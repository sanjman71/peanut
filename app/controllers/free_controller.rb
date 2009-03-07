class FreeController < ApplicationController
  # privilege_required 'read appointments', :only => [:index]

  # GET /users/1/free/calendar
  def new
    if params[:schedulable].blank? or params[:id].blank?
      # redirect to a specific schedulable
      schedulable = current_company.schedulables.first
      redirect_to url_for(params.update(:subdomain => current_subdomain, :schedulable => schedulable.tableize, :id => schedulable.id)) and return
    end
        
    # initialize schedulable, default to anyone
    @schedulable  = current_company.schedulables.find_by_schedulable_id_and_schedulable_type(params[:id], params[:schedulable].to_s.classify)
    @schedulable  = User.anyone if @schedulable.blank?
    
    # build list of schedulables to allow the scheduled to be adjusted by resource
    @schedulables = current_company.schedulables.all
    
    # initialize daterange, start calendar on sunday, end calendar on sunday
    @daterange    = DateRange.parse_when('next 4 weeks', :start_on => 0, :end_on => 0)
    
    # find unscheduled time
    @unscheduled_appts  = AppointmentScheduler.find_unscheduled_time(current_company, @schedulable, @daterange)
    
    # build calendar markings
    @calendar_markings  = build_calendar_markings(@unscheduled_appts.values.flatten)
    
    # build time of day collection
    # TODO xxx - need a better way of mapping these times to start, end hours
    @tod        = ['morning', 'afternoon']
    @tod_start  = 'morning'
    @tod_end    = 'afternoon'
    
    @free_service = current_company.services.free.first

    # select the view to show
    style       = params[:style] || 'block'
    
    respond_to do |format|
      format.html { render(:action => "free_#{style}")}
    end
  end
  
end
