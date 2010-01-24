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
    
    if (validate_start_before_equal_end_date(start_date, end_date) == false) {
      alert("The end date is earlier than the start date");
      return false;
    }
    
    // check filter fields, and remove them if they are no visible
    if (!$("div#report_provider").is(":visible")) {
      $("div#report_provider").remove();
    }

    if (!$("div#report_service").is(":visible")) {
      $("div#report_service").remove();
    }

    // post the report query
    $.post($("form#report_form").attr("action"), $("form#report_form").serialize(), null, "script");

    // replace the search button with text
    $(this).replaceWith("<h3 class ='submitting'>Generating...</h3>");

    return false;
  })
}

$.fn.init_reports_filter = function() {
  $("select#report_filter").change(function() {
    // hide all filters
    $("div.report_filter").hide();
    
    if (this.value != 'any') {
      // show specific filter
      $("div#report_"+this.value).show();
    }

    return true;
  })
}

$.fn.init_datepicker_reports = function() {
  $("input.report.datepicker").datepicker({minDate: '-3m', maxDate: '+0'});
}

$(document).ready(function() {
  $(document).init_datepicker_reports();
  $(document).init_reports_filter();
  $(document).init_reports_form();
})