module EventsHelper

  EVENT_MESSAGE_IDS =
    {
      :appointment_confirmation => 1,
      :added_to_waitlist => 2,
      :appointment_canceled => 3,
      :waitlist_canceled => 4
    }

  EVENT_MESSAGES = 
  {
    EVENT_MESSAGE_IDS[:appointment_confirmation] =>
      '#{link_to event.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => event.customer.id, :state => \'upcoming\')} confirmed a #{event.eventable.service.name } #{link_to \'appointment\', appointment_path(event.eventable, :subdomain => current_subdomain)}.',
    EVENT_MESSAGE_IDS[:added_to_waitlist] =>
      '#{link_to event.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => event.customer.id, :state => \'upcoming\')} added to waitlist for a #{event.eventable.service.name } #{link_to \'appointment\', appointment_path(event.eventable, :subdomain => current_subdomain)}.',
    EVENT_MESSAGE_IDS[:appointment_canceled] =>
      '#{link_to event.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => event.customer.id, :state => \'canceled\')} canceled a #{event.eventable.service.name } #{link_to \'appointment\', appointment_path(event.eventable, :subdomain => current_subdomain)}.',
    EVENT_MESSAGE_IDS[:waitlist_canceled] =>
      '#{link_to event.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => event.customer.id, :state => \'upcoming\')} removed a #{event.eventable.service.name} #{link_to \'appointment\', appointment_path(event.eventable, :subdomain => current_subdomain)} from waitlist.'
  }

  def event_types_for_select
    [["Urgent", "1"], ["Approval", "2"], ["Informational", "3"]]
  end

  def message_id_to_str(id)
    EVENT_MESSAGES[id]
  end

end
