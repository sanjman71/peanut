class FreeController < ApplicationController
  # privilege_required 'read companies', :only => [:index]

  # GET /people/1/free
  def index
    if params[:person_id].blank?
      # redirect to a specific person
      person = current_company.people.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :person_id => person.id)) and return
    end
        
    # initialize person, default to anyone
    @person   = current_company.people.find(params[:person_id]) if params[:person_id]
    @person   = Person.anyone if @person.blank?
    
    style     = params[:style] || 'block'
    
    respond_to do |format|
      format.html { render(:action => "free_#{style}")}
    end
  end
  
end
