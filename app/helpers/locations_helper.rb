module LocationsHelper

  def location_title_renderer(location)
    if location.nil?
      return ''
    else
      h(location.location_name)
    end
  end

  def location_short_title_renderer(location)
    ''
  end
  
  def location_address_renderer(location, horizontal = false, render_country = false)
    if location.nil?
      return ''
    end
    country_pair = Location::COUNTRIES.detect {|country_pair| country_pair[1] == location.country}
    country_name = country_pair ? country_pair[0] : location.country
    line_break = horizontal ? '' : '<br />'
    result = ''
    result += h(location.street_addr) + ', <br />' unless location.street_addr.blank?
    result += h(location.city) + ', ' + line_break unless location.city.blank?
    result += h(location.state) unless location.state.blank?
    result += ' ' + location.zip unless location.zip.blank?
    result += ', ' + line_break unless ((render_country == false) || (country_name.blank) || (location.zip.blank? && location.state.blank?) )
    result += h(country_name) unless (render_country == false || country_name.blank?)
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
  
end
