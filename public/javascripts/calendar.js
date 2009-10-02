// add free time for a provider on a specific day
$.fn.init_add_single_free_time = function() {
  $("#add_single_free_time_form").submit(function () {
    var when      = $("input#date").attr('value');
    var start_at  = $("input#start_at").attr('value');
    var end_at    = $("input#end_at").attr('value');
    var errors    = 0;
    
    if (!when) {
      $("input#date").addClass('highlighted');
      alert("Please select a date");
      return false; 
    } else {
      $("input#date").removeClass('highlighted');
    }
    
    if (!start_at) {
      $("input#start_at").addClass('highlighted');
      alert("Please select a start time");
      return false; 
    } else {
      $("input#start_at").removeClass('highlighted');
    }

    if (!end_at) {
      $("input#end_at").addClass('highlighted');
      alert("Please select an end time");
      return false; 
    } else {
      $("input#end_at").removeClass('highlighted');
    }

    // normalize time format, validate that start_at < end_at
    var start_at = convert_time_ampm_to_string(start_at)
    var end_at   = convert_time_ampm_to_string(end_at)

    if (!(start_at <= end_at)) {
      alert("The start time must be earlier than the end time");
      return false;
    }

    // normalize date format
    var when = convert_date_to_string(when);

    // replace form data with formatted versions
    $("input#start_at").attr('value', start_at);
    $("input#end_at").attr('value', end_at);
    $("input#date").attr('value', when);

    // post
    $.post(this.action, $(this).serialize(), null, "script");
    $(this).find('input[type="submit"]').replaceWith("<h3 class ='submitting'>Adding...</h3>");
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
    $("#schedule_container").replaceWith("<h3 class='submitting' style='text-align: center;'>Loading Schedule...</h3>");
    return false;
  })
}

// search provider calendar with a date range
$.fn.init_search_calendar_with_date_range = function () {
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
      alert("The start date must be before the end date");
      return false;
    }
  })
}

$.fn.init_datepicker = function() {
  $(".datepicker").datepicker({minDate: +0, maxDate: '+3m'});
}

$.fn.init_timepicker = function() {
  $(".timepicker").timepickr({convention:12, left:-180});
}

$.fn.init_send_pdf = function() {
  $("#send_pdf_dialog").dialog({ autoOpen: false });
  
  $("#send_pdf").click(function() {
    // open dialog when link is clicked
    $("#send_pdf_dialog").dialog('open');
    return false;
  })
  
  $("#send_pdf_button").click(function() {
    // find checked radio button
    var checked = $(".pdf_group:checked").val();
    if (!checked) {
      alert("Please select an option");
      return false;
    }
    //$.post(this.action, $(this).serialize(), null, "script");
    $(this).replaceWith("<h3 class ='submitting'>Sending...</h3>");
    return false;
  })
}

$(document).ready(function() {
  $(document).init_datepicker();
  $(document).init_timepicker();
  $(document).init_search_calendar_with_date_range();
  $(document).init_add_single_free_time();
  $(document).init_select_calendar_show_provider();
  $(document).init_show_appointment_on_hover();
  $(document).init_send_pdf();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_select_calendar_show_provider();
})
