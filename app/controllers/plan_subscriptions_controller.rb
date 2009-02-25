class PlanSubscriptionsController < ApplicationController
  layout "company"

  privilege_required 'update companies', :only => [:edit, :update], :on => :current_company
  
  def edit
    @plan_subscription = current_company.plan_subscription
    
    respond_to do |format|
      format.html # edit.html.haml
    end
  end
  
  def update
    @plan = Plan.find_by_textid(params[:plan])
    
    if @plan.is_eligible(current_company)
      current_company.plan = @plan
      if current_company.plan_subscription.next_bill_date.blank?
        current_company.plan_subscription.next_bill_date = Time.now + @plan.days_to_first_bill
      end
      current_company.save
      flash[:notice] = "Your plan has been updated."
    else
      flash[:error] = "You are not eligible for the #{@plan.name} plan."
    end
    
    redirect_to edit_company_root_path(:subdomain => current_company.subdomain)
        
  end

end
