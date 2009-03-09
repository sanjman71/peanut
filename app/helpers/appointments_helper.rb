module AppointmentsHelper

  def build_appointment_when_links(person, when_collection, current, options={})
    default = options[:default]
    
    when_collection.each do |s|
      # add css 'current' class for the current link
      klass       = (s == current) ? 'current' : ''
      url_params  = {:controller => 'appointments', :action => 'index', :person_id => person, :subdomain => @subdomain}
      
      if s == default
        # no when parameter for the default value (explicitly clear start/end date used for range values)
        link  = link_to(s.titleize, url_for(url_params.update(:when => nil, :start_date => nil, :end_date => nil)), :class => klass)
      else
        # use when parameter
        link  = link_to(s.titleize, url_for(url_params.update(:when => s.to_url_param)), :class => klass)
      end
      
      # use separator unless its the last element
      separator = (s == when_collection.last) ? '' : '&nbsp;|&nbsp;'
      
      yield link, separator
    end
  end
  
  def service_duration_in_words(duration_in_minutes)
    if duration_in_minutes >= 60
      # use hours
      hours, mins = [duration_in_minutes / 60, duration_in_minutes % 60]
      mins > 0 ? "Typically #{pluralize(hours, 'hour')}, #{pluralize(mins, 'minute')}" : "Typically #{pluralize(hours, 'hour')}"
    else
      # use minutes
      "Typically #{duration_in_minutes} minutes"
    end
  end
  
  def service_duration_select_options
    collection = []
    
    # add minutes in 15 minute intervals
    collection = [15, 30, 45].inject(collection) do |collection, minutes|
      collection.push(["#{minutes} minutes", minutes])
      collection
    end

    # add hours
    collection = [1, 2, 3].inject(collection) do |collection, hours|
      # convert hours to mintues for select value
      hours > 1 ? collection.push(["#{hours} hours", hours*60]) : collection.push(["#{hours} hour", hours*60])
      collection
    end
    
    collection
  end
  
end
