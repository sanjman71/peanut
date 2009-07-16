$.fn.set_weekly_schedule = function () {
  var s = 'Select one or more days below';
  
  // find selected day names
  var daynames = new Array();
  $('.dayname.mark').each(function() {
    daynames.push($(this).attr("id"));
  })
  
  if (daynames.length > 0) {
    s = daynames.join(", ");
  }
  
  // find slider start time
  if ($("#slider_start").find(".time.mark:first").length) {
    var tstart = $("#slider_start").find(".time.mark:first").attr('id');
    s += " starting at " + tstart;

    // find slider end time
    var tend = $("#slider_end").find(".time.mark:first").attr('id');
    if (tend) { s += " and ending at " + tend; }
  }
  
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
  if ($("#slider_start").find(".time.mark:first").length) {
    var tstart = $("#slider_start").find(".time.mark:first").attr("id") + '00';
    $("#tstart").attr('value', tstart);
  }
  
  if ($("#slider_end").find(".time.mark:first").length) {
    var tend = $("#slider_end").find(".time.mark:first").attr("id") + '00';
    $("#tend").attr('value', tend);
  }

  // write recurrence 'dstart'
  if ($("#schedule_start_date").attr('value')) {
    date   = Date.fromString($("#schedule_start_date").attr('value'));
    dstart = date.asString("yyyymmdd");
    $("#dstart").attr('value', dstart);
  } else {
    // clear out field
    $("#dstart").attr('value', '');
  }

  // write recurrence 'until'
  if ($("#schedule_end_date").attr('value')) {
    date = Date.fromString($("#schedule_end_date").attr('value'));
    dend = date.asString("yyyymmdd");
    $("#until").attr('value', dend);
  } else {
    // clear out field
    $("#until").attr('value', '');
  }
}

$(document).ready(function() {

  // initialize datepicker
  Date.firstDayOfWeek = 7;
  Date.format = 'mm/dd/yyyy';
  $(document).init_datepicker({start_date : (new Date()).addDays(1).asString(), end_date : (new Date()).addMonths(3).asString(), max_days:10});

  // initialize weekly schedule
  $(document).set_weekly_schedule();

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
  
  // show start, end time as they are selected
  $(".slider .time").bind("afterClick", function () {
    $(document).set_weekly_schedule();
    $(document).set_recurrence();
  })

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

  // bind to start and end date selected events
  $('#schedule_end_date').bind(
    'dpClosed',
    function(e, selectedDates)
    {
      // update recurrence
      $(document).set_weekly_schedule();
      $(document).set_recurrence();
    }
  )
  
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

    alert("values passed");
    
    return false;
  })
})