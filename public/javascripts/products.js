$(document).ready(function() {
  $(document).init_new_object("#new_product_form");  // don't need to rebind after an ajax call
  $("#new_product_name").focus();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
 $(document).init_ujs_links();
 $("#new_product_name").focus();
})