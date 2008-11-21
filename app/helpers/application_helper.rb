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

    # 'Resources' link
    name = 'Resources'
    if current_controller.controller_name == 'resources' and current_controller.action_name == 'index'
      link = link_to(name, resources_path, :class => 'current')
    else
      link = link_to(name, resources_path)
    end

    yield link
  end
  
end
