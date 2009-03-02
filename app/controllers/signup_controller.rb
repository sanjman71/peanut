class SignupController < ApplicationController
  layout 'home'
  # ssl_required :new
  
  # /signup/:plan
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
      @user         = logged_in? ? current_user : User.new(params[:user])
      @terms        = params[:company].delete(:terms).to_i
      @company      = Company.new(params[:company])
      @plan         = Plan.find(params[:plan_id])

      # try to create company, user objects
      @company.save
      @user.save

      # try to create subscription only if user and company are valid
      @subscription = Subscription.create(:user => @user, :company => @company, :plan => @plan)
      
      # Check credit card details only if the plan has a cost associated with it or if the data has been provided.
      if @plan.cost > 0 || !params[:cc].blank?
        @credit_card  = ActiveMerchant::Billing::CreditCard.new(params[:cc])
        @payment      = @subscription.authorize(@credit_card)
      end

      # check terms
      @terms_error  = 'The terms and conditions must be accepted' unless @terms == 1

      # rollback unless all objects are valid
      # raise ActiveRecord::Rollback if !@company.valid? or !@user.valid? or !@subscription.errors.empty? or @terms != 1
      raise ActiveRecord::Rollback if !@company.valid? or !@user.valid?
      raise ActiveRecord::Rollback if !@subscription.errors.empty? or @terms != 1

      # register, activate user
      if !logged_in?
        @user.register!
        @user.activate!
      end

      # set user role on the specific company
      @user.grant_role('company manager', @company)

      # signup completed, redirect to login page
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to(login_path(:subdomain => @company.subdomain)) and return
    end
    
    respond_to do |format|
      format.html { render(:action => 'new') }
    end
  end
  
  def index
    plans     = Plan.order_by_cost
    @free     = plans[0]
    @basic    = plans[1]
    @premium  = plans[2]
    @max      = plans[3]
  end

end
