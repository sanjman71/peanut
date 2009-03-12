module CalendarHelper

  def build_calendar_when_links(schedulable, when_collection, current, options={})
    default = options[:default]
    
    when_collection.each do |s|
      # add css 'current' class for the current link
      klass       = (s == current) ? 'current' : ''
      url_params  = {:controller => 'calendar', :action => 'show', :schedulable_id => schedulable.id, :schedulable_type => schedulable.tableize, :subdomain => @subdomain}
      
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

end