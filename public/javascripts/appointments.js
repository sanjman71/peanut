$(document).ready(function() {
  $(document).init_add_free_time();
  $(document).init_show_appointments();
  $(document).init_highlight_appointments();
  
  // Re-initialize after an ajax call
  $("#add_free_time_form").ajaxComplete(function(request, settings){
    $(document).init_add_free_time();
    $(document).init_show_appointments();
    $(document).init_highlight_appointments();
  })
})
