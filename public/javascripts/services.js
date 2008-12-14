$(document).ready(function() {
  $(document).init_new_membership();
  $(document).init_new_service();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
 $(document).init_ujs_links();
 $(document).init_new_membership();
 $(document).init_new_service();
})