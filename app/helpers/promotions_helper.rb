module PromotionsHelper

  def promotion_discount_to_s(promotion)
    case promotion.units
    when 'cents'
      s = "#{number_to_currency(promotion.discount/100)}"
    when 'percent'
      s = "#{number_to_percentage(promotion.discount, :precision => 0)}"
    else
      s = ''
    end
    
    if promotion.minimum > 0
      s += ", with $#{promotion.minimum} minimum"
    else
      s += ", no minimum"
    end
    
    s
  end

  def promotion_uses_to_s(promotion)
    "#{promotion.uses_allowed} allowed, #{promotion.remaining} remaining"
  end
  
  def promotion_expires_to_s(promotion)
    if promotion.expires_at.blank?
      "no expiration"
    else
      "expires #{promotion.expires_at.to_s(:appt_short_month_day_year)}"
    end
  end
end