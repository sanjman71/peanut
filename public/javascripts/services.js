$(document).ready(function() {
  $(document).init_add_service_provider();
  $(document).init_new_object("#new_service_form");  // don't need to rebind after an ajax call
  $("#new_service_name").focus();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
 $(document).init_add_service_provider();
 $("#new_service_name").focus();
})