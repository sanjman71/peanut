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
      @plan         = Plan.find_by_textid(params[:plan])
      @subscription = Subscription.new
    end
  end

  def create
    # this requires a transaction
    Company.transaction do
      @user         = logged_in? ? current_user : User.new(params[:user])
      @terms        = params[:company].delete(:terms).to_i
      @company      = Company.new(params[:company])
      @plan         = Plan.find_by_textid(params[:plan])

      # try to create company, user objects
      @company.save
      @user.save

      # try to create subscription only if user and company are valid
      @subscription = Subscription.create(:user => @user, :company => @company, :plan => @plan)
      @credit_card  = ActiveMerchant::Billing::CreditCard.new(params[:cc])
      @payment      = @subscription.authorize(@credit_card)

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
    @free     = Plan.find_by_textid("free")
    @basic    = Plan.find_by_textid("basic")
    @premium  = Plan.find_by_textid("premium")
    @max      = Plan.find_by_textid("max")
  end

end
