// add appointment for a provider on a specific day
$.fn.init_add_work_appointment = function() {

  // initialize add work appointment dialog
  $("div.dialog#add_work_appointment_dialog").dialog({ modal: true, autoOpen: false, hide: 'slide', width: 625, height: 500, show: 'fadeIn(slow)',
                                                       title: $("div.dialog#add_work_appointment_dialog").attr('title') });

  // open add appointment dialog on click
  $("a#calendar_add_work_appointment").click(function() {
    var form            = "form#add_work_appointment_form";
    // start date and provider fields are fixed when adding new work appointments
    // set current provider as initial provider_id and provider_type
    $(form).find("input#initial_provider_id").val(current_provider.get("id"));
    $(form).find("input#initial_provider_type").val(current_provider.get("type"));
    // force the current provider to be selected
    force_provider_selected(form, current_provider.get("id"), current_provider.get("type"));
    // disable providers select
    $(form).find("select#provider").attr('disabled', 'disabled');
    // set start date field, and disable
    var normalized_date = $(this).parents("td").attr('id');
    var calendar_date   = convert_yymmdd_string_to_mmddyy(normalized_date)
    $(form).find("input#start_date").val(calendar_date);
    $(form).find("input#start_date").addClass('disabled');
    $(form).find("input#start_date").attr('disabled', 'disabled');
    // clear start_at, customer fields
    $(form).find("input#start_time").val('');
    $(form).find("input#customer_name").val('');
    $(form).find("input#customer_id").val('');
    // set creator id field, hide creator div used to show creator for edits
    $(form).find("input#creator_id").val(current_user.get("id"));
    $(form).find("div#creator").addClass('hide');
    // set form url and method
    $(form).attr('action', appointment_create_work_path);
    $(form).attr('method', 'post');
    // set form submit text
    $(form).find("input:submit").val("Add");
    // open dialog
    $("div.dialog#add_work_appointment_dialog").dialog('open');
    return false;
  })

  $("a#add_work_appointment_add_customer").click(function() {
    // close this dialog
    $("div.dialog#add_work_appointment_dialog").dialog('close');
    // show add user dialog, set return dialog link, disable escape
    $("div.dialog#add_user_dialog a#add_user_return_dialog").attr('dialog', "div.dialog#add_work_appointment_dialog");
    $("div.dialog#add_user_dialog").dialog('option', 'closeOnEscape', false);
    $("div.dialog#add_user_dialog").dialog('open');
    return false;
  })
  
  $("form#add_work_appointment_form").submit(function () {
    // Provider is built into the form when it's generated - the end user doesn't provide this information.
    var service_id    = $(this).find("select#service_id").val();
    var customer_id   = $(this).find("input#customer_id").val();
    var start_date    = $(this).find("input#start_date").val();
    var start_time    = $(this).find("input#start_time").val();
    var provider      = $(this).find("select#provider option:selected").val();
    var provider_type = provider.split('/')[0];
    var provider_id   = provider.split('/')[1];

    if (!start_date) {
      alert("Please select a date");
      return false; 
    }
    
    if (!service_id) {
      alert("Please select a service");
      return false; 
    }

    if (!start_time) {
      alert("Please select a start time");
      return false; 
    }

    if (!customer_id) {
      alert("Please select a customer");
      return false; 
    }

    // normalize time format
    var start_time = convert_time_ampm_to_string(start_time)

    // normalize date format
    var start_date = convert_date_to_string(start_date);

    // replace hidden tag formatted version
    $(this).find("input#start_at").attr('value', start_date + 'T' + start_time);

    // set provider_type, provider_id hidden fields; disable provider field
    $(this).find("input#provider_type").attr('value', provider_type);
    $(this).find("input#provider_id").attr('value', provider_id);
    $(this).find("select#provider").attr('disabled', 'disabled');

    // disable start_date, start_time field
    $(this).find("input#start_date").attr('disabled', 'disabled');
    $(this).find("input#start_time").attr('disabled', 'disabled');

    // serialize form
    data = $(this).serialize();
    //alert("form action: " + this.action + ", form serialize: " + data);
    //return false;

    // enable start_time field
    $(this).find("input#start_time").removeAttr('disabled');

    // check if its a post or put
    if ($(this).attr('method') == 'put') {
      // put
      $.put(this.action, data, null, "script");
    } else {
      // post
      $.post(this.action, data, null, "script");
    }
    $(this).find('input[type="submit"]').replaceWith("<h3 class ='submitting'>Adding...</h3>");
    return false;
  })
}

$.fn.init_edit_work_appointment = function() {
  // open add appointment dialog on click
  $("a#edit_work_appointment").click(function() {
    var form          = "form#add_work_appointment_form";
    // enable start_date field
    $(form).find("input#start_date").removeClass('disabled');
    $(form).find("input#start_date").attr('disabled', '');
    // fill in appointment values for the edit form
    var appointment_div   = $(this).closest("div.appointment");
    var appt_id           = $(appointment_div).attr('id').match(/\w_(\d+)/)[1];  // e.e.g 'appointment_13' => '13'
    var start_date        = convert_yymmdd_string_to_mmddyy(appointments.get(appt_id).get("appt_schedule_day"));
    // var start_date        = convert_yymmdd_string_to_mmddyy($(appointment_div).attr('appt_schedule_day'));
    var start_time        = appointments.get(appt_id).get("appt_start_time");
    // var start_time        = $(appointment_div).attr('appt_start_time');
    var duration          = appointments.get(appt_id).get('appt_duration');
    // var duration          = $(appointment_div).attr('appt_duration');
    var service_name      = appointments.get(appt_id).get('appt_service');
    // var service_name      = $(appointment_div).find("div.service a").text();
    var customer_name     = appointments.get(appt_id).get('appt_customer');
    var customer_id       = appointments.get(appt_id).get('appt_customer_id');  // e.g. 'user_5' => '5'
    // var customer_name     = $(appointment_div).find("div.customer div.customer_name").children().text();
    // var customer_id       = $(appointment_div).find("div.customer").attr('id').match(/\w+_(\d+)/)[1];  // e.g. 'user_5' => '5'
    var provider          = appointments.get(appt_id).get('appt_provider'); // e.g. 'users/11'
    // var provider          = $(appointment_div).attr('appt_provider'); // e.g. 'users/11'
    var creator           = appointments.get(appt_id).get('appt_creator'); // e.g. 'Johnny'
    // var creator           = $(appointment_div).attr('appt_creator'); // e.g. 'Johnny'
    $(form).find("input#start_date").val(start_date);
    $(form).find("input#start_time").val(start_time);
    $(form).find("select#service_id").val(service_name).attr('selected', 'selected');
    $(form).find("select#service_id").change();
    $(form).find("select#duration").val(duration).attr('selected', 'selected'); // set duration after service
    $(form).find("input#customer_name").val(customer_name);
    $(form).find("input#customer_id").val(customer_id);
    // select current appointment provider, and disable field
    $(form).find("select#provider").val(provider).attr('selected', 'selected');
    $(form).find("select#provider").attr('disabled', 'disabled');
    // set creator, and show creator div
    $(form).find("div#creator").removeClass('hide');
    $(form).find("h4#creator_name").text(creator);
    // set form url and method
    $(form).attr('action', appointment_update_work_path.replace(/:id/, appt_id));
    $(form).attr('method', 'put');
    // set form submit text
    $(form).find("input:submit").val("Update");
    // open dialog
    $("div.dialog#add_work_appointment_dialog").dialog('open');
    return false;
  })  
}

$.fn.init_cancel_appointment = function() {
  // initialize cancel appointment dialog
  $("div.dialog#cancel_appointment_dialog").dialog({ modal: true, autoOpen: false, hide: 'slide', width: 575, height: 300, show: 'fadeIn(slow)',
                                                     title: $("div.dialog#cancel_appointment_dialog").attr('title') });

  // user click on 'cancel appointment', results in opening cancel appointment dialog
  $("a.cancel").click(function() {
    // fill in dialog appointment values
    var appointment_div     = $(this).closest("div.appointment");
    var appt_id             = $(appointment_div).attr('id').match(/\w_(\d+)/)[1];
    // var service_name        = $(appointment_div).find("div.service").text();
    // var start_date_time     = $(appointment_div).attr('appt_day_date_time');
    // var customer_name       = $(appointment_div).find("div.customer div.customer_name").children().text();
    var start_date_time     = appointments.get(appt_id).get('appt_day_date_time');
    var service_name        = appointments.get(appt_id).get('appt_service');
    var customer_name       = appointments.get(appt_id).get('appt_customer');
    var cancel_url          = $(this).attr('url');
    var edit_recurrence_url = $(this).attr('edit_recurrence');
    var cancel_dialog       = "div.dialog#cancel_appointment_dialog";
    var cancel_dialog_title = "span#ui-dialog-title-cancel_appointment_dialog";
    $(cancel_dialog).find("#service_name").text(service_name);
    $(cancel_dialog).find("#start_date_time").text(start_date_time);
    if ($(this).hasClass('work')) {
      // set title to 'Cancel Appointment'
      $(cancel_dialog_title).text("Cancel Appointment");
      // initialize and show the work appointment customer
      $(cancel_dialog).find("#customer_name").html(customer_name);
      $(cancel_dialog).find("div#customer").show();
    } else {
      // set title to 'Cancel Availability'
      $(cancel_dialog_title).text("Cancel Availability");
      // free appointments don't have customers, so hide this field
      $(cancel_dialog).find("div#customer").hide();
    }
    if (edit_recurrence_url != '') {
      // set edit recurrence link
      $(cancel_dialog).find("a#edit_recurrence").attr('href', edit_recurrence_url);
      // show manage recurrence text
      $(cancel_dialog).find("#manage_recurrence").show();
    } else {
      // hide manage recurrence text
      $(cancel_dialog).find("#manage_recurrence").hide();
    }
    // set cancel appointment link
    $(cancel_dialog).find("a#cancel_appointment").attr('href', cancel_url);
    // open dialog
    $(cancel_dialog).dialog('open');
    return false;
  })

  $("a#cancel_appointment").click(function() {
    $.get(this.href, {}, null, "script");
    $(this).replaceWith("<h3 class ='submitting'>Canceling...</h3>");
    return false;
  })
}

// add free time for a provider on a specific day
$.fn.init_add_free_appointment = function() {
  
  // initialize add free appointment dialog
  $("div#add_free_appointment_dialog").dialog({ modal: true, autoOpen: false, hide: 'slide', width: 575, height: 285, show: 'fadeIn(slow)', 
                                                title: $("div#add_free_appointment_dialog").attr('title') });
  
  // open add free appointment dialog on click
  $("a#calendar_add_free_appointment").click(function() {
    var form            = "form#add_free_appointment_form";
    // set creator field
    $(form).find("input#creator_id").val(current_user.get("id"));
    // set dialog date fields
    var normalized_date = $(this).parents("td").attr('id');
    var calendar_date   = convert_yymmdd_string_to_mmddyy(normalized_date)
    $(form).find("input#date").attr('value', normalized_date);
    $(form).find("input#free_date").val(calendar_date);
    // clear start_at, end_at time fields
    $(form).find("input#free_start_at").val('');
    $(form).find("input#free_end_at").val('');
    // set form submit text
    $(form).find("input:submit").val("Add");
    // open dialog
    $("div#add_free_appointment_dialog").dialog('open');
    return false;
  })

  $("form#add_free_appointment_form").submit(function () {
    var free_date = $(this).find("input#free_date").val();
    var start_at  = $(this).find("input#free_start_at").val();
    var end_at    = $(this).find("input#free_end_at").val();

    if (!free_date) {
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

    // normalize date
    var free_date = convert_date_to_string(free_date);

    // normalize time format, validate that start_at < end_at
    var start_at = convert_time_ampm_to_string(start_at)
    var end_at   = convert_time_ampm_to_string(end_at)

    if (!(start_at < end_at)) {
      alert("The start time must be earlier than the end time");
      return false;
    }

    // set hidden date field
    $(this).find("input#date").attr('value', free_date);

    // set hidden start_at, end_at fields with normalized values
    $(this).find("input#start_at[type='hidden']").attr('value', free_date + 'T' + start_at);
    $(this).find("input#end_at[type='hidden']").attr('value', free_date + 'T' + end_at);
    
    // disable start_at, end_at fields
    $(this).find("input#free_start_at").attr('disabled', 'disabled');
    $(this).find("input#free_end_at").attr('disabled', 'disabled');

    // serialize form
    data = $(this).serialize();
    //alert("form serialize: " + data);
    //return false;

    // enable start_at, end_at fields
    $(this).find("input#free_start_at").removeAttr('disabled');
    $(this).find("input#free_end_at").removeAttr('disabled');

    // check if its a post or put
    if ($(this).attr('method') == 'put') {
      $.put(this.action, data, null, "script");
    } else {
      $.post(this.action, data, null, "script");
    }
    $(this).find('input[type="submit"]').replaceWith("<h3 class ='submitting'>Adding...</h3>");
    return false;
  })
}

$.fn.init_edit_free_appointment = function() {
  // open add free time dialog on click
  $("a#edit_free_appointment").click(function() {
    var form                = "form#add_free_appointment_form";
    // fill in appointment values since this is an edit form
    var appointment_div     = $(this).closest("div.appointment");
    var appt_id             = $(appointment_div).attr('id').match(/\w_(\d+)/)[1];
    // var start_date          = convert_yymmdd_string_to_mmddyy($(appointment_div).attr('appt_schedule_day'));
    // var start_time          = $(appointment_div).attr('appt_start_time');
    // var end_time            = $(appointment_div).attr('appt_end_time');
    var start_date          = convert_yymmdd_string_to_mmddyy(appointments.get(appt_id).get("appt_schedule_day"));
    var start_time          = appointments.get(appt_id).get("appt_start_time");
    var end_time            = appointments.get(appt_id).get("appt_end_time");
    var edit_recurrence_url = $(this).attr('edit_recurrence');
    $(form).find("input#free_date").val(start_date);
    $(form).find("input#free_start_at").val(start_time);
    $(form).find("input#free_end_at").val(end_time);
    $(form).find("a#edit_recurrence").attr('href', edit_recurrence_url);

    if (edit_recurrence_url != '') {
      // free appointment is a recurrence, so show link to manage it
      $(form).find("#manage_recurrence").show();
    } else {
      // free appointment is a not a recurrence
      $(form).find("#manage_recurrence").hide();
    }
    // set form url and method
    $(form).attr('action', appointment_update_free_path.replace(/:id/, appt_id));
    $(form).attr('method', 'put');
    // set form submit text
    $(form).find("input:submit").val("Update");
    // open dialog
    $("div#add_free_appointment_dialog").dialog('open');
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
    var free_capacity_slots = 0;
    var overbooked_capacity_slots = 0;

    // count free capacity slots
    $(this).find("div.capacity_slot.free").each(function() {
      free_capacity_slots += 1;
    })

    // count overbooked capacity slots
    $(this).find("div.capacity_slot.overbooked").each(function() {
      overbooked_capacity_slots += 1;
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
    if (free_capacity_slots > 0) {
      // mark as free, add text
      $("div#free_work_calendar td#" + date).addClass('activity').addClass('free');
      text.push('Free');
    }

    if (work_appointments > 0) {
      // mark as work, add text
      $("div#free_work_calendar td#" + date).addClass('activity').addClass('work');
      text.push('Work');
    }

    if (overbooked_capacity_slots > 0) {
      // mark as overbooked, add text
      $("div#free_work_calendar td#" + date).addClass('activity').addClass('overbooked');
      text.push('<br/>Overbooked');
    }

    // mark text
    $("div#free_work_calendar td#" + date).find("#available").html(text.join(", "));
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

  // mark a calendar date
  if (calendar_highlight_date == 'first-activity') {
    // mark the first calendar date with activity
    $("table.calendar td.activity:first").click();
  } else if ($("table.calendar td#"+calendar_highlight_date).size() > 0) {
    // mark the specified date
    $("table.calendar td#"+calendar_highlight_date).click();
  } else {
    // default to first calendar date with activity
    $("table.calendar td.activity:first").click();
  }

  // show add menu icon on calendar date hover, allow past dates
  $("td .date").hover(function () {
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

$.fn.init_schedule_datepicker = function() {
  $(".pdf.datepicker").datepicker({minDate: '-1m', maxDate: '+3m'});
  $(".appointment.add.edit.datepicker").datepicker({minDate: '0m', maxDate: '+3m'});
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

$.fn.init_truncate = function() {
  $(".truncate").truncate({max_length: 80});
}

$(document).ready(function() {
  $(document).init_schedule_datepicker();
  $(document).init_schedule_timepicker();
  $(document).init_search_calendar_with_date_range();
  $(document).init_add_free_appointment();
  $(document).init_add_work_appointment();
  $(document).init_edit_free_appointment();
  $(document).init_edit_work_appointment();
  $(document).init_cancel_appointment();
  $(document).init_select_calendar_show_provider();
  $(document).init_show_appointment_on_hover();
  $(document).init_add_calendar_markings();
  $(document).init_schedule_pdf();
  $(document).init_autocomplete_customers();
  $(document).init_truncate();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_select_calendar_show_provider();
})
