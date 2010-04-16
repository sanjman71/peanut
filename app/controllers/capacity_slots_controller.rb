class CapacitySlotsController < ApplicationController
  before_filter :init_provider

  # privilege_required_any  'update calendars', :only =>[:capacity], :on => [:provider, :current_company]

  # GET /users/1/capacity/start/2010010T0900000/duration/3600
  def capacity
    # @provider initialized in before_filter

    @start_at = Time.zone.parse(params[:start_time])
    @duration = params[:duration].to_i
    # find all slots that overlap the specified time range
    @slots    = current_company.capacity_slots.provider(@provider).overlap(@start_at, @start_at + @duration).order_start_at
    # find min capacity of all slots
    @capacity = @slots.collect{ |o| o.capacity }.min.to_i

    respond_to do |format|
      format.json { render(:json => Hash[:capacity => @capacity].to_json) }
    end
  end
  
end