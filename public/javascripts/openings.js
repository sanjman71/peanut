// search schedules for available appointments
$.fn.init_search_openings = function() {
  $("#search_submit").click(function() {
    // validate search inputs
    var service_id = $('#service_id').val();

    if (service_id == "0") {
      // alert the user
      alert("Please select a service");
      return false;
    }
    
    // remove duration change element if its not visible
    //if (!$(".duration .change").is(":visible")) {
      //$(".duration .change").remove();
    //}
    
    // remove when date range if its not visible
    if (!$("#when_date_range_start").is(":visible")) {
      $("#when_date_range_start").remove();
      $("#when_date_range_end").remove();
    } else {
      // check that we have both a start and end date, and the start date is before the end date
      start_date = $("#start_date").attr('value');
      end_date   = $("#end_date").attr('value');
      
      if (!(start_date) || !(end_date)) {
        alert("Please select a start date and end date");
        return false;
      }
      
      if (end_date <= start_date) {
        alert("The start date must be before the end date");
        return false;
      }
    }

    // remove when select list if its not visible
    if (!$("#when_select").is(":visible")) {
      $("#when_select").remove();
    }
    
    // post the search query
    $.post($("#search_openings_form").attr("action"), $("#search_openings_form").serialize(), null, "script");

    // replace the search button with text
    $(this).replaceWith("<h4 class ='submitting'>Searching...</h3>");
    
    return false;
  })
}

// toggle when between a list of predefined values (e.g. 'this week') and fields to enter start and end dates
$.fn.init_search_when_toggle = function() {
  $("#show_when_date_range").click(function() {
    // hide select list
    $("#when_select").hide();
    $("#when_select_cancel").hide();
    // show date range text fields
    $("#when_date_range_start").show();
    $("#when_date_range_end").show();
    $("#when_date_range_cancel").show();
    return false;
  })

  $("#show_when_select").click(function() {
    // show select list
    $("#when_select").show();
    $("#when_select_cancel").show();
    // hide date range text fields
    $("#when_date_range_start").hide();
    $("#when_date_range_end").hide();
    $("#when_date_range_cancel").hide();
    return false;
  })
}

// Note: deprecated
$.fn.init_openings_sliders = function() {
  // show sliders on click
  $(".pick_time").click(function () {
    var $slider = $(this).siblings(".slider");
    
    if ($slider.is(":hidden")) {
      // hide all sliders
      $(".slider").hide();
    
      // show this specific slider
      $(this).siblings(".slider").show();
    } else {
      // hide this slider
      $slider.hide();
    }

    // hide all book it divs
    $(".book_it").hide();
    
    return false;
  })
  
  // bind to the 'afterClick' event, which indicates the user picked a time on the slider
  $(".slider .time").bind("afterClick", function() {
    var book_it   = $(this).parents("div.capacity_slot").find("div.book_it");
    var book_time = $(this).text() + " " + $(this).attr("ampm");
    var book_url  = book_it.find("a.bookit").attr("url").replace(/(\d+T)(\d{4,4})(\d+)/, "$1" + $(this).attr("id") + "$3");
    
    if (!book_it.is(":visible")) {
      // hide all other book it links
      $(".book_it").hide();
      
      // show this book it link
      book_it.show();
    }

    // change book it url and text
    book_it.find("a").attr("href", book_url);
    book_it.find("a").text("Book " + book_time);
  })
}

// Note: not currently used
$.fn.init_openings_show_single_date = function() {
  // set hover states to show selected date, ignore past dates
  $(".weekday.free:not(.past),.weekend.free:not(.past)").hover(
    function() {
      // highlight date
      $(this).addClass('hover');
      
      // hide all appointment dates except this one
      $(".appointments.date").hide();
      $("#appointments_" + $(this).attr("id")).show();
    },
    function() {
      // un-highlight date
      $(this).removeClass('hover');
      // show all dates
      $(".appointments.date").show();
    }
  );
}

$.fn.init_openings_bookit = function() {
  $("a.bookit").click(function() {
    // find selected datetime of this capacity slot
    var slot_id  = $(this).attr('slot_id');
    var datetime = $("div#" + slot_id + " select#slot_times :selected").val();

    // validate datetime
    var datetime_regex = /^[0-9]{8,8}T[0-9]{6,6}$/;
    if (datetime_regex.test(datetime) == false) {
      alert("Please select a time");
      return false;
    }

    // build url using datetime
    var url = $(this).attr('url').replace(/datetime/, datetime);
    $(this).attr('href', url);
    return true;
  })
}

$.fn.init_openings_add_calendar_markings = function() {
  // find capacity slots by date, and mark calendar based on these slots
  $("div#free_capacity_slots div.slots.date").each(function () {
    // count the number of available time slots for this date
    var time_slot_count = 0;
    $(this).find("div.provider.slot").each(function() {
      time_slot_count += parseInt($(this).attr('count'));
    })

    if (time_slot_count > 0) {
      // extract calendar date and mark the calendar
      re    = /slots_(\d+)/
      match = $(this).attr('id').match(re);
      date  = match[1];
      // mark as free
      $("div#free_calendar td#" + date).addClass('free');
      // add 'available' text
      $("div#free_calendar td#" + date).find("#available").text('Available');
    }
  })

  // set hover states to show selected date, ignore past dates
  $("td.weekday.free:not(.past),td.weekend.free:not(.past)").click(function() {
    $("div#free_capacity_slots").show();
    // unmark all selected calendar dates, and mark this calendar date as selected
    $(".free.selected").removeClass('selected');
    $(this).addClass('selected');
    // hide all capacity slots, and show this one
    var slot_id = "#slots_" + $(this).attr("id");
    $(".slots.date").hide();
    $(slot_id).show();
  })

  // mark the first available date, if there is one
  var first_date = $("td.free:not(.past):first")
  if (first_date) {
    $(first_date).click();
  }
}

$.fn.init_datepicker_openings = function() {
  $(".datepicker").datepicker({minDate: +0, maxDate: '+2m'});
}

$(document).ready(function() {
  $(document).init_search_openings();
  $(document).init_search_when_toggle();
  $(document).init_openings_add_calendar_markings();
  $(document).init_datepicker_openings();
  $(document).init_openings_bookit();
  // rounded corners
  $('#search_submit').corners("7px");
})
