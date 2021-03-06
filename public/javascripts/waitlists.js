// search waitlist for the selected provider
$.fn.init_select_search_waitlist_provider = function () {
  $("#search_provider").change(function () {
    var href = '/' + this.value + '/waitlist';
    window.location = href;
    return false;
  })
}

$.fn.init_add_waitlist = function() {
  $("form#add_waitlist_form").submit(function () {
    // validate customer signup
    var customer_id = $("input#waitlist_customer_id").attr('value');
    
    if (!customer_id) {
      alert("Please login to continue");
      return false;
    }

    // check dates and teims
    var start_date  = $('input#waitlist_start_date').val();
    var end_date    = $('input#waitlist_end_date').val();
    var start_time  = $('input#waitlist_start_time').val();
    var end_time    = $('input#waitlist_end_time').val();

    if (!start_date) {
      alert("Please enter a waitlist start date");
      return false;
    }
    
    if (!end_date) {
      alert("Please enter a waitlist end date");
      return false;
    }

    if (end_date < start_date) {
      alert("The start date must be before the end date");
      return false;
    }
    
    if (!start_time) {
      alert("Please enter a waitlist start time");
      return false;
    }

    if (!end_time) {
      alert("Please enter a waitlist end time");
      return false;
    }

    // normalize start, end times
    start_time = convert_time_ampm_to_string(start_time)
    end_time   = convert_time_ampm_to_string(end_time)

    if (!(start_time <= end_time)) {
      alert("The start time must be earlier than the end time");
      return false;
    }

    // set formatted start, end times, disable input times
    $("input#waitlist_start_time_formatted").attr('value', start_time);
    $("input#waitlist_start_time").attr('disabled', 'disabled');
    $("input#waitlist_end_time_formatted").attr('value', end_time);
    $("input#waitlist_end_time").attr('disabled', 'disabled');

    // normalize start, end dates, e.g. '10/2/2010' to '20101002'
    start_date = convert_date_to_string(start_date);
    end_date   = convert_date_to_string(end_date);

    // set formatted start, end dates, disable input dates
    $("input#waitlist_start_date_formatted").attr('value', start_date);
    $("input#waitlist_start_date").attr('disabled', 'disabled');
    $("input#waitlist_end_date_formatted").attr('value', end_date);
    $("input#waitlist_end_date").attr('disabled', 'disabled');

    // serialize form
    data = $(this).serialize();
    //alert("form serialize: " + data);
    //return false;

    // post the appointment confirmation
    $.post(this.action, data, null, "script");
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

/*
$.fn.init_send_waitlist_message = function() {
  $("#send_message_dialog").dialog({ autoOpen: false, modal: true, height: 220, width: 500, show: 'fadeIn(slow)' });

  $("#send_waitlist_message").live('click', function() {
    // fill in message address
    var address = $(this).attr('address')
    $("input#message_address").attr('value', address);
    // open dialog when link is clicked
    $("#send_message_dialog").dialog('open');
    return false;
  })
}
*/

$.fn.init_waitlist_dialog = function() {
  // initialize add free time dialog
  $("div#add_waitlist_dialog").dialog({ modal: true, autoOpen: false, width: 750, height: 325, show: 'fadeIn(slow)', title: $("div#add_waitlist_dialog").attr('title') });

  // open dialog when 'add waitlist' link is clicked
  $("a#add_waitlist").click(function() {
    // check add waitlist form
    var add_waitlist_form = $("form#add_waitlist_form").size();

    if (add_waitlist_form == 0) {
      // open user login dialog
      $(document).open_user_login_dialog();
    } else {
      // clear date, time fields
      $("form#add_waitlist_form input#waitlist_start_date").val('');
      $("form#add_waitlist_form input#waitlist_end_date").val('');
      $("form#add_waitlist_form input#waitlist_start_time").val('');
      $("form#add_waitlist_form input#waitlist_end_time").val('');
      // open add waitlist dialog
      $("div.dialog#add_waitlist_dialog").dialog('open');
    }
    return false;
  })
}

$.fn.init_waitlist_datepicker = function() {
  $(".waitlist.datepicker").datepicker({minDate: +0, maxDate: '+1m'});
}

$.fn.init_waitlist_timepicker = function() {
  $(".waitlist.timepicker").timepickr({convention:12});
}

$(document).ready(function() {
  $(document).init_waitlist_datepicker();
  $(document).init_waitlist_timepicker();
  $(document).init_show_appointment_waitlists();
  $(document).init_waitlist_dialog();
  $(document).init_add_waitlist();
  $(document).init_select_search_waitlist_provider();
  //$(document).init_send_waitlist_message();
})
