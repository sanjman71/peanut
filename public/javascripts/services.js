$(document).ready(function() {
  $(document).init_new_membership();
  $(document).init_new_object("#new_service");  // don't need to rebind after an ajax call
  $("#new_service_name").focus();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
 $(document).init_ujs_links();
 $(document).init_new_membership();
 $("#new_service_name").focus();
})