class SubscriptionsController < ApplicationController
  layout "company"

  privilege_required 'update companies', :only => [:edit, :update], :on => :current_company
  
  def edit
    @subscription = current_company.subscription
    @current_plan = current_company.plan
    
    # find all eligible plans, filter out the current plan
    @plans = Plan.order_by_cost.select { |p| p.is_eligible?(current_company) and p != @current_plan }
    
    respond_to do |format|
      format.html # edit.html.haml
    end
  end
  
  def update
    @plan = Plan.find(params[:plan_id])
    
    if @plan.is_eligible?(current_company)
      current_company.subscription.plan = @plan
      current_company.subscription.save
      flash[:notice] = "Your plan has been updated."
    else
      flash[:error] = "You are not eligible for the #{@plan.name} plan."
    end
    
    redirect_to edit_company_root_path(:subdomain => current_company.subdomain) and return
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
        format.html { redirect_to(edit_company_root_path(:subdomain => current_subdomain)) and return }
      else
        flash[:notice] = 'There was a problem authorizing your credit card.'
        format.html { render :action => "edit_cc" }
      end
    end
  end

end
