$(document).ready(function() {
  $(document).init_add_free_time(); // don't need to rebind after an ajax call
  $(document).init_select_schedulable_for_appointment_calendar();
  $(document).init_highlight_appointments();
  $(document).init_search_appointments_by_confirmation_code();  // don't need to rebind after an ajax call
  $('#appointment_code').focus();
  $('#appointment_time_range_start_at').focus();

  Date.firstDayOfWeek = 7;
  Date.format = 'mm/dd/yyyy';

  $(document).init_datepicker({start_date : (new Date()).asString(), end_date : (new Date()).addMonths(1).asString(), max_days:10});
  $(document).init_toggle_dates();

  // rounded corners
  $('.rounded').corners();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_select_schedulable_for_appointment_calendar();
  $(document).init_highlight_appointments();
})
