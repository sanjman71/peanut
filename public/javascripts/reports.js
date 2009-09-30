// build a report
$.fn.init_reports_form = function() {
  $("#report_submit").click(function() {
    // validate dates
    var start_date = $('input#report_start_date').attr("value");
    var end_date   = $('input#report_end_date').attr("value");

    if (!start_date) {
      $('input#report_start_date').addClass('highlighted');
      alert("Please enter a start date");
      return false;
    } else {
      $('input#report_start_date').removeClass('highlighted');
    }

    if (!end_date) {
      $('input#report_end_date').addClass('highlighted');
      alert("Please enter an end date");
      return false;
    } else {
      $('#end_date').removeClass('highlighted');
    }
    
    if (end_date <= start_date) {
      alert("The start date must be before the end date");
      return false;
    }

    // post the report query
    $.post($("form#report_form").attr("action"), $("form#report_form").serialize(), null, "script");

    // replace the search button with a progress image onsubmit
    $(this).replaceWith("<h3 class ='submitting'>Generating...</h3>");
    
    return false;
  })
}

$.fn.init_datepicker_reports = function() {
  $(".datepicker").datepicker({minDate: '-3m', maxDate: '+0'});
}

$(document).ready(function() {
  $(document).init_datepicker_reports();
  $(document).init_reports_form();
})