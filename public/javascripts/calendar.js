// relaod calendar when a new provider is selected
$.fn.init_change_calendar_provider = function () {
  $("#show_provider").change(function () {
    var href = '/' + this.value + '/calendar';
    window.location = href;
    $("#calendar").replaceWith("<h3 class='submitting' style='text-align: center;'>Loading Schedule...</h3>");
    return false;
  })
}

$.fn.init_schedule_pdf = function() {
  // initialize show pdf date range dialog
  $("div.dialog#pdf_schedule_date_range_dialog").dialog({modal: true, autoOpen: false, hide: 'slide', width: 350, height: 200, show: 'fadeIn(slow)', title: $("div#pdf_schedule_date_range_dialog").attr('title')})

  $("a#pdf_schedule_date_range").click(function() {
    // clear date form fields
    $("div.dialog#pdf_schedule_date_range_dialog input.datepicker").val('');
    // open dialog on click
    $("div.dialog#pdf_schedule_date_range_dialog").dialog('open');
    return false;
  })

  $("form#pdf_schedule_date_range_form").submit(function() {
    // check start, end dates
    var start_date  = $(this).find("input#pdf_start_date").attr('value');
    var end_date    = $(this).find("input#pdf_end_date").val();
  
    if (!start_date) {
      alert("Please enter a start date");
      return false;
    }

    if (!end_date) {
      alert("Please enter an end date");
      return false;
    }

    if (validate_start_before_equal_end_date(start_date, end_date) == false) {
      alert("The end date is earlier than the start date");
      return false;
    }
  
    // close dialog
    $("div.dialog#pdf_schedule_date_range_dialog").dialog('close');

    return true;
  })
}

$(document).ready(function() {
  $(document).init_change_calendar_provider();
  $(document).init_schedule_pdf();
});
