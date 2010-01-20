module LocationsHelper

  def location_title_renderer(location)
    if location.nil?
      return ''
    elsif location.name.blank?
      h(location.street_address + ', ' + location.city.name + ' ' + location.state.code + ' ' + location.zip.name)
    else
      h(location.name)
    end
  end

  def location_short_title_renderer(location)
    ''
  end
  
  def location_address_renderer(location, horizontal = false, render_country = false)
    if location.nil?
      return ''
    end
    line_break = horizontal ? '' : '<br />'
    result = ''
    result += h(location.street_address) + ', <br />' unless location.street_address.blank?
    result += h(location.city.name) + ', ' + line_break unless location.city.blank?
    result += h(location.state.code) unless location.state.blank?
    result += ' ' + location.zip.name unless location.zip.blank?
    result += ', ' + line_break unless ((render_country == false) || (location.country.blank) || (location.zip.blank? && location.state.blank?) )
    result += h(location.country.name) unless (render_country == false || location.country.blank?)
    result.gsub(/([^\\])\'/, '\1\\\\\'' )
  end

  def location_map_info(location)
    if location.nil?
      return ''
    end
    result = ''
    result += '<span class="location_map_info">'
    result += '<span class="location_title">'
    result += location_short_title_renderer(location)
    result += '</span><br />'
    result += location_address_renderer(location, true, false)
    result += '<br />' + h(location.phone) unless location.phone.blank?
    result += '<br />' + h(location.email) unless location.email.blank?
    result += '</span>'
    result.gsub(/([^\\])\'/, '\1\\\\\'' )
  end  

  # This is based on the implementation of page_entries_info in will_paginate's view_helpers.rb
  def location_page_info(collection, options = {})
    entry_name = options[:entry_name] ||
      (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))
    
    if collection.total_pages <= 3
      case collection.size
      when 0; "No #{entry_name.pluralize} found"
      else;   ""
      end
    else
      %{#{entry_name.pluralize} <b>%d&nbsp;-&nbsp;%d</b> of <b>%d</b>} % [
        collection.offset + 1,
        collection.offset + collection.length,
        collection.total_entries
      ]
    end
  end

  def locations_for_select(locatable)
    o = [[]]
    o[0] = ['Any', 0]
    o = o + options_for_select(locatable.locations.collect{ |l| [location_title_renderer(l), l.id]}, @current_company.id)
    o
  end
  
  def states_for_select(country)
    s = country.states.order_by_code.collect { |c| [c.name, c.id] }
  end
  
  def countries_for_select()
    c = Country.all.collect { |c| ["#{c.name}", c.id]}
  end
  
end
