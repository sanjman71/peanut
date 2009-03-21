class CompanySchedulablesController < ApplicationController
  
  # POST /calendars/:schedulable_type/:schedulable_id/toggle
  def toggle
    logger.debug("*** toggle: #{params}")
    @calendar = CompanySchedulable.find_by_schedulable_id_and_schedulable_type(params[:schedulable_id], params[:schedulable_type].to_s.classify)
    
    if @calendar
      # remove calendar
      @calendar.destroy
      logger.debug("*** removed calendar: #{@calendar.id}")
    else
      begin
        # add calendar
        @schedulable  = eval("#{params[:schedulable_type].to_s.classify}.find_by_id(#{params[:schedulable_id]})")
        @calendar     = CompanySchedulable.create(:schedulable => @schedulable, :company => current_company)
        logger.debug("*** added calendar for: #{@schedulable}")
      rescue Exception => e
        logger.debug("*** schedulable error: #{e.message}")
      end
    end
    
    render_component(:controller => 'employees',  :action => 'index',
                     :layout => false, :params => {:authenticity_token => params[:authenticity_token] })
  end
  
end