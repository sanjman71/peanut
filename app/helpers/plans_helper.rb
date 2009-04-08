module PlansHelper

  def plan_billing_details(plan)
    "#{number_to_currency(plan.cost/100)} " + plan_billing_regularity(plan)
  end
  
  def plan_billing_regularity(plan)
    if plan.between_billing_time_amount == 1
      "every #{plan.between_billing_time_unit.singularize}."
    else
      "every #{pluralize(plan.between_billing_time_amount, plan.between_billing_time_unit)}."
    end
  end
  
  # type => ['providers', 'locations']
  def plan_limit_text(plan, type)
    if plan.send("max_#{type.to_s.pluralize}")
      "Up to #{pluralize(plan.send("max_#{type.to_s.pluralize}"), type.to_s.singularize)}"
    else
      "Unlimited #{type.to_s.pluralize}"
    end
  end
  
end
