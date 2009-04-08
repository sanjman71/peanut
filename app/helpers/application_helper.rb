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
    
  FLASH_TYPES = [:error, :warning, :success, :message, :notice]

  def display_flash(type = nil)
    if type.nil? or type == :all
      html = FLASH_TYPES.collect { |name| display_flash(name) }
      return html
    else
      return flash[type].blank? ? "" : "<div class=\"#{type}\">#{flash[type]}</div>"
    end
  end
  
  def display_message(msg, type = :notice)
    return "" if msg.blank?
    "<div class=\"#{type.to_s}\">#{msg}</div>"
  end
    
  def build_tab_links(current_controller)
    # 'Openings' tab
    name = 'Openings'
    if current_controller.controller_name == 'openings' and ['index'].include?(current_controller.action_name)
      link = link_to(name, openings_path(:subdomain => @subdomain), :class => 'current')
    else
      link = link_to(name, openings_path(:subdomain => @subdomain))
    end
    
    yield link

    if has_privilege?('read calendars', current_company)

      # 'Schedules' tab
      name = 'Schedules'
      if current_controller.controller_name == 'calendar' and ['show', 'edit'].include?(current_controller.action_name)
        link = link_to(name, url_for(:controller => 'calendar', :action => 'index', :subdomain => @subdomain), :class => 'current')
      else
        link = link_to(name, url_for(:controller => 'calendar', :action => 'index', :subdomain => @subdomain))
      end

      yield link

    end

    if has_privilege?('read wait appointments', current_company)

      # 'Waitlist' tab
      name = 'Waitlist'
      if current_controller.controller_name == 'waitlist' and ['index'].include?(current_controller.action_name)
        link = link_to(name, waitlist_index_path, :class => 'current')
      else
        link = link_to(name, waitlist_index_path)
      end

      yield link

    end

    if has_role?(Company.customer_role_name, current_company)

      # 'Appointments' tab for customer work appointments
      name = 'Appointments'
      if current_controller.controller_name == 'appointments' and ['index', 'search', 'show'].include?(current_controller.action_name)
        link = link_to(name, customer_appointments_path(current_user), :class => 'current')
      else
        link = link_to(name, customer_appointments_path(current_user))
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
  
    # if has_privilege?('read invoices', current_company)
    # 
    #   # 'Invoices' tab
    #   name = 'Invoices'
    #   if current_controller.controller_name == 'invoices' and ['index', 'show'].include?(current_controller.action_name)
    #     link = link_to(name, invoices_path, :class => 'current')
    #   else
    #     link = link_to(name, invoices_path)
    #   end
    # 
    #   yield link
    # 
    # end
    
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

    # if has_privilege?('read products', current_company)
    # 
    #   # 'Products' tab
    #   name = 'Products'
    #   if current_controller.controller_name == 'products' and ['index', 'show'].include?(current_controller.action_name)
    #     link = link_to(name, products_path, :class => 'current')
    #   else
    #     link = link_to(name, products_path)
    #   end
    # 
    #   yield link
    #   
    # end
    
    if has_privilege?('read users', current_company)
    
      # 'Providers' tab
      name = 'Providers'
      if current_controller.controller_name == 'providers' and ['index', 'show', 'edit'].include?(current_controller.action_name)
        link = link_to(name, providers_path, :class => 'current')
      else
        link = link_to(name, providers_path)
      end

      yield link
    end
    
    if has_privilege?('read events', current_company)

      # 'Dashboard' tab
      name = 'Dashboard'
      if current_controller.controller_name == 'events' and ['index'].include?(current_controller.action_name)
        link = link_to(name, events_path, :class => 'current')
      else
        if current_company.events.urgent.unseen.size > 0
          link = link_to(name, events_path, :class => 'urgent')
        elsif current_company.events.approval.unseen.size > 0
          link = link_to(name, events_path, :class => 'approval')
        else
          link = link_to(name, events_path)
        end
      end

     yield link
    end
  end
  
  def build_admin_tab_links
    if has_privilege?('create companies')
      link = link_to 'Admin Console', root_path(:subdomain => 'www')
      yield link
    end
  end
  
  # build schedulable display name based on context of the current user
  def schedulable_display_name(schedulable, current_user)
    return "" if schedulable.blank?
    (schedulable == current_user) ? "Me" : schedulable.name
  end
  
  # build customer display name based on context of the current user
  def customer_display_name(customer, current_user)
    return "" if customer.blank?
    (customer == current_user) ? "Me" : customer.name
  end

  # build user display name based on context of the current user
  def user_display_name(user, current_user)
    return "" if user.blank?
    (user == current_user) ? "Me" : user.name
  end
  
  def build_company_location_select_options
    anywhere = Location.anywhere
    [[anywhere.name, anywhere.id]] + current_locations.collect{ |l| [l.name, l.id]}
  end
  
  def mobile_carrier_select_options
    [["Select a carrier", nil]] + MobileCarrier.all.collect { |o| [o.name, o.id] }
  end
  def use_tiny_mce
    # Avoid multiple inclusions
    unless @content_for_tiny_mce
      @content_for_tiny_mce = "" 
      content_for :tiny_mce do
        javascript_include_tag('tiny_mce/tiny_mce') + javascript_include_tag('tiny_mce_editor')
      end
    end
  end
  
end
