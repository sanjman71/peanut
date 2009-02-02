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
  
  # build title based on the current company and location
  def current_company_title_with_location
    name  = current_company.name
    # add location name if we have at least company location
    name += " - #{current_location.name}" unless current_locations.size == 0 or current_location.blank?
    name
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

    if has_privilege?('read work appointments', current_company)

      # 'Schedules' tab
      name = 'Schedules'
      if current_controller.controller_name == 'appointments' and current_controller.action_name == 'index'
        link = link_to(name, appointments_path(:subdomain => @subdomain), :class => 'current')
      else
        link = link_to(name, appointments_path(:subdomain => @subdomain))
      end

      yield link

    end

    if has_privilege?('read waitlist', current_company)

      # 'Waitlist' tab
      name = 'Waitlist'
      if current_controller.controller_name == 'waitlist' and ['index'].include?(current_controller.action_name)
        link = link_to(name, waitlist_index_path, :class => 'current')
      else
        link = link_to(name, waitlist_index_path)
      end

      yield link

    end

    if has_privilege?('read customers', current_company)

      # 'Customers' tab
      name = 'Customers'
      if current_controller.controller_name == 'customers' and ['index', 'show'].include?(current_controller.action_name)
        link = link_to(name, customers_path(:subdomain => @subdomain), :class => 'current')
      else
        link = link_to(name, customers_path(:subdomain => @subdomain))
      end

      yield link

    end
  
    if has_privilege?('read invoices', current_company)

      # 'Invoices' tab
      name = 'Invoices'
      if current_controller.controller_name == 'invoices' and ['index', 'show'].include?(current_controller.action_name)
        link = link_to(name, invoices_path, :class => 'current')
      else
        link = link_to(name, invoices_path)
      end

      yield link

    end
    
    if has_privilege?('read work appointments', current_company)

      # 'Appointments' tab
      name = 'Appointments'
      if current_controller.controller_name == 'appointments' and ['search', 'show'].include?(current_controller.action_name)
        link = link_to(name, search_appointments_path, :class => 'current')
      else
        link = link_to(name, search_appointments_path)
      end

      yield link

    end
      
    if has_privilege?('read people', current_company)

      # 'People' tab
      name = 'People'
      if current_controller.controller_name == 'people' and ['index', 'show'].include?(current_controller.action_name)
        link = link_to(name, people_path, :class => 'current')
      else
        link = link_to(name, people_path)
      end

      yield link

    end
    
    if has_privilege?('read services', current_company)

      # 'Services' tab
      name = 'Services'
      if current_controller.controller_name == 'services' and ['index', 'show'].include?(current_controller.action_name)
        link = link_to(name, services_path, :class => 'current')
      else
        link = link_to(name, services_path)
      end

      yield link

    end

    if has_privilege?('read products', current_company)

      # 'Products' tab
      name = 'Products'
      if current_controller.controller_name == 'products' and ['index', 'show'].include?(current_controller.action_name)
        link = link_to(name, products_path, :class => 'current')
      else
        link = link_to(name, products_path)
      end

      yield link
      
    end
  end
  
  def build_admin_tab_links
    if has_privilege?('create companies')
      link = link_to 'Admin Console', companies_path(:subdomain => nil)
      yield link
    end
  end
  
  # build the set of locations links for the current company, using the current locations collection
  def build_company_location_links
    # get all company locations, remove the current location
    locations = current_locations - Array(current_location)
    
    # add the special anywhere location if its not the current location
    locations += Array(Location.anywhere) unless current_location and current_location.anywhere?
    
    # sort locations by name
    locations.sort_by{ |l| l.name }.each_with_index do |location, index|
      # build company location link
      link = select_location_path(location)
      last = index == (locations.size - 1)
      yield location.name, link, last
    end
  end
  
end
