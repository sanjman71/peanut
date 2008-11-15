# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  
  def build_tab_links(current_controller)

    # 'Schedules' link
    name = 'Schedules'
    if current_controller.controller_name == 'free' and current_controller.action_name == 'manage'
      link = link_to(name, manage_free_path, :class => 'current')
    else
      link = link_to(name, manage_free_path)
    end
    
    yield link

    # 'Openings' link
    name = 'Openings'
    if current_controller.controller_name == 'free' and current_controller.action_name == 'index'
      link = link_to(name, free_index_path, :class => 'current')
    else
      link = link_to(name, free_index_path)
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
