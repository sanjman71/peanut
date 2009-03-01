class SubscriptionsController < ApplicationController
  layout "company"

  privilege_required 'update companies', :only => [:index, :edit, :update], :on => :current_company
  
  # GET /subscriptions
  def index
    case params[:filter]
    when 'errors'
      @subscriptions  = Subscription.billing_errors
      @search_text    = "Subscriptions w/ Billing Errors (#{@subscriptions.size})" 
    else
      @subscriptions  = Subscription.all
      @search_text    = "All Subscriptions (#{@subscriptions.size})" 
    end
    
    respond_to do |format|
      format.html { render(:action => :index, :layout => 'home')}
    end
  end
  
  def edit
    @subscription = current_company.subscription

    plans     = Plan.order_by_cost
    @free     = plans[0]
    @basic    = plans[1]
    @premium  = plans[2]
    @max      = plans[3]
    
    respond_to do |format|
      format.html # edit.html.haml
    end
  end
  
  def update
    @plan = Plan.find(params[:plan_id])
    
    if @plan.is_eligible(current_company)
      current_company.plan = @plan
      current_company.save
      flash[:notice] = "Your plan has been updated."
    else
      flash[:error] = "You are not eligible for the #{@plan.name} plan."
    end
    
    redirect_to edit_company_root_path(:subdomain => current_company.subdomain)
        
  end
  
  def edit_cc
    @credit_card  = ActiveMerchant::Billing::CreditCard.new(params[:cc])    
  end
  
  def update_cc

    @credit_card  = ActiveMerchant::Billing::CreditCard.new(params[:active_merchant_billing_credit_card])
    @payment      = current_company.subscription.authorize(@credit_card)
    
    respond_to do |format|
      if current_company.subscription.errors.empty?
        flash[:notice] = 'Credit card was successfully updated.'
        format.html { redirect_to(edit_company_root_path(:subdomain => current_subdomain)) }
      else
        flash[:notice] = 'There was a problem authorizing your credit card.'
        format.html { render :action => "edit_cc" }
      end
    end
  end

end
