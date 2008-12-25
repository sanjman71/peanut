# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def javascript(*files)
    content_for(:javascript) { javascript_include_tag(*files) }
  end

  def stylesheet(*files)
    content_for(:stylesheet) { stylesheet_link_tag(*files) }
  end
  
  def build_tab_links(current_controller)

    # 'Schedules' link
    name = 'Schedules'
    if current_controller.controller_name == 'appointments' and current_controller.action_name == 'index'
      link = link_to(name, appointments_path(:subdomain => @subdomain), :class => 'current')
    else
      link = link_to(name, appointments_path(:subdomain => @subdomain))
    end
    
    yield link

    # 'Openings' link
    name = 'Openings'
    if current_controller.controller_name == 'openings' and current_controller.action_name == 'index'
      link = link_to(name, openings_path(:subdomain => @subdomain), :class => 'current')
    else
      link = link_to(name, openings_path(:subdomain => @subdomain))
    end
    
    yield link

    # 'Customers' link
    name = 'Customers'
    if current_controller.controller_name == 'customers' and ['index', 'show'].include?(current_controller.action_name)
      link = link_to(name, customers_path(:subdomain => @subdomain), :class => 'current')
    else
      link = link_to(name, customers_path(:subdomain => @subdomain))
    end

    yield link

    # 'Appointments' link
    name = 'Appointments'
    if current_controller.controller_name == 'appointments' and ['search', 'show'].include?(current_controller.action_name)
      link = link_to(name, search_appointments_path, :class => 'current')
    else
      link = link_to(name, search_appointments_path)
    end

    yield link

    # 'People' link
    name = 'People'
    if current_controller.controller_name == 'people' and ['index', 'show'].include?(current_controller.action_name)
      link = link_to(name, people_path, :class => 'current')
    else
      link = link_to(name, people_path)
    end

    yield link

    # 'Services' link
    name = 'Services'
    if current_controller.controller_name == 'services' and ['index', 'show'].include?(current_controller.action_name)
      link = link_to(name, services_path, :class => 'current')
    else
      link = link_to(name, services_path)
    end

    yield link

    # 'Products' link
    name = 'Products'
    if current_controller.controller_name == 'products' and ['index', 'show'].include?(current_controller.action_name)
      link = link_to(name, products_path, :class => 'current')
    else
      link = link_to(name, products_path)
    end

    yield link
  end
  
end
