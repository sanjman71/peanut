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

  $("#weekly_schedule").text("Schedule: " + s);
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
    s = convert_time_ampm_to_string($("#starts_at").attr('value'));
    $("#tstart").attr('value', s);
  }

  if ($("#ends_at").attr('value')) {
    // format 'start_at' field for 'dstart'
    s = convert_time_ampm_to_string($("#ends_at").attr('value'));
    $("#tend").attr('value', s);
  }
  
  // write recurrence 'dstart'
  if ($("#start_date").attr('value')) {
    s = convert_date_to_string($("#start_date").attr('value'));
    $("#dstart").attr('value', s);
  } else {
    // clear out field
    $("#dstart").attr('value', '');
  }

  // write recurrence 'dend'
  // If it's set, we use the value. If not, we use the start date
  if ($("#end_date").attr('value')) {
    s = convert_date_to_string($("#end_date").attr('value'));
    $("#dend").attr('value', s);
  } else if ($("#start_date").attr('value')) {
    s = convert_date_to_string($("#start_date").attr('value'));
    $("#dend").attr('value', s);
  } else {
    // clear out field
    $("#dend").attr('value', '');
  }

  // write recurrence 'until'
  if ($("#schedule_end_date").attr('value')) {
    s = convert_date_to_string($("#schedule_end_date").attr('value'));
    $("#until").attr('value', s);
  } else {
    // clear out field
    $("#until").attr('value', '');
  }

  // write capacity
  if ($("#capacity").attr('value')) {
    s = convert_date_to_string($("#capacity").attr('value'));
    $("#capacity").attr('value', s);
  } else {
    // set field to default
    $("#capacity").attr('value', '1');
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
    // validate presence of byday, tstart, tend, start_date
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

    if (!$("#start_date").attr('value')) {
      alert("Please specify a start date");
      return false
    }

    // Make sure the end date/time is later than the start date/time
    // With the dates and times in the right format we can use string compares
    sd = convert_date_to_string($("#start_date").attr('value'));
    ed = convert_date_to_string($("#end_date").attr('value'));
    st = convert_time_ampm_to_string($("#starts_at").attr('value'));
    et = convert_time_ampm_to_string($("#ends_at").attr('value'));    
    
    // If the end date is earlier than the start date
    if (ed < sd) {
      alert("The end date is earlier than the start date");
      return false
    } else if ((ed == sd) && (et < st)) {
      // If it ends on the same date as it starts, but the end time is earlier
      alert("The end time is earlier than the start time");
      return false
    }
    return true;
  })
}

// edit calendar for the selected provider
$.fn.init_select_calendar_edit_weekly_provider = function () {
  $("#edit_provider").change(function () {
    var href = '/' + this.value + '/calendar/weekly/edit';
    window.location = href;
    return false;
  })
}

$(document).ready(function() {
  $(document).init_daynames();
  $(document).init_schedule_range();
  $(document).init_datepicker();
  $(document).init_timepicker();
  $(document).init_schedule_form();
  $(document).init_select_calendar_edit_weekly_provider();
  
  // initialize weekly schedule
  $(document).set_weekly_schedule();
})