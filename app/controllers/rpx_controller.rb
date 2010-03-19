class RpxController < ApplicationController
  before_filter :init_user, :only => [:add]

  privilege_required  'update users', :only => [:add], :on => :user

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

    # set session return_to value if it was specified
    @return_to = params[:return_to]
    session[:return_to] = @return_to unless @return_to.blank?

    # check if its for a user we already know about
    @user = User.with_identifier(@data[:identifier]).first
    
    if @user.blank?
      # check if rpx user create is for a public company
      if current_company and current_company.preferences[:public].to_i == 0
        flash[:error] = "You are not authorized to create a user account for this company"
        redirect_to login_path and return
      end

      # create user using rpx data
      @options = Hash[:preferences_phone => current_company.preferences[:customer_phone],
                      :preferences_email => current_company.preferences[:customer_email]]
      @user    = User.create_rpx(@data[:name], @data[:email], @data[:identifier], @options)

      if @user.valid?
        # create user session
        @redirect_path = session_initialize(@user)
        redirect_back_or_default(@redirect_path) and return
      else
        flash[:error] = @user.errors.full_messages.join("<br/>")
        render(:template => "sessions/new") and return
      end
    else
      # create user session
      @redirect_path = session_initialize(@user)
      redirect_back_or_default(@redirect_path) and return
    end
  end

  # GET /rpx/add/1
  def add
    @redirect_path = add_rpx_user_path(current_user)

    begin
      @data = RPXNow.user_data(params[:token])
      @email = @data[:email]
      @identifier = @data[:identifier]
    rescue Exception => e
      flash[:error] = "Rpx add account error: #{params[:error]}"
      redirect_to(@redirect_path) and return
    end

    @user = User.with_identifier(@identifier).first

    if @user
      flash[:error] = "Rpx login is already linked to this account"
      redirect_to(@redirect_path) and return
    end

    if @email.blank?
      flash[:error] = "Rpx user account missing email address"
      redirect_to(@redirect_path) and return
    end

    # add email address to user account, mark as verified, set priority
    @rpx_email = current_user.email_addresses.create(:address => @email, :identifier => @identifier)
    @rpx_email.verify!
    @rpx_email.update_attribute(:priority, EmailAddress::PRIORITY_MEDIUM)

    flash[:notice] = "Added rpx login to your user account"
    redirect_to(@redirect_path) and return
  end

  protected

  def init_user
    @user = User.find(params[:id])
  end

end