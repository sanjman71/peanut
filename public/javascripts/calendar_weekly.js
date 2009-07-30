$.fn.set_weekly_schedule = function () {
  var s = 'Select one or more days below';
  
  // find selected day names
  var daynames = new Array();
  $('.dayname.mark').each(function() {
    daynames.push($(this).attr("id"));
  })

  if (daynames.length == 0) {
    // pick a day before a weekly schedule can be set
    $("#weekly_schedule").text(s);
    return;
  }
  
  s = daynames.join(", ");

  // find start time
  if ($("#starts_at").attr('value')) {
    s += " starting at " + $("#starts_at").attr('value');

    // check end time
    var tend = $("#ends_at").attr('value');
    if (tend) { s += " and ending at " + tend; }
  }

  // find slider start time
/*  if ($("#slider_start").find(".time.mark:first").length) {
    var tstart = $("#slider_start").find(".time.mark:first").attr('id');
    s += " starting at " + tstart;

    // find slider end time
    var tend = $("#slider_end").find(".time.mark:first").attr('id');
    if (tend) { s += " and ending at " + tend; }
  }
*/  
  $("#weekly_schedule").text(s);
}

$.fn.set_recurrence = function () {
  // find selected day names
  var daynames = new Array();
  $('.dayname.mark').each(function() {
    daynames.push($(this).attr("byday"));
  })
  
  // write recurrence 'byday'
  if (daynames.length > 0) {
    s = daynames.join(",");
    $("#byday").attr('value', s);
  }
  
  // write recurrence 'tstart' and 'tend', append '00' for seconds
  if ($("#starts_at").attr('value')) {
    // format 'start_at' field for 'dstart'
    s = $(document).convert_time_ampm_to_string($("#starts_at").attr('value'));
    $("#tstart").attr('value', s);
  }

  if ($("#ends_at").attr('value')) {
    // format 'start_at' field for 'dstart'
    s = $(document).convert_time_ampm_to_string($("#ends_at").attr('value'));
    $("#tend").attr('value', s);
  }
  
  // write recurrence 'dstart'
  if ($("#schedule_start_date").attr('value')) {
    s = $(document).convert_date_to_string($("#schedule_start_date").attr('value'));
    $("#dstart").attr('value', s);
  } else {
    // clear out field
    $("#dstart").attr('value', '');
  }

  // write recurrence 'until'
  if ($("#schedule_end_date").attr('value')) {
    s = $(document).convert_date_to_string($("#schedule_end_date").attr('value'));
    $("#until").attr('value', s);
  } else {
    // clear out field
    $("#until").attr('value', '');
  }
}

$.fn.init_daynames = function () {
  // set hover states to show selected day name
  $(".dayname").hover(
    function() {
      // highlight day name
      $(this).addClass('hover');
    },
    function() {
      $(this).removeClass('hover');
    }
  );

  // toggle day names as they are selected
  $(".dayname").click(function () {
    $(this).toggleClass('mark');
    $(document).set_weekly_schedule();
    $(document).set_recurrence();
  });
}

$.fn.init_schedule_range = function () {
  $("#schedule_end_until").click(function () {
    // show date field
    $("#schedule_end_date").show();
  })

  $("#schedule_end_never").click(function () {
    // hide date field
    $("#schedule_end_date").hide();
    // clear date field
    $("#schedule_end_date").attr("value", '');
    // update recurrence using end date
    $(document).set_weekly_schedule();
    $(document).set_recurrence();
  })
}

$.fn.init_datepicker = function () {
  $(".datepicker").datepicker({
      minDate: +0, 
      maxDate: '+3m',
      onClose: function(dateText, instance) {
        $(document).set_weekly_schedule();
        $(document).set_recurrence();
      }
    });
}

$.fn.init_timepicker = function() {
  $(".timepicker").timepickr({
      convention:12, 
      select: function() { 
        $(document).set_weekly_schedule();
        $(document).set_recurrence();
      }
    });
}

$.fn.init_schedule_form = function () {
  // submit weekly schedule
  $("#add_weekly_schedule_form").submit(function () {
    // validate presence of byday, tstart, tend, schedule_start_date
    if (!$("#byday").attr('value')) {
      alert("Please select 1 or more days");
      return false
    }

    if (!$("#tstart").attr('value')) {
      alert("Please specify a start time");
      return false
    }

    if (!$("#tend").attr('value')) {
      alert("Please specify an end time");
      return false
    }

    if (!$("#schedule_start_date").attr('value')) {
      alert("Please specify a start date");
      return false
    }

    return true;
  })
}

// convert mm/dd/yyyy date to yyyymmdd string
$.fn.convert_date_to_string = function(s) {
  re    = /(\d{2,2})\/(\d{2,2})\/(\d{4,4})/
  match = s.match(re);
  if (!match) {
    s = ''
  } else {
    s = match[3] + match[1] + match[2]
  }
  return s
}

// convert '03:00 pm' time format to 'hhmmss' 24 hour time format
$.fn.convert_time_ampm_to_string = function(s) {
  re      = /(\d{2,2}):(\d{2,2}) (am|pm)/
  match   = s.match(re);

  // convert hour to integer, leave minute as string
  hour    = parseInt(match[1], 10); 
  minute  = match[2];

  if (match[3] == 'pm') {
    // add 12 for pm
    hour += 12;
  }

  value = hour < 10 ? "0" + hour.toString() : hour.toString()
  value += minute + "00";
  return value
}

$(document).ready(function() {

  $(document).init_daynames();
  $(document).init_schedule_range();
  $(document).init_datepicker();
  $(document).init_timepicker();
  $(document).init_schedule_form();

  // initialize weekly schedule
  $(document).set_weekly_schedule();
})