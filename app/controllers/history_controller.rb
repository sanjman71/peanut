class HistoryController < ApplicationController
  before_filter :current_user

  privilege_required  'read users', :only =>[:index], :on => :current_user

  # GET /history/index
  def index
    # find all user's appointments + waitlist
    @appointments = current_user.appointments.paginate(:page => params[:page], :order => "start_at desc")
    @waitlists    = current_user.waitlists.all(:order => 'updated_at desc', :include => :waitlist_time_ranges)

    respond_to do |format|
      format.html
    end
  end

end