class SignupController < ApplicationController
  layout 'home'
  # ssl_required :new
  
  # /signup/:plan
  def new
    if request.post? or request.put?
      return do_signup
    else
      @company  = Company.new
      @user     = logged_in? ? current_user : User.new
      if @user.account.blank?
        @user.account = Account.new
      end
      @plan     = Plan.find_by_link_text(params[:plan])
    end
  end

  private
  
  def do_signup
    @user     = logged_in? ? current_user : User.new(params[:user])
    if !@user.account
      @account  = @user.build_account(params[:account])
    else
      @user.account.update_attributes(params[:account])
      @account = @user.account
    end
    @terms    = params[:company].delete(:terms).to_i
    @company  = Company.new(params[:company])
    @plan     = Plan.find_by_link_text(params[:plan])
    
    # use a transaction to objects
    Company.transaction do
      # check terms
      @terms_error = 'The terms and conditions must be accepted' unless @terms == 1

      @ucp = UserCompanyPlan.new(:user => @user, :company => @company, :plan => @plan)
      @ucp.next_bill_date = Time.now + (@plan.days_before_start_billing).days if @plan.days_before_start_billing

      # create company, user objects
      # create account and join table objects
      @company.save
      @user.save
      @account.save
      @ucp.save
      
      # rollback unless all objects are valid
      raise ActiveRecord::Rollback if !@company.valid? or !@user.valid? or !@account.valid? or !@ucp.valid? or @terms != 1

      # register, activate user
      if !logged_in?
        @user.register!
        @user.activate!
      end
      
      # set user role on the specific company
      @user.grant_role('company manager', @company)
      
      # signup completed, redirect to login page
      flash[:notice] = "Signup complete! Please sign in to continue."
      return redirect_to(login_path(:subdomain => @company.subdomain))
    end
  end
end
