module LogEntriesHelper

  LOG_ENTRY_MESSAGE_IDS =
    {
      :appointment_confirmation => 1,
      :added_to_waitlist => 2,
      :appointment_canceled => 3,
      :waitlist_canceled => 4,
      :approval_request => 5,
      :cancel_request => 6,
      :sent_appointment_confirmation_email => 7,
      :sent_appointment_confirmation_sms => 8,
      :sent_waitlist_confirmation_email => 9,
      :sent_waitlist_confirmation_sms => 10
    }

  LOG_ENTRY_MESSAGES = 
  {
    LOG_ENTRY_MESSAGE_IDS[:appointment_confirmation] =>
      '#{link_to log_entry.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => log_entry.customer.id, :state => \'upcoming\')} confirmed a #{log_entry.loggable.service.name } #{link_to \'appointment\', appointment_path(log_entry.loggable, :subdomain => current_subdomain)}.',
    LOG_ENTRY_MESSAGE_IDS[:added_to_waitlist] =>
      '#{link_to log_entry.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => log_entry.customer.id, :state => \'upcoming\')} added to waitlist for a #{log_entry.loggable.service.name } #{link_to \'appointment\', appointment_path(log_entry.loggable, :subdomain => current_subdomain)}.',
    LOG_ENTRY_MESSAGE_IDS[:appointment_canceled] =>
      '#{link_to log_entry.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => log_entry.customer.id, :state => \'canceled\')} canceled a #{log_entry.loggable.service.name } #{link_to \'appointment\', appointment_path(log_entry.loggable, :subdomain => current_subdomain)}.',
    LOG_ENTRY_MESSAGE_IDS[:waitlist_canceled] =>
      '#{link_to log_entry.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => log_entry.customer.id, :state => \'upcoming\')} removed a #{log_entry.loggable.service.name} #{link_to \'appointment\', appointment_path(log_entry.loggable, :subdomain => current_subdomain)} from waitlist.',
    LOG_ENTRY_MESSAGE_IDS[:approval_request] =>
      '#{link_to log_entry.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => log_entry.customer.id, :state => \'upcoming\')} requested a #{log_entry.loggable.service.name} #{link_to \'appointment\', appointment_path(log_entry.loggable, :subdomain => current_subdomain)}.',
    LOG_ENTRY_MESSAGE_IDS[:cancel_request] =>
      '#{link_to log_entry.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => log_entry.customer.id, :state => \'upcoming\')} canceled their request for a #{log_entry.loggable.service.name} #{link_to \'appointment\', appointment_path(log_entry.loggable, :subdomain => current_subdomain)}.',
    LOG_ENTRY_MESSAGE_IDS[:sent_appointment_confirmation_email] =>
      'Sent email appointment confirmation to #{link_to log_entry.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => log_entry.customer.id, :state => \'upcoming\')} for their #{log_entry.loggable.service.name} #{link_to \'appointment\', appointment_path(log_entry.loggable, :subdomain => current_subdomain)}.',
    LOG_ENTRY_MESSAGE_IDS[:sent_appointment_confirmation_sms] =>
      'Sent SMS appointment confirmation to #{link_to log_entry.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => log_entry.customer.id, :state => \'upcoming\')} for their #{log_entry.loggable.service.name} #{link_to \'appointment\', appointment_path(log_entry.loggable, :subdomain => current_subdomain)}.',
    LOG_ENTRY_MESSAGE_IDS[:sent_waitlist_confirmation_email] =>
      'Sent email waitlist confirmation to #{link_to log_entry.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => log_entry.customer.id, :state => \'upcoming\')} for their #{log_entry.loggable.service.name} #{link_to \'appointment\', appointment_path(log_entry.loggable, :subdomain => current_subdomain)}.',
    LOG_ENTRY_MESSAGE_IDS[:sent_waitlist_confirmation_sms] =>
      'Sent SMS waitlist confirmation to #{link_to log_entry.customer.name, url_for(:subdomain => current_subdomain, :controller => \'appointments\', :action => \'index\', :customer_id => log_entry.customer.id, :state => \'upcoming\')} for their #{log_entry.loggable.service.name} #{link_to \'appointment\', appointment_path(log_entry.loggable, :subdomain => current_subdomain)}.'
  }

  def log_entry_types_for_select
    [["Urgent", "1"], ["Approval", "2"], ["Informational", "3"]]
  end

  def message_id_to_str(id)
    LOG_ENTRY_MESSAGES[id]
  end

end
