# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def build_tab_links(current_controller)

    # 'Schedules' link
    name = 'Schedules'
    if current_controller.controller_name == 'appointments' and current_controller.action_name == 'index'
      link = link_to(name, appointments_path, :class => 'current')
    else
      link = link_to(name, appointments_path)
    end
    
    yield link

    # 'Openings' link
    name = 'Openings'
    if current_controller.controller_name == 'openings' and current_controller.action_name == 'index'
      link = link_to(name, openings_path, :class => 'current')
    else
      link = link_to(name, openings_path)
    end
    
    yield link

    # 'Customers' link
    name = 'Customers'
    if current_controller.controller_name == 'customers' and current_controller.action_name == 'index'
      link = link_to(name, customers_path, :class => 'current')
    else
      link = link_to(name, customers_path)
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
    if current_controller.controller_name == 'people' and current_controller.action_name == 'index'
      link = link_to(name, people_path, :class => 'current')
    else
      link = link_to(name, people_path)
    end

    yield link
  end
  
end
