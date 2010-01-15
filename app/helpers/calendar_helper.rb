module CalendarHelper

  def build_calendar_range_type_links(provider, range_type_collection, current, start_date)

    range_type_collection.each do |rt|
      url_params  = {:provider_id => provider.id, :provider_type => provider.tableize, :subdomain => @subdomain}
      # add css 'current' class for the current link
      klass       = (rt == current) ? 'current' : ''
      if ((rt == 'daily') && (start_date.today?))
        url_params.merge!({:when => 'today'})
        # use when parameter
        link  = link_to(rt.titleize, when_show_path(url_params), :class => klass)
      else
        url_params.merge!({:range_type => rt, :start_date => start_date.to_s(:appt_schedule_day)})
        # use when parameter
        link  = link_to(rt.titleize, range_type_show_path(url_params), :class => klass)
      end      
      
      yield link
    end
  end

  def build_calendar_when_links(provider, when_collection, current, options={})
    default = options[:default]
    
    when_collection.each do |s|
      # add css 'current' class for the current link
      klass       = (s == current) ? 'current' : ''
      url_params  = {:controller => 'calendar', :action => 'show', :provider_id => provider.id, :provider_type => provider.tableize, :subdomain => @subdomain}
      
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

  def build_calendar_prev_next_links(provider, daterange)
    next_when   = daterange.name.to_url_param
    next_start  = (daterange.end_at.in_time_zone + 1.day).to_s(:appt_schedule_day)
    prev_start  = (daterange.start_at.in_time_zone - daterange.days.days).to_s(:appt_schedule_day)
    next_link   = link_to("Next", when_start_show_path(:provider_id => provider.id, :provider_type => provider.tableize, :when => next_when, :start_date => next_start))
    prev_link   = link_to("Previous", when_start_show_path(:provider_id => provider.id, :provider_type => provider.tableize, :when => next_when, :start_date => prev_start))

    Hash[:prev_link => prev_link, :next_link => next_link]
  end

  def build_calendar_today_prev_next_links(provider, daterange)

    prev_link = next_link = today_link = nil

    start_date         = daterange.start_at.in_time_zone
    end_date           = daterange.end_at.in_time_zone
    current_range_type = daterange.range_type
    if current_range_type == 'none'
      if daterange.days <= 1
        current_range_type = 'daily'
      elsif daterange.days <= 7
        current_range_type = 'weekly'
      else
        current_range_type = 'monthly'
      end
    end
    
    day_after_end = end_date.tomorrow.beginning_of_day

    case current_range_type
    when 'daily'
      prev_date          = start_date - 1.day
      next_date          = start_date + 1.day
      range_word         = "Day"
      today_word         = "Today"
      today_link         = link_to("#{today_word}",  when_show_path(:when => 'today'))
    when 'weekly'
      prev_date          = start_date - 1.week
      next_date          = (start_date + 1.week < day_after_end) ? (start_date + 1.week) : day_after_end
      range_word         = "Week"
      today_word         = "Week starting today"
    when 'monthly'
      prev_date          = start_date - 1.month
      next_date          = (start_date + 1.month < day_after_end) ? (start_date + 1.month) : day_after_end
      range_word         = "Month"
      today_word         = "Month starting today"
    else # Should never get here
      prev_date          = start_date - 1.month
      next_date          = (start_date + 1.month < day_after_end) ? (start_date + 1.month) : day_after_end
      current_range_type = 'monthly'
      range_word         = "Month"
      today_word         = "Month starting today"
    end

    url_params  = {:provider_id => provider.id, :provider_type => provider.tableize, :subdomain => @subdomain, :range_type => current_range_type}

    if prev_link.blank?
      prev_link = link_to("Previous #{range_word}", 
                          range_type_show_path(url_params.merge({:start_date => prev_date.to_s(:appt_schedule_day)})))
    end
    if next_link.blank?
      next_link = link_to("Next #{range_word}", 
                          range_type_show_path(url_params.merge({:start_date => next_date.to_s(:appt_schedule_day)})))
    end
    if today_link.blank?
      today_link = link_to("#{today_word}",  
                          range_type_show_path(url_params.merge({:start_date => Time.zone.today.to_time.to_s(:appt_schedule_day)})))
    end

    {:today_link => today_link, :prev_link => prev_link, :next_link => next_link}
  end
  
end