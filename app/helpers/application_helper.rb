# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def title(page_title)
    content_for(:title)  { page_title }
  end
  
  def javascript(*files)
    content_for(:javascript) { javascript_include_tag(*files) }
  end

  def stylesheet(*files)
    content_for(:stylesheet) { stylesheet_link_tag(*files) }
  end
  
  FLASH_TYPES = [:error, :warning, :success, :message]

  def display_flash(type = nil)
    html = ""

    if type.nil?
      FLASH_TYPES.each { |name| html << display_flash(name) }
    else
      return flash[type].blank? ? "" : "<div class=\"#{type}\">#{flash[type]}</div>"
    end

    html
  end
  
  def display_message(msg, type = :notice)
    return "" if msg.blank?
    "<div class=\"#{type.to_s}\">#{msg}</div>"
  end
  
  def build_tab_links(current_controller)
    
    # 'Openings' tab
    name = 'Openings'
    if current_controller.controller_name == 'openings' and current_controller.action_name == 'index'
      link = link_to(name, openings_path(:subdomain => @subdomain), :class => 'current')
    else
      link = link_to(name, openings_path(:subdomain => @subdomain))
    end
    
    yield link

    if has_privilege?('update company')

      # 'Schedules' tab
      name = 'Schedules'
      if current_controller.controller_name == 'appointments' and current_controller.action_name == 'index'
        link = link_to(name, appointments_path(:subdomain => @subdomain), :class => 'current')
      else
        link = link_to(name, appointments_path(:subdomain => @subdomain))
      end

      yield link


      # 'Customers' tab
      name = 'Customers'
      if current_controller.controller_name == 'customers' and ['index', 'show'].include?(current_controller.action_name)
        link = link_to(name, customers_path(:subdomain => @subdomain), :class => 'current')
      else
        link = link_to(name, customers_path(:subdomain => @subdomain))
      end

      yield link

      # 'Invoices' tab
      name = 'Invoices'
      if current_controller.controller_name == 'invoices' and ['index', 'show'].include?(current_controller.action_name)
        link = link_to(name, invoices_path, :class => 'current')
      else
        link = link_to(name, invoices_path)
      end

      yield link

      # 'Appointments' tab
      name = 'Appointments'
      if current_controller.controller_name == 'appointments' and ['search', 'show'].include?(current_controller.action_name)
        link = link_to(name, search_appointments_path, :class => 'current')
      else
        link = link_to(name, search_appointments_path)
      end

      yield link
      
      # 'People' tab
      name = 'People'
      if current_controller.controller_name == 'people' and ['index', 'show'].include?(current_controller.action_name)
        link = link_to(name, people_path, :class => 'current')
      else
        link = link_to(name, people_path)
      end

      yield link

      # 'Services' tab
      name = 'Services'
      if current_controller.controller_name == 'services' and ['index', 'show'].include?(current_controller.action_name)
        link = link_to(name, services_path, :class => 'current')
      else
        link = link_to(name, services_path)
      end

      yield link

      # 'Products' tab
      name = 'Products'
      if current_controller.controller_name == 'products' and ['index', 'show'].include?(current_controller.action_name)
        link = link_to(name, products_path, :class => 'current')
      else
        link = link_to(name, products_path)
      end

      yield link

      # 'Waitlist' tab
      name = 'Waitlist'
      if current_controller.controller_name == 'waitlist' and ['index'].include?(current_controller.action_name)
        link = link_to(name, waitlist_index_path, :class => 'current')
      else
        link = link_to(name, waitlist_index_path)
      end

      yield link
    end # 'update company' privilege
  end
  
  # build the set of locations links for the specified company, using the current_location if its given
  def build_location_links(company, current_location=nil)
    # get all company locations, remove the current location
    company_locations = company.locations - Array(current_location)
    
    # add the special anywhere location if its not the current location
    company_locations += Array(Location.anywhere) unless current_location and current_location.anywhere?
    
    # sort locations by name
    company_locations.sort_by{ |l| l.name }.each_with_index do |location, index|
      # build company location link
      name = location.name
      link = set_default_location_path(location)
      last = index == (company_locations.size - 1)
      yield name, link, last
    end
  end
  
end
