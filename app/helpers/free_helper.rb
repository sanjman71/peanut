module FreeHelper
  
  def build_when_links(when_collection, current)
    default = Appointment::WHEN_THIS_WEEK
    
    when_collection.each do |s|
      # add css 'current' class for the current link
      klass = (s == current) ? 'current' : ''
      
      if s == default
        # no when parameter for the default value
        link  = link_to(s.titleize, manage_resource_free_path(:subdomain => @subdomain), :class => klass)
      else
        # use when parameter
        link  = link_to(s.titleize, manage_resource_free_path(:subdomain => @subdomain, :when => s), :class => klass)
      end
      
      # use separator unless its the last element
      separator = (s == when_collection.last) ? '' : '&nbsp;|&nbsp;'
      
      yield link, separator
    end
  end
  
  # map each collection object to  link_name, link_parameter, and css class names
  def build_links(collection, options={})
    default = options[:default]
    param   = options[:param]
    current = options[:current]
    
    collection.each do |s|
      link_title  = s
      link_param  = (s == default) ? {} : Hash[param => s]
      klass_name  = (s == current) ? 'current' : ''
      yield link_title, link_param, klass_name
    end
  end
end
