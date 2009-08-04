// add free time for a provider on a specific day
$.fn.init_add_single_free_time = function() {
  $("#add_single_free_time_form").submit(function () {
    var start_at  = $("#start_at").attr('value');
    var end_at    = $("#end_at").attr('value');
    var errors    = 0;
    
    if (!start_at) {
      $("#start_at").addClass('highlighted');
      errors += 1;
    } else {
      $("#start_at").removeClass('highlighted');
    }

    if (!end_at) {
      $("#end_at").addClass('highlighted');
      errors += 1;
    } else {
      $("#end_at").removeClass('highlighted');
    }

    if (errors > 0) { return false; }

    // normalize time format, validate that start_at < end_at
    var start_at = $(document).convert_time_ampm_to_string(start_at)
    var end_at   = $(document).convert_time_ampm_to_string(end_at)

    if (!(start_at <= end_at)) {
      alert("The start time must be earlier than the end time");
      return false;
    }

    $("#start_at").attr('value', start_at);
    $("#end_at").attr('value', end_at);

    $.post(this.action, $(this).serialize(), null, "script");
    $(this).find("#submit").hide();
    $(this).find("#progress").show();

    return false;
  })
}


// show appointment data (e.g. edit/delete links) on hover
$.fn.init_show_appointment_on_hover = function () {
  $(".appointment").hover(
    function () {
      $("#hover_" + this.id).show();
    },
    function () {
      $("#hover_" + this.id).hide();
    }
  )
} 

// show calendar for the selected provider
$.fn.init_select_calendar_show_provider = function () {
  $("#show_provider").change(function () {
    var href = '/' + this.value + '/calendar';
    window.location = href;
    return false;
  })
}

// search provider calendar with a date range
$.fn.init_search_calendar_with_date_range = function () {
  $(".datepicker").datepicker({minDate: +0, maxDate: '+3m'});

  // check date fields before submit
  $("#search_calendar_with_date_range_submit").click(function() {
    var start_date = $('#start_date').attr("value");
    var end_date   = $('#end_date').attr("value");

    if (!start_date) {
      $('#start_date').addClass('highlighted');
      alert("Please enter a start date");
      return false;
    } else {
      $('#start_date').removeClass('highlighted');
    }

    if (!end_date) {
      $('#end_date').addClass('highlighted');
      alert("Please enter an end date");
      return false;
    } else {
      $('#end_date').removeClass('highlighted');
    }

    if (end_date <= start_date) {
      $('#start_date').addClass('highlighted');
      $('#end_date').addClass('highlighted');
      alert("The start date must be before the end date");
      return false;
    }
  })
}

$.fn.init_timepicker = function() {
  $(".timepicker").timepickr({convention:12});
}

$(document).ready(function() {
  $(document).init_search_calendar_with_date_range();
  $(document).init_timepicker();
  $(document).init_add_single_free_time();
  $(document).init_select_calendar_show_provider();
  $(document).init_show_appointment_on_hover();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_select_calendar_show_provider();
})
