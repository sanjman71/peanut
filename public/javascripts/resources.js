$(document).ready(function() {
  $(document).init_add_company_resource();
  $(document).init_live_resources_search();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_add_company_resource();
})
