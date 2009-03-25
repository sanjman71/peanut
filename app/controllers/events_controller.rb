class EventsController < ApplicationController

  # Everyone can create an event, though they generally won't know it.
  privilege_required  'read events', :only => [:index, :show]
  privilege_required  'delete events', :only => [:destroy]
  privilege_required  'update events', :only => [:edit, :update]

  def index

    @urgent = current_company.events.urgent
    @approval = current_company.events.approval
    @informational = current_company.events.informational
    
    respond_to do |format|
      format.html
    end
    
  end
  
  def show
    
  end
  
  def edit
    
  end
  
  def update
    
  end
  
  def create
    e = Event.new(params[:event])
    e.company_id = current_company.id unless current_company.blank?
    e.user_id = current_user.id unless current_user.blank?
    if e.save
      flash[:notice] = "Your event was created"
    else
      flash[:error] = "Problem creating event"
    end
    
    redirect_to events_path(:subdomain => current_subdomain) and return
    
  end
  
  def destroy
    debugger
    @event = Event.find(params[:id])
    
    if @event && @event.delete
      flash[:notice] = "Event was deleted"
    else
      flash[:error] = "Couldn't delete event"
    end
    @urgent = current_company.events.urgent
    @approval = current_company.events.approval
    @informational = current_company.events.informational
    respond_to do |format|
      format.html { redirect_to events_path(:subdomain => current_subdomain)}
      format.js
    end
    
  end
  
end
