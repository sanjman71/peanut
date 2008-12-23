$(document).ready(function() {
  $(document).init_new_product();
  $("#add_product_name").focus();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
 $(document).init_ujs_links();
 $(document).init_new_product();
 $("#add_product_name").focus();
})