$.fn.init_toggle_user_calendar = function() {
  $(".checkbox.user").click(function() {
    // hide checkbox and label
    $(this).hide();
    $(this).siblings(".checkbox.label").hide();
    // show progress bar
    $(this).siblings(".checkbox.progress").show();
    // post data
    $.post($(this).attr("url"), {}, null, "script");
    return false;
  })
}

$(document).ready(function() {
  $(document).init_toggle_user_calendar();  // re-bind after an ajax call
  
})

$(document).ajaxComplete(function(request, settings) {
  $(document).init_toggle_user_calendar();
})
