$(document).ready(function() {
  $(document).init_new_membership();
  $(document).init_new_service();
  $("#add_service_name").focus();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
 $(document).init_ujs_links();
 $(document).init_new_membership();
 $(document).init_new_service();
 $("#add_service_name").focus();
})