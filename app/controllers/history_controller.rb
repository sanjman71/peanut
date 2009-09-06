class HistoryController < ApplicationController
  before_filter :current_user

  privilege_required  'read users', :only =>[:index], :on => :current_user

  # GET /history/index
  def index
    # find all user's appointments
    @appointments = current_user.appointments.paginate(:page => params[:page], :order => "start_at desc")

    respond_to do |format|
      format.html
    end
  end

end