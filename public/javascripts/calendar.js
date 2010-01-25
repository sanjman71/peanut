// add appointment for a provider on a specific day
$.fn.init_add_appointment = function() {

  // initialize add appointment dialog
  $("div.dialog#add_appointment_dialog").dialog({ modal: true, autoOpen: false, hide: 'slide', width: 625, height: 325, show: 'fadeIn(slow)', title: $("div.dialog#add_appointment_dialog").attr('title') });

  // open add appointment dialog on click
  $("a#calendar_add_appointment").click(function() {
    // set dialog date field
    var normalized_date = $(this).parents("td").attr('id');
    var calendar_date   = convert_string_to_date(normalized_date)
    $("form#add_appointment_form input#apt_start_date").val(calendar_date);
    // clear start_at, customer fields
    $("form#add_appointment_form input#apt_start_time").val('');
    $("form#add_appointment_form input#customer_name").val('');
    $("form#add_appointment_form input#customer_id").val('');
    // open dialog
    $("div.dialog#add_appointment_dialog").dialog('open');
    return false;
  })

  $("a#calendar_add_customer").click(function() {
    // close this dialog
    $("div.dialog#add_appointment_dialog").dialog('close');
    // show add user dialog, set return dialog link, disable escape
    $("div.dialog#add_user_dialog a#add_user_return_dialog").attr('dialog', "div.dialog#add_appointment_dialog");
    $("div.dialog#add_user_dialog").dialog('option', 'closeOnEscape', false);
    $("div.dialog#add_user_dialog").dialog('open');
    return false;
  })
  
  $("form#add_appointment_form").submit(function () {
    // Provider is built into the form when it's generated - the end user doesn't provide this information.
    var service_id      = $("form#add_appointment_form select#service_id").val();
    var customer_id     = $("form#add_appointment_form input#customer_id").val();
    var apt_start_date  = $("form#add_appointment_form input#apt_start_date").val();
    var apt_start_time  = $("form#add_appointment_form input#apt_start_time").val();
    
    if (!apt_start_date) {
      alert("Please select a date");
      return false; 
    }
    
    if (!service_id) {
      alert("Please select a service");
      return false; 
    }

    if (!apt_start_time) {
      alert("Please select a start time");
      return false; 
    }

    if (!customer_id) {
      alert("Please select a customer");
      return false; 
    }

    // normalize time format
    var apt_start_time = convert_time_ampm_to_string(apt_start_time)

    // normalize date format
    var apt_start_date = convert_date_to_string(apt_start_date);

    // replace hidden tag formatted version
    $("form#add_appointment_form input#start_at").attr('value', apt_start_date + 'T' + apt_start_time);

    // disable apt_start_time field
    $("form#add_appointment_form input#apt_start_time").attr('disabled', 'disabled');

    // serialize form
    data = $(this).serialize();
    //alert("form serialize: " + data);
    //return false;

    // enable apt_start_time field
    $("form#add_appointment_form input#apt_start_time").removeAttr('disabled');

    // post
    $.post(this.action, data, null, "script");
    $(this).find('input[type="submit"]').replaceWith("<h3 class ='submitting'>Adding...</h3>");
    return false;
  })
}

// add free time for a provider on a specific day
$.fn.init_add_single_free_time = function() {
  
  // initialize add free time dialog
  $("div#add_free_time_dialog").dialog({ modal: true, autoOpen: false, hide: 'slide', width: 575, height: 250, show: 'fadeIn(slow)', title: $("div#add_free_time_dialog").attr('title') });
  
  // open add free time dialog on click
  $("a#calendar_add_free_time").click(function() {
    // set dialog date fields
    var normalized_date = $(this).parents("td").attr('id');
    var calendar_date   = convert_string_to_date(normalized_date)
    $("form#add_single_free_time_form input#date").attr('value', normalized_date);
    $("form#add_single_free_time_form div#free_date input#free_date").val(calendar_date);
    // clear start_at, end_at time fields
    $("form#add_single_free_time_form div#free_start_at_text input#free_start_at").val('');
    $("form#add_single_free_time_form div#free_end_at_text input#free_end_at").val('');
    // open dialog
    $("div#add_free_time_dialog").dialog('open');
    return false;
  })

  $("form#add_single_free_time_form").submit(function () {
    var when      = $("input#date").attr('value'); // use hidden field date
    var start_at  = $("input#free_start_at").attr('value');
    var end_at    = $("input#free_end_at").attr('value');

    if (!when) {
      alert("Please select a date");
      return false; 
    }

    if (!start_at) {
      alert("Please select a start time");
      return false; 
    }

    if (!end_at) {
      alert("Please select an end time");
      return false; 
    }

    // normalize time format, validate that start_at < end_at
    var start_at = convert_time_ampm_to_string(start_at)
    var end_at   = convert_time_ampm_to_string(end_at)

    if (!(start_at < end_at)) {
      alert("The start time must be earlier than the end time");
      return false;
    }

    // set hidden start_at, end_at  fields with normalized values
    $("input#start_at[type='hidden']").attr('value', start_at);
    $("input#end_at[type='hidden']").attr('value', end_at);
    
    // disable start_at, end_at fields
    $("input#free_start_at").attr('disabled', 'disabled');
    $("input#free_end_at").attr('disabled', 'disabled');

    // serialize form
    data = $(this).serialize();
    //alert("form serialize: " + data);
    //return false;

    // enable start_at, end_at fields
    $("input#free_start_at").removeAttr('disabled');
    $("input#free_end_at").removeAttr('disabled');

    // post
    $.post(this.action, data, null, "script");
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
    $(this).find("div.free_appointment div.capacity_and_work div.capacity_slot").each(function() {
      capacity_slots += 1;
    })

    $(this).find("div.capacity_slot").each(function() {
      capacity_slots += 1;
    })

    // count capacity slot 2 divs, but not those that indicate overbooked - only those that are free
    $(this).find("div.capacity_slot2.free").each(function() {
      capacity_slots += 1;
    })

    // count work appointments for this date; there are multiple ways to count work appointments
    var work_appointments = 0;

    $(this).find("div.free_appointment div.capacity_and_work div.appointment.work").each(function() {
      work_appointments += 1;
    })

    $(this).find("div.appointment.work").each(function() {
      work_appointments += 1;
    })

    var text = [];

    // mark the calendar
    if (capacity_slots > 0) {
      // mark as free, add text
      $("div#free_work_calendar td#" + date).addClass('free');
      text.push('Free');
    }

    if (work_appointments > 0) {
      // mark as work, add text
      $("div#free_work_calendar td#" + date).addClass('work');
      text.push('Work');
    }

    // mark text
    $("div#free_work_calendar td#" + date).find("#available").text(text.join(", "));
  })

  // add click handler to show selected free, work dates; allow past dates
  $("td.weekday.free,td.weekday.work,td.weekend.free,td.weekend.work").click(function() {
    $("div#calendar_by_day").show();
    // unmark all selected calendar dates, and mark this calendar date as selected
    $(".free.selected,.work.selected").removeClass('selected');
    $(this).addClass('selected');
    // hide all dates, and show this date
    $(".calendar_schedule_date").hide();
    var date_id = "div#date_" + $(this).attr("id");
    $(date_id).show();
  })

  // show add menu icon on calendar date hover
  $("td:not(.past) .date").hover(function () {
    $(this).find("span#calendar_add_menu").css('visibility', 'visible');
    }, function () {
    $(this).find("span#calendar_add_menu").css('visibility', 'hidden');
    // hide add menu links
    $(this).find("ul#calendar_add_menu_links").hide();
  })

  // show add menu links on click
  $("a#calendar_add_menu").click(function() {
    $(this).next("ul#calendar_add_menu_links").show(300);
    return false;
  })
}

$.fn.init_cancel_appointment = function() {
  // initialize cancel appointment dialog
  $("div.dialog#cancel_appointment_dialog").dialog({ modal: true, autoOpen: false, hide: 'slide', width: 575, height: 250, show: 'fadeIn(slow)',
                                                     title: $("div.dialog#cancel_appointment_dialog").attr('title') });

  // user click on 'cancel appointment', results in opening cancel appointment dialog
  $("a.cancel").click(function() {
    // fill in appointment values
    var service_name    = $(this).parents("div.appointment").find("div.service a").text();
    var start_date_time = $(this).parents("div.appointment").find("div.start_date_time").text();
    var customer_name   = $(this).parents("div.appointment").find("div.customer h6").text();
    var cancel_url      = $(this).attr('href');
    $("div.dialog#cancel_appointment_dialog").find("#service_name").text(service_name);
    $("div.dialog#cancel_appointment_dialog").find("#start_date_time").text(start_date_time);
    $("div.dialog#cancel_appointment_dialog").find("#customer_name").text(customer_name);
    $("div.dialog#cancel_appointment_dialog").find("a#cancel_appointment").attr('href', cancel_url);
    // open dialog
    $("div.dialog#cancel_appointment_dialog").dialog('open');
    return false;
  })
}

$.fn.init_schedule_datepicker = function() {
  $(".pdf.datepicker").datepicker({minDate: '-1m', maxDate: '+3m'});
}

$.fn.init_schedule_timepicker = function() {
  $(".appointment.work.timepicker").timepickr({convention:12, left:0});
  $(".appointment.free.timepicker").timepickr({convention:12, left:0});
}

$.fn.init_schedule_pdf = function() {
  // initialize show pdf date range dialog
  $("div.dialog#pdf_schedule_date_range_dialog").dialog({modal: true, autoOpen: false, hide: 'slide', width: 475, height: 225, show: 'fadeIn(slow)', title: $("div#pdf_schedule_date_range_dialog").attr('title')})

  $("a#pdf_schedule_date_range").click(function() {
    // clear date form fields
    $("div.dialog#pdf_schedule_date_range_dialog input.datepicker").val('');
    // open dialog on click
    $("div.dialog#pdf_schedule_date_range_dialog").dialog('open');
    return false;
  })

  $("form#pdf_schedule_date_range_form").submit(function() {
    // check start, end dates
    var start_date  = $(this).find("input#pdf_start_date").attr('value');
    var end_date    = $(this).find("input#pdf_end_date").val();
  
    if (!start_date) {
      alert("Please enter a start date");
      return false;
    }

    if (!end_date) {
      alert("Please enter an end date");
      return false;
    }

    if (validate_start_before_equal_end_date(start_date, end_date) == false) {
      alert("The end date is earlier than the start date");
      return false;
    }
  
    // close dialog
    $("div.dialog#pdf_schedule_date_range_dialog").dialog('close');

    return true;
  })

  /*
  $("#send_pdf_dialog").dialog({ autoOpen: false });
  
  $("#send_pdf").click(function() {
    // open dialog on click
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
  */
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
                                                          rows[i] = { data:data[i], value: data[i].name+(data[i].email ? " "+data[i].email : '')+(data[i].phone ? " "+data[i].phone : ''), result:data[i].name };
                                                      }
                                                      return rows;
                                                  },
                                            formatItem: function(data,i,max,value,term) { return value; },
                                            autoFill: false
                                          });
  
  $("#customer_name").result(function(event, data, formatted) {
    // set the customer id
    $("#customer_id").attr("value", data.id);
  });

}

$(document).ready(function() {
  $(document).init_schedule_datepicker();
  $(document).init_schedule_timepicker();
  $(document).init_search_calendar_with_date_range();
  $(document).init_add_single_free_time();
  $(document).init_add_appointment();
  $(document).init_cancel_appointment();
  $(document).init_select_calendar_show_provider();
  $(document).init_show_appointment_on_hover();
  $(document).init_add_calendar_markings();
  $(document).init_schedule_pdf();
  $(document).init_autocomplete_customers();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_select_calendar_show_provider();
})
