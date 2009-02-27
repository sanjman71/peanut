module AppointmentsHelper

  def build_appointment_when_links(person, when_collection, current, options={})
    default = options[:default]
    
    when_collection.each do |s|
      # add css 'current' class for the current link
      klass       = (s == current) ? 'current' : ''
      url_params  = {:controller => 'appointments', :action => 'index', :person_id => person, :subdomain => @subdomain}
      
      if s == default
        # no when parameter for the default value
        link  = link_to(s.titleize, url_for(url_params.update(:when => nil)), :class => klass)
      else
        # use when parameter
        link  = link_to(s.titleize, url_for(url_params.update(:when => s.to_url_param)), :class => klass)
      end
      
      # use separator unless its the last element
      separator = (s == when_collection.last) ? '' : '&nbsp;|&nbsp;'
      
      yield link, separator
    end
  end
  
end
