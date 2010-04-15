class HistoryController < ApplicationController
  before_filter :current_user

  privilege_required  'read users', :only =>[:index], :on => :current_user

  # Deprecated: we use appointment routes and controller instead, this controller seems inconsitent with the rest of the app

  # GET /history
  # def index
  #   # find all user's appointments + waitlist
  #   @appointments = current_user.appointments.company(current_company).paginate(:page => params[:page], :order => "start_at desc")
  #   @title        = "Appointment History"
  # 
  #   respond_to do |format|
  #     format.html
  #   end
  # end

  # GET /history/waitlist
  # def waitlist
  #   @waitlists  = current_user.waitlists.company(current_company).all(:order => 'updated_at desc', :include => :waitlist_time_ranges)
  #   @title      = "Waitlist History"
  # 
  #   respond_to do |format|
  #     format.html
  #   end
  # end
  
end