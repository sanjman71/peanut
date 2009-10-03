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

  def display_flash(force = false)
    if force || @flash_displayed.nil? || @flash_displayed == false
      @flash_displayed = true
      render :partial => "shared/flash.html.haml", :object => (flash.nil? ? {} : flash)
    end
  end

  def build_tab_links(current_controller)
    # 'Openings' tab
    name    = 'Openings'
    path    = openings_path(:subdomain => @subdomain)
    klasses = []

    if current_controller.controller_name == 'openings' and ['index'].include?(current_controller.action_name)
      klasses.push('current')
    end

    yield name, path, klasses

    if has_privilege?('read calendars', current_company)

      # 'Schedules' tab
      name    = 'Schedules'
      path    = url_for(:controller => 'calendar', :action => 'index', :subdomain => @subdomain)
      klasses = []

      if current_controller.controller_name == 'calendar' and ['show', 'edit'].include?(current_controller.action_name)
        klasses.push('current')
      end

      yield name, path, klasses
    end

    if has_privilege?('read wait appointments', current_company)

      # 'Waitlist' tab
      name    = 'Waitlist'
      path    = waitlist_index_path
      klasses = []

      if current_controller.controller_name == 'waitlist' and ['index'].include?(current_controller.action_name)
        klasses.push('current')
      end

      yield name, path, klasses
    end

    if has_privilege?('read customers', current_company)

      # 'Customers' tab
      name    = 'Customers'
      path    = customers_path(:subdomain => @subdomain)
      klasses = []

      if current_controller.controller_name == 'customers' and ['index', 'show'].include?(current_controller.action_name)
        klasses.push('current')
      end

      yield name, path, klasses
    end

    if has_privilege?('read services', current_company)
    
      # 'Services' tab
      name    = 'Services'
      path    = services_path
      klasses = []

      if current_controller.controller_name == 'services' and ['index', 'show'].include?(current_controller.action_name)
        klasses.push('current')
      end

      yield name, path, klasses
    end
    
    if has_privilege?('read users', current_company)

      # 'Providers' tab
      name    = 'Providers'
      path    = providers_path
      klasses = []

      if current_controller.controller_name == 'providers' and ['index', 'show', 'edit'].include?(current_controller.action_name)
        klasses.push('current')
      end

      yield name, path, klasses
    end

    # SK: not sure if this is the correct privilege
    if has_privilege?('read calendars', current_company)

      # 'Reports' tab
      name    = 'Reports'
      path    = reports_path
      klasses = []

      if current_controller.controller_name == 'reports' and ['index'].include?(current_controller.action_name)
        klasses.push('current')
      end

      yield name, path, klasses
    end

    if has_role?('company customer', current_company)

      # 'History' tab for customer appointments
      name    = 'History'
      path    = history_index_path
      klasses = []

      if current_controller.controller_name == 'history' and ['index', 'show'].include?(current_controller.action_name)
        klasses.push('current')
      end

      yield name, path, klasses
    end

    # if has_privilege?('read log_entries', current_company)
    # 
    #   # 'Dashboard' tab
    #   name = 'Dashboard'
    #   if current_controller.controller_name == 'log_entries' and ['index'].include?(current_controller.action_name)
    #     link = link_to(name, log_entries_path, :class => 'current')
    #   else
    #     if current_company.log_entries.urgent.unseen.size > 0
    #       link = link_to(name, log_entries_path, :class => 'urgent')
    #     elsif current_company.log_entries.approval.unseen.size > 0
    #       link = link_to(name, log_entries_path, :class => 'approval')
    #     else
    #       link = link_to(name, log_entries_path)
    #     end
    #   end
    # 
    #  yield link
    # end
  end

  def build_admin_tab_links
    if has_privilege?('manage site')
      yield 'Admin Console', root_path(:subdomain => 'www'), Array.new
    end
  end
  
  def build_signup_links(current_controller)
    # 'Signup' tab
    name    = 'Signup'
    path    = signup_beta_path
    klasses = []

    if current_controller.controller_name == 'signup'
      klasses.push('current')
    end

    yield name, path, klasses

    if has_privilege?('manage site')
      klasses = current_controller.controller_name == 'promotions' ? ['current'] : []
      yield 'Promotions', promotions_path, klasses

      klasses = current_controller.controller_name == 'companies' ? ['current'] : []
      yield 'Companies', companies_path, klasses
    end
  end

  # build provider display name based on context of the current user
  def provider_display_name(provider, current_user)
    return "" if provider.blank?
    (provider == current_user) ? "Me" : provider.name
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
