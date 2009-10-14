// search waitlist for the selected provider
$.fn.init_select_search_waitlist_provider = function () {
  $("#search_provider").change(function () {
    var href = '/' + this.value + '/waitlist';
    window.location = href;
    return false;
  })
}

$.fn.init_add_waitlist = function() {
  $("#add_waitlist_submit").click(function() {
    // validate customer signup
    var customer_id = $("input#waitlist_customer_id").attr('value');
    
    if (!customer_id) {
      alert("Please login to continue");
      return false;
    }

    // check dates and teims
    var start_date  = $('input#start_date').attr("value");
    var end_date    = $('input#end_date').attr("value");
    var start_time  = $('input#start_time').attr("value");
    var end_time    = $('input#end_time').attr("value");

    if (!start_date) {
      alert("Please enter a start date");
      return false;
    }
    
    if (!end_date) {
      alert("Please enter an end date");
      return false;
    }

    if (end_date <= start_date) {
      alert("The start date must be before the end date");
      return false;
    }
    
    if (!start_time) {
      alert("Please enter a start time");
      return false;
    }

    if (!end_time) {
      alert("Please enter an end time");
      return false;
    }

    // normalize start, end times
    start_time = convert_time_ampm_to_string(start_time)
    end_time   = convert_time_ampm_to_string(end_time)

    if (!(start_time <= end_time)) {
      alert("The start time must be earlier than the end time");
      return false;
    }

    // replace start, end times
    $("input#start_time").attr('value', start_time);
    $("input#end_time").attr('value', end_time);
    
    // post the appointment confirmation
    $.post($("#add_waitlist_form").attr("action"), $("#add_waitlist_form").serialize(), null, "script");
    // show progress message
    $("div#add_waitlist").replaceWith("<h3 class='submitting' style='text-align: center;'>Adding...</h3>");

    return false;
  })
}

$.fn.init_show_appointment_waitlists = function() {
  $("#show_appointment_waitlist").live('click', function() {
    $.post($(this).attr('url'), {_method:$(this).attr('_method')}, null, "script");
    // show progress message
    $(this).replaceWith("<h5 class='submitting' style='text-align: center;'>Retrieving Waitlist ...</h5>");
    return false;
  })
}

$.fn.init_send_waitlist_message = function() {
  $("#send_message_dialog").dialog({ autoOpen: false, modal: true, height: 250, width: 500 });

  $("#send_waitlist_message").live('click', function() {
    // fill in message address
    var address = $(this).attr('address')
    $("input#message_address").attr('value', address);
    // open dialog when link is clicked
    $("#send_message_dialog").dialog('open');
    return false;
  })
}

$.fn.init_datepicker = function() {
  $(".datepicker").datepicker({minDate: +0, maxDate: '+1m'});
}

$.fn.init_timepicker = function() {
  $(".timepicker").timepickr({convention:12});
}

$(document).ready(function() {
  $(document).init_select_search_waitlist_provider();
  $(document).init_add_waitlist();
  $(document).init_show_appointment_waitlists();
  $(document).init_send_waitlist_message();
  $(document).init_datepicker();
  $(document).init_timepicker();
})
