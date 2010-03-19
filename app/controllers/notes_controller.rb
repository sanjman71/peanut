class NotesController < ApplicationController

  # POST /resources
  # POST /resources.xml
  def create

    @note = Note.create(params[:note])
    
    if !@note.valid?
      @error = true
      flash[:error] = "Problem adding note"
      @notes = []
    else
      # set notice text
      flash[:notice]  = "Added note"

      # build notes collection, most recent first 
      @notes        =  @note.subject.notes.sort_recent

      if !@note.subject.blank? and @note.subject.class == Appointment and @note.subject.valid? and @note.subject.work?
        appointment = @note.subject
        begin
          # send appointment change based on (confirmation) preferences
          @preferences  = Hash[:customer => current_company.preferences[:work_appointment_confirmation_customer],
                               :manager => current_company.preferences[:work_appointment_confirmation_manager],
                               :provider => current_company.preferences[:work_appointment_confirmation_provider]]
          @changes      = MessageComposeAppointment.changes(appointment, @preferences, {:company => current_company})
          # check if customer cancelation was sent
          if @changes.any? { |who, message| who == :customer }
            # add flash message
            flash[:notice] += "<br/>An email with the appointment changes will be sent to #{appointment.customer.email_address}."
          end
        rescue Exception => e
          logger.debug("[error] update appointment error sending message: #{e.message}")
        end
        
      end

    end
    
    respond_to do |format|
      format.js
    end
    
  end

end