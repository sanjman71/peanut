class RpxController < ApplicationController

  include UserSessionHelper

  # GET /rpx/login
  # called after an rpx authentication
  def login
    begin
      @data = RPXNow.user_data(params[:token])
    rescue Exception => e
      flash[:error] = "Rpx login error: #{params[:error]}"
      redirect_to login_path and return
    end

    if @data.blank?
      flash[:error] = "Rpx login error"
      redirect_to login_path and return
    end

    @user = User.with_identifier(@data[:identifier]).first
    
    if @user.blank?
      # check if rpx user create is for a public company
      if current_company and current_company.preferences[:public].to_i == 0
        flash[:error] = "You are not authorized to create a user account for this company"
        redirect_to login_path and return
      end

      # create user using rpx data
      @user = User.create_rpx(@data[:name], @data[:email], @data[:identifier])

      if @user.valid?
        # create user session
        redirect_path = session_initialize(@user)
      end

      if @user.valid?
        redirect_back_or_default(redirect_path) and return
      else
        flash[:error] = @user.errors.full_messages.join("<br/>")
        render(:template => "sessions/new") and return
      end
    else
      # create user session
      redirect_path = session_initialize(@user)
      redirect_back_or_default(redirect_path) and return
    end
  end

end