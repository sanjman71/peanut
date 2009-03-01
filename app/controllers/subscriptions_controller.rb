class SubscriptionsController < ApplicationController
  layout "company"

  privilege_required 'update companies', :only => [:edit, :update], :on => :current_company
  
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
  
end
