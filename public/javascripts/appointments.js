$(document).ready(function() {
  $(document).init_add_free_time(); // don't need to rebind after an ajax call
  $(document).init_show_appointments();
  $(document).init_highlight_appointments();
  $(document).init_search_appointments_by_confirmation_code();  // don't need to rebind after an ajax call
  $('#appointment_code').focus();
  $('#appointment_time_range_start_at').focus();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_show_appointments();
  $(document).init_highlight_appointments();
})
