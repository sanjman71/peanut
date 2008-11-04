# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  # add the token s to value if b is true
  def add_class_if(b, s, value = '')
    return value if !b
    
    if value.blank?
      s
    else
      value += ' #{s}'
    end
  end
  
end
