class RpxController < ApplicationController

  include UserSessionHelper

  def customer
    raise Exception unless @data = RPXNow.user_data(params[:token])
    
    @user = User.with_identifier(@data[:identifier]).first
    
    if @user.blank?
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