// build a report
$.fn.init_report_form = function() {
  $("#report_submit").click(function() {
    // post the report query
    $.post($("form#report_form").attr("action"), $("form#report_form").serialize(), null, "script");

    // replace the search button with a progress image onsubmit
    $("#report_submit").hide();
    $("#report_progress").show();
    
    return false;
  })
}

$(document).ready(function() {
  $(".datepicker").datepicker({minDate: +0, maxDate: '+2m'});  
  $(document).init_report_form();
})