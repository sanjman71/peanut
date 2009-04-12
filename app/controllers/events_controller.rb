class EventsController < ApplicationController

  # Everyone can create an event, though they generally won't know it.
  privilege_required  'read events', :only => [:index]
  privilege_required  'update events', :only => [:mark_as_seen]
  privilege_required  'create events', :only => [:create]
  privilege_required  'delete events', :only => [:destroy]

  def index
    if params[:state].blank? || params[:state] == 'unseen'
      @seen = false
      @urgent_by_day = current_company.events.urgent.unseen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
      @approval_by_day = current_company.events.approval.unseen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
      @informational_by_day = current_company.events.informational.unseen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
    else
      @seen = true
      @urgent_by_day = current_company.events.urgent.seen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
      @approval_by_day = current_company.events.approval.seen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
      @informational_by_day = current_company.events.informational.seen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
    end

    respond_to do |format|
      format.html
    end
  end
  
  def mark_as_seen
    @event = Event.find(params[:id])
    if @event
      if (params[:seen].blank? || params[:seen] == true)
        @event.mark_as_seen!
        state = 'unseen'
      else
        @event.mark_as_unseen!
        state = 'seen'
      end
    end
    if @event.save
      flash[:notice] = "Changed event"  
    else
      flash[:error] = "Couldn't change event"
    end
    
    respond_to do |format|
      format.html { redirect_to url_for(:subdomain => current_subdomain, :action => 'index', :state => state) and return }
      format.js {
        if state == 'seen'
          @urgent_by_day = current_company.events.urgent.seen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
          @approval_by_day = current_company.events.approval.seen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
          @informational_by_day = current_company.events.informational.seen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
        else
          @urgent_by_day = current_company.events.urgent.unseen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
          @approval_by_day = current_company.events.approval.unseen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
          @informational_by_day = current_company.events.informational.unseen.order_recent.group_by { |e| e.updated_at.beginning_of_day }
        end
      }
    end
    
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
