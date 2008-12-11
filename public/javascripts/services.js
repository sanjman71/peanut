$(document).ready(function() {
  $(document).init_new_membership();
  $(document).init_new_service();

  // Re-initialize after an ajax call
  $("#new_membership").ajaxComplete(function(request, settings) {
    $(document).init_ujs_links();
    $(document).init_new_membership();
    $(document).init_new_service();
  })
})