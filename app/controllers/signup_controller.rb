class SignupController < ApplicationController
  before_filter :init_promotion, :only => [:new, :create]

  layout 'home'
  # ssl_required :new
  
  # GET /signup/beta
  def beta
    @promotion = Promotion.new

    respond_to do |format|
      format.html
    end
  end

  # POST /signup/check
  def check
    # find promotion
    @promotion = Promotion.find_by_code(params[:promotion][:code])

    if @promotion
      # use basic plan
      @plan = Plan.find_by_name('Basic')
      redirect_to(signup_plan_path(@plan, :promo => @promotion.code))
    else
      flash[:error] = "Promotion is no longer valid"
      redirect_to(signup_beta_path)
    end
  end

  # GET /signup
  def index
    @plans = Plan.order_by_cost

    respond_to do |format|
      format.html
    end
  end
  
  # GET /signup/:plan_id
  def new
    # @promotion is initialized in before filter

    @company        = Company.new
    @user           = logged_in? ? current_user : User.new
    @plan           = Plan.find(params[:plan_id])
    @subscription   = Subscription.new

    if @promotion
      # apply promotion
      @prices   = @promotion.calculate(@plan.cost)
      @price    = @prices.last
      
      if @price == 0
        @message  = "Your promotion code allows you to signup without any billing information."
      end
    else
      # use plan cost
      @price    = @plan.cost
    end

    respond_to do |format|
      format.html
    end
  end

  # POST /signup/:plan_id
  def create
    # @promotion is initialized in before filter

    # this requires a transaction
    Company.transaction do
      # get and remove terms from params
      @terms        = params[:company].delete(:terms).to_i
      @user         = logged_in? ? current_user : User.create_or_reset(params[:user])
      @plan         = Plan.find(params[:plan_id])
      # subscription and company objects are dependent on each other
      @subscription = Subscription.new(:user => @user, :plan => @plan)
      @company      = Company.create(params[:company].update(:subscription => @subscription))

      # check credit card details only if the plan is billable and there is a non-zero price after any promotions
      if @plan.billable?
        @price = @promotion ? @promotion.calculate(@plan.cost).last : @price

        if @price > 0
          @credit_card  = ActiveMerchant::Billing::CreditCard.new(params[:cc])
          @payment      = @subscription.authorize(@credit_card)
        end
      end

      # check terms
      unless @terms == 1
        @terms_error = 'The terms and conditions must be accepted'
      end

      # rollback unless all objects are valid
      raise ActiveRecord::Rollback if !@company.valid? or !@user.valid?
      raise ActiveRecord::Rollback if !@subscription.errors.empty? or @terms != 1

      # add user as company provider, which also grants user 'company provider' role
      @company.user_providers.push(@user)

      unless @user.has_role?('company manager', @company)
        # add user as company manager
        @user.grant_role('company manager', @company)
      end

      if @promotion
        # create promotion redemption and link to subscription
        @promotion.promotion_redemptions.create(:redeemer => @subscription)
      end

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

  protected

  def init_promotion
    return if params[:promo].blank? and session[:promo].blank?
    @promotion = Promotion.find_by_code(params[:promo] || session[:promo])
    return if @promotion.blank?
    # ensure promotion is still redeemable
    return unless @promotion.redeemable?

    # cache promotion as a session variable
    session[:promo] = @promotion.code

    true
  end
end
