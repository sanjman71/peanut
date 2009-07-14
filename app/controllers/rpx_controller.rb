class RpxController < ApplicationController

  def customer
    raise Exception unless @data = RPXNow.user_data(params[:token])
    
    @user = User.find_by_identifier(@data[:identifier])
    
    if @user.blank?
      # create user using rpx identifier
      @user = User.create(:name => @data[:name], :email => @data[:email], :identifier => @data[:identifier])
    
      @user.register! if @user && @user.valid?
      success = @user && @user.valid?
    
      if success && @user.errors.empty?
        @redirect_path  = "/"
      else
        raise Exception, "error"
      end
    else
      # create new user session
    end
    
    redirect_back_or_default(@redirect_path)
  end

end