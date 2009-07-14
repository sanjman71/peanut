class RpxController < ApplicationController

  def customer
    raise Exception unless @data = RPXNow.user_data(params[:token])
    # raise Exception, "id: #{data[:identifier]}, name: #{data[:name]}, email: #{data[:email]}, display: #{data[:username]}, #{data.keys}"
    
    @user = User.find_by_identifier(@data[:identifier])
    
    if @user.blank?
      # create user using rpx identifier
      # @user = User.new(:name => @data[:name], :email => @data[:email], :identity => @data[:identifier])
      @user = User.new(:name => @data[:name], :email => @data[:email], :identifier => @data[:identifier], 
                       :password => "secret", :password_confirmation => "secret")
    
      @user.register! if @user && @user.valid?
      success = @user && @user.valid?
    
      if success && @user.errors.empty?
        @redirect_path  = "/" #return_to || "/"
      else
        raise Exception, "error"
      end
    else
      # create new user session
    end
    
    redirect_back_or_default(@redirect_path)
  end

end