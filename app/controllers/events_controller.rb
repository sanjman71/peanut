class EventsController < ApplicationController

  # Everyone can create an event, though they generally won't know it.
  privilege_required  'read events', :only => [:index, :show]
  privilege_required  'delete events', :only => [:destroy]
  privilege_required  'update events', :only => [:edit, :update]

  def index
    
    if params[:seen].blank? || params[:seen] != "true"
      @seen = false
      @urgent = current_company.events.urgent.unseen
      @approval = current_company.events.approval.unseen
      @informational = current_company.events.informational.unseen
    else
      @seen = true
      @urgent = current_company.events.urgent.seen
      @approval = current_company.events.approval.seen
      @informational = current_company.events.informational.seen
    end
    
    respond_to do |format|
      format.html
    end
    
  end
  
  def mark_as_seen
    @event = Event.find(params[:id])
    if @event
      @event.seen = true
    end
    if @event.save
      flash[:notice] = "Event marked as seen"
    else
      flash[:error] = "Couldn't mark event as seen"
    end
    
    redirect_to events_path(:subdomain => current_subdomain) and return
    
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
