// add appointment for a provider on a specific day
$.fn.init_add_appointment = function() {
  $("#add_appointment_form").submit(function () {
    // Provider is built into the form when it's generated - the end user doesn't provide this information.
    var service_id      = $("#add_appointment_form select#service_id").attr('value');
    var customer_id     = $("#add_appointment_form input#customer_id").attr('value');
    var apt_start_date  = $("#add_appointment_form input#apt_start_date").attr('value');
    var apt_start_time  = $("#add_appointment_form input#apt_start_time").attr('value');
    var errors    = 0;
    
    if (!apt_start_date) {
      $("#add_appointment_form input#apt_start_date").addClass('highlighted');
      alert("Please select a date");
      return false; 
    } else {
      $("#add_appointment_form input#apt_start_date").removeClass('highlighted');
    }
    
    if (!apt_start_time) {
      $("#add_appointment_form input#apt_start_time").addClass('highlighted');
      alert("Please select a start time");
      return false; 
    } else {
      $("#add_appointment_form input#apt_start_time").removeClass('highlighted');
    }

    if (!customer_id) {
      $("#add_appointment_form input#customer_name").addClass('highlighted');
      alert("Please select a customer");
      return false; 
    } else {
      $("#add_appointment_form input#customer_name").removeClass('highlighted');
    }

    if (!service_id) {
      $("#add_appointment_form select#service_id").addClass('highlighted');
      alert("Please select a service");
      return false; 
    } else {
      $("#add_appointment_form select#service_id").removeClass('highlighted');
    }

    // We have all the required fields

    // normalize time format, validate that start_at < end_at
    var apt_start_time = convert_time_ampm_to_string(apt_start_time)

    // normalize date format
    var apt_start_date = convert_date_to_string(apt_start_date);

    // replace hidden tag formatted version
    $("#add_appointment_form input#start_at").attr('value', apt_start_date + 'T' + apt_start_time);

    // post
    $.post(this.action, $(this).serialize(), null, "script");
    $(this).find('input[type="submit"]').replaceWith("<h3 class ='submitting'>Adding...</h3>");
    return false;
  })
}

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

$.fn.init_add_calendar_markings = function() {
  // find capacity slots by date, and mark calendar based on these slots
  $("div#calendar_by_day div.calendar_schedule_date").each(function () {
    // extract calendar date
    re    = /date_(\d+)/
    match = $(this).attr('id').match(re);
    date  = match[1];

    // count capacity slots for this date
    var capacity_slots = 0;
    $(this).find("div.capacity_and_work div.capacity_slot").each(function() {
      capacity_slots += 1;
    })

    // count work appointments for this date
    var work_appointments = 0;
    $(this).find("div.capacity_and_work div.appointment.work").each(function() {
      work_appointments += 1;
    })

    var text = [];

    // mark the calendar
    if (capacity_slots > 0) {
      // mark as free
      $("div#free_work_calendar td#" + date).addClass('free');
      // add text
      text.push('Free');
    }

    if (work_appointments > 0) {
      // mark as work
      //$("div#free_work_calendar td#" + date).addClass('work');
      // add text
      text.push('Work');
    }

    // mark text
    $("div#free_work_calendar td#" + date).find("span#available").text(text.join(", "));
  })

  // add click handler to show selected free date, allow past dates
  $(".weekday.free,.weekend.free").click(function() {
    $("div#calendar_by_day").show();
    // unmark all selected calendar dates, and mark this calendar date as selected
    $(".free.selected").removeClass('selected');
    $(this).addClass('selected');
    // hide all date, and show this one
    var date_id = "div#date_" + $(this).attr("id");
    $(".calendar_schedule_date").hide();
    $(date_id).show();
  })
}

$.fn.init_schedule_datepicker = function() {
  $(".datepicker").datepicker({minDate: 0, maxDate: '+3m'});
}

$.fn.init_schedule_timepicker = function() {
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

$.fn.init_autocomplete_customers = function() {
  // Set up the autocomplete
  // Setup help for the JSON solution from here: http://blog.schuager.com/2008/09/jquery-autocomplete-json-apsnet-mvc.html
  // and here: http://www.it-eye.nl/weblog/2008/08/23/using-jquery-autocomplete-with-grails-and-json/
  // This will dynamically invoke the index function on the customers controller, asking for JSON data
  // The parse option is used to parse the JSON result into rows, each containing all the data for the row, the value displayed and the formatted value
  // The formatItem option is also used to format the rows displayed in the pulldown
  $("#customer_name").autocomplete($("#customer_name").attr("url"),
                                          {
                                            dataType:'json',
                                            parse: function(data) {
                                                      var rows = new Array();
                                                      for(var i=0; i<data.length; i++){
                                                          rows[i] = { data:data[i], value:data[i].user.name, result:data[i].user.name };
                                                      }
                                                      return rows;
                                                  },
                                            formatItem: function(data,i,max,value,term) { return value; },
                                            autoFill: false
                                          });
  
  $("#customer_name").result(function(event, data, formatted) {
    // set the customer id
    $("#customer_id").attr("value", data.user.id);
  });

}

$(document).ready(function() {
  $(document).init_schedule_datepicker();
  $(document).init_schedule_timepicker();
  $(document).init_search_calendar_with_date_range();
  $(document).init_add_single_free_time();
  $(document).init_add_appointment();
  $(document).init_select_calendar_show_provider();
  $(document).init_show_appointment_on_hover();
  $(document).init_add_calendar_markings();
  $(document).init_send_pdf();
  $(document).init_autocomplete_customers();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_select_calendar_show_provider();
})
