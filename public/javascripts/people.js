$(document).ready(function() {
  $(document).init_live_people_search();
  $(document).init_new_object("#new_person");  // don't need to rebind after an ajax call
  $("#live_search_for_people").focus();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_ujs_links();
  $("#live_search_for_people").focus();
})
