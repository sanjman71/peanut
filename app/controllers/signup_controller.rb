class SignupController < ApplicationController
  layout 'home'
  # ssl_required :new
  
  def index
    @plans = Plan.order_by_cost

    respond_to do |format|
      format.html
    end
  end
  
  # /signup/:plan_id
  def new
    if request.post? or request.put?
      return create
    else
      @company      = Company.new
      @user         = logged_in? ? current_user : User.new
      @plan         = Plan.find(params[:plan_id])
      @subscription = Subscription.new
    end
  end

  def create
    # this requires a transaction
    Company.transaction do
      # get and remove terms from params
      @terms        = params[:company].delete(:terms).to_i
      @user         = logged_in? ? current_user : User.create(params[:user])
      @plan         = Plan.find(params[:plan_id])
      # subscription and company objects are dependent on each other
      @subscription = Subscription.new(:user => @user, :plan => @plan)
      @company      = Company.create(params[:company].update(:subscription => @subscription))

      # check credit card details only if the plan is billable
      if @plan.billable?
        @credit_card  = ActiveMerchant::Billing::CreditCard.new(params[:cc])
        @payment      = @subscription.authorize(@credit_card)
      end

      # check terms
      @terms_error = 'The terms and conditions must be accepted' unless @terms == 1

      # rollback unless all objects are valid
      # raise ActiveRecord::Rollback if !@company.valid? or !@user.valid? or !@subscription.errors.empty? or @terms != 1
      raise ActiveRecord::Rollback if !@company.valid? or !@user.valid?
      raise ActiveRecord::Rollback if !@subscription.errors.empty? or @terms != 1

      # register, activate user
      if !logged_in?
        @user.register!
        @user.activate!
      end

      # add user as company provider, which also grants user 'company provider' role
      @company.providers.push(@user)

      # add user as company manager
      @user.grant_role('company manager', @company)
      
      # signup completed, redirect to login page and instruct user to login
      flash[:notice] = "Signup complete! Please login to continue."
      
      if !logged_in?
        # redirect to the new company's login path
        redirect_to(login_path(:subdomain => @company.subdomain)) and return
      else
        # redirect to the new company's openings path
        redirect_to(openings_path(:subdomain => @company.subdomain)) and return
      end
    end
    
    respond_to do |format|
      format.html { render(:action => 'new') }
    end
  end

end
