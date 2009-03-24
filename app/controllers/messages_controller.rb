class MessagesController < ApplicationController

  # POST /messages/deliver/:type (e.g. 'email', 'sms')
  #  - appointment_id
  #  - message
  def deliver
    @type         = params[:type]
    @appointment  = Appointment.find(params[:appointment_id])
    @user         = @appointment.customer
    @message      = params[:message]
    
    case @type
    when 'email'
      begin
        @email = @user ? @user.email : ''
        MailWorker.async_send_message(:company_id => current_company.id, :user_id => @user.id, :message => @message)
        flash[:notice] = "Sent message to #{@user.email}"
      rescue Exception => e
        flash[:error] = "There was an error sending a message to #{@user.email}"
        logger.debug("xxx error sending email: #{e.message}")
      end
    when 'sms'
      begin
        @sms  = @user ? @user.phone : ''
        SmsWorker.async_send_message(:company_id => current_company.id, :user_id => @user.id, :message => @message)
        flash[:notice] = "Sent message to #{@user.phone}"
      rescue Exception => e
        flash[:error] = "There was an error sending a message to #{@user.phone}"
        logger.debug("xxx error sending sms: #{e.message}")
      end
    end
    
    respond_to do |format|
      format.js
    end
  end
  
  
end