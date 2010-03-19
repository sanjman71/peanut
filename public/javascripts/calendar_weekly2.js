// change calendar based on the selected provider
$.fn.init_select_calendar_weekly_provider = function() {
  $("#edit_provider").change(function() {
    var href = '/' + this.value + '/calendar/weekly/edit';
    window.location = href;
    return false;
  })

  $("#show_provider").change(function() {
    var href = '/' + this.value + '/calendar/weekly';
    window.location = href;
    return false;
  })
}

$.fn.init_add_recurrence = function() {
  $("a#add_recurrence").click(function() {
    var add_div   = $(this).closest("div.day").nextAll("div#add:first");
    var time_slot = $("div.time_slot.hide#add").clone().removeClass('hide').appendTo(add_div);
    // add class 'datepicker' so it can be properly initialized
    $(time_slot).find("input#datepicker").addClass('datepicker');
    // set datepicker initial date; find date by mapping wday to a date
    var wday = $(add_div).attr('wday');
    var date = wday_to_date.get(wday);
    $(time_slot).find("input#datepicker").val(date);
    // add unique id, its a requirement of the jquery library when there are more than 1 on a page
    $(time_slot).find("input#datepicker").attr('id', "datepicker_" + Math.floor(Math.random()*101));
    init_timepicker_weekly();
    init_datepicker_weekly();
    hide_manage_links();
    return false;
  })
  
  $("a#add_recurrence_cancel").live('click', function() {
    $(this).closest("div#add").remove();
    show_manage_links();
    return false;
  })
  
  $("a#add_recurrence_save").live('click', function() {
    var recur_rules = new Array();
    var errors      = 0;
    var time_slots  = 0;

    $("div.time_slot#add:not(.hide)").each(function() {
      var $start_date = $(this).find("input.datepicker");
      var dstart      = convert_date_to_string($start_date.val());
      var $starts_at  = $(this).find("input#starts_at");
      var $ends_at    = $(this).find("input#ends_at");
      var tstart      = convert_time_ampm_to_string($starts_at.val());
      var tend        = convert_time_ampm_to_string($ends_at.val());    
      
      // check start date
      if (dstart == '') {
        $start_date.addClass('highlight');
        errors += 1;
        alert("Please enter a start date");
        return;
      } else {
        $start_date.removeClass('highlight');
      }

      // check start and end times
      if (tstart == '') {
        $starts_at.addClass('highlight');
        errors += 1;
        alert("Please enter a start time");
        return;
      } else if (tend == '') {
        $ends_at.addClass('highlight');
        errors += 1;
        alert("Please enter an end time");
        return;
      } else if (tend < tstart) {
        $starts_at.addClass('highlight');
        $ends_at.addClass('highlight');
        errors += 1;
        alert("The end time is earlier than the start time");
        return;
      } else {
        $starts_at.removeClass('highlight');
        $ends_at.removeClass('highlight');
      }

      // build recur rule
      var byday = $(this).parent().attr('byday');
      var rule  = "freq=weekly;byday=" + byday + ";dstart=" + dstart + ";tstart=" + tstart + ";tend=" + tend;
      recur_rules.push(rule);
      // increment timeslots
      time_slots += 1;
    })

    if (errors > 0) { return false; }
    if (time_slots == 0) { return false; }

    // set form values and submit
    var form  = "form#add_weekly_schedule_form"
    $(form).find("input#rules").val(recur_rules.join('|'));
    var url   = $(form).attr('action');
    var data  = $(form).serialize();
    $.post(url, data, null, "script");
  
    // show progress
    $(this).closest("#actions").replaceWith("<img src='/images/bounce.gif'>");

    return false;
  })
}

$.fn.init_edit_recurrence = function() {
  $("a#edit_recurrence").click(function() {
    $(this).closest("div.recurrence").find("div#edit").show();
    $(this).closest("div.recurrence").find("div#show").hide();
    init_timepicker_weekly();
    hide_manage_links();
    return false;
  })
  
  $("a#edit_recurrence_cancel").live('click', function() {
    $(this).closest("div.recurrence").find("div#show").show();
    $(this).closest("div.recurrence").find("div#edit").hide();
    show_manage_links();
    return false;
  })

  $("a#edit_recurrence_save").live('click', function() {
    var starts_at = $(this).closest("#actions").siblings("input#starts_at:first").val();
    var ends_at   = $(this).closest("#actions").siblings("input#ends_at:first").val();
    var tstart    = convert_time_ampm_to_string(starts_at);
    var tend      = convert_time_ampm_to_string(ends_at);
    
    // check start and end times
    if (tstart == '') {
      alert("Please enter a start time");
      return false;
    } else if (tend == '') {
      alert("Please enter an end time");
      return false;
    } else if (tend < tstart) {
      alert("The end time is earlier than the start time");
      return false;
    }

    // find recurrence id
    var id      = $(this).closest(".appointment.recurrence").attr('id').match(/\w_(\d+)/)[1]

    // build recur rule
    var recur   = $(this).closest("#edit").siblings("#show").attr('recur_rule');
    var dstart  = $(this).closest("#edit").siblings("#show").attr('dstart');
    var rule    = recur + ";dstart=" + dstart + ";tstart=" + tstart + ";tend=" + tend;
    
    // set form values and submit
    var form  = "form#update_weekly_schedule_form"
    $(form).find("input#rules").val(rule);
    var url   = $(form).attr('action').replace(/:id/, id);
    var data  = $(form).serialize();
    $.put(url, data, null, "script");

    // show progress
    $(this).closest("#actions").replaceWith("<img src='/images/bounce.gif'>");

    return false;
  })
}

function show_manage_links() {
  // show all manage links
  $("a.manage").removeClass('hide');
}

function hide_manage_links() {
  // hide all manage links
  $("a.manage").addClass('hide');
}

/*
function toggle_add_recurrence_save_button() {
  // show save button if we ahve at least 1 new time slot
  if ($("div.time_slot#add").length > 1) {
    $("input#add_recurrence_save").removeAttr('disabled');
  } else {
    $("input#add_recurrence_save").attr('disabled', 'disabled');
  }
}
*/

/*
function set_time_slot_count(day) {
  var time_slot_count = $(day).find("div#time_slot").length;
  var time_slot_text  = "Not available";
  if (time_slot_count == 1) {
    time_slot_text = "1 Time Slot";
  } else if (time_slot_count > 1) {
    time_slot_text = time_slot_count + " Time Slots";
  }
  $(day).find("#time_slot_count").text(time_slot_text);
}
*/

function init_timepicker_weekly() {
  $(".timepicker").timepickr({convention:12});
}

function init_datepicker_weekly() {
  $(".datepicker").datepicker({minDate: '+0d', maxDate: '+3m'});
}

/*
$.fn.init_datepicker_weekly = function () {
  $(".datepicker").datepicker({minDate: '+0d', maxDate: '+3m'});
}
*/

/*
$.fn.init_weekly_time_slots = function() {
  $("a#add_time_slot").live('click', function() {
    var day_block = $(this).closest("div.day").find("div#day_time_slots");
    $("div#hidden_time_slot div#time_slot").clone().appendTo(day_block);
    // update time slot count
    set_time_slot_count($(this).closest("div.day"));
    // init timepicker
    init_timepicker_weekly();
    return false;
  })

  $("a#remove_time_slot").live('click', function() {
    var day_block = $(this).closest("div.day").find("div#day_time_slots");
    $(this).closest("div#time_slot").remove();
    // update time slot count
    set_time_slot_count(day_block);
    return false;
  })
}
*/

/*
$.fn.init_weekly_schedule_form = function () {
  // submit weekly schedule
  $("form#add_weekly_schedule_form").submit(function() {
    var recur_rules = new Array();
    var time_slots  = 0;
    var errors      = 0;

    $("div.day").each(function() {
      // check each day's time slots
      $(this).find("div#time_slot").each(function() {
        var starts_at   = $(this).find("#starts_at");
        var ends_at     = $(this).find("#ends_at");
        var start_time  = convert_time_ampm_to_string(starts_at.attr('value'));
        var end_time    = convert_time_ampm_to_string(ends_at.attr('value'));    

        if ((start_time == '') || (end_time == '')) { return; }

        time_slots      += 1;

        // end date must be after the start date
        if (end_time < start_time) {
          starts_at.addClass('highlight');
          ends_at.addClass('highlight');
          errors += 1;
          alert("The end time is earlier than the start time");
          return;
        } else {
          starts_at.removeClass('highlight');
          ends_at.removeClass('highlight');
        }

        // build recurrence rule
        var byday   = $(this).closest("div.day").attr('byday')
        var dinput  = $(this).closest("div.day").find('input.datepicker');
        var dstart  = convert_date_to_string(dinput.val());

        // check start date for the day of week
        if (dstart == '') {
          dinput.addClass('highlight');
          errors += 1;
          alert("Please enter a start date");
        } else {
          dinput.removeClass('highlight');
        }

        var rule = "freq=weekly;byday=" + byday + ";dstart=" + dstart + ";tstart=" + start_time + ";tend=" + end_time;
        recur_rules.push(rule);
      })
    })

    if (time_slots == 0) {
      alert("Please add at least 1 time slot");
      return false;
    }

    // set rules field
    $(this).find("input#rules").val(recur_rules.join('|'));

    // show progress
    $(this).find("#submit").hide().parent().find("#progress").show();

    return true;
  })
}
*/

/*
$.fn.check_recurrence = function () {
  // check if we have a recurrence being edited
  if (recurrence.get("id") != undefined) {
    // set appointment id
    //$("div.day").attr("recurrence_id", recurrence.get("id"));
    // add time slot
    $("div.day a#add_time_slot").click();
    // fill in start, end time
    $("div.day div#time_slot input#starts_at").val(recurrence.get("starts_at_ampm"));
    $("div.day div#time_slot input#ends_at").val(recurrence.get("ends_at_ampm"));
  }
}
*/

$(document).ready(function() {
  $(document).init_select_calendar_weekly_provider();
  $(document).init_add_recurrence();
  $(document).init_edit_recurrence();
  //$(document).init_weekly_time_slots();
  //$(document).init_weekly_schedule_form();
  //$(document).init_datepicker_weekly();
  //$(document).check_recurrence();
})