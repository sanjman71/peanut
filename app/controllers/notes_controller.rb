class NotesController < ApplicationController
  before_filter :init_current_company
  layout 'blueprint'

  # POST /resources
  # POST /resources.xml
  def create
    @note = Note.create(params[:note])
    
    if !@note.valid?
      @errors = true
      return
    end
    
    # set notice text
    @notice_text  = "Created note"
    
    # build notes collection, most recent first 
    @notes        =  @note.subject.notes.sort_recent
  end

end