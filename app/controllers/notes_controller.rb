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

    end
    
    respond_to do |format|
      format.js
    end
    
  end

end