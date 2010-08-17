var add_work_appt_form  = "form#add_work_appointment_form";

// add appointment for a provider on a specific day
$.fn.init_add_work_appointment = function() {

  // initialize add work appointment dialog
  $("div.dialog#add_work_appointment_dialog").dialog({ modal: true, autoOpen: false, hide: 'slide', width: 625, height: 525, show: 'fadeIn(slow)',
                                                       title: $("div.dialog#add_work_appointment_dialog").attr('title') });

  // open add appointment dialog on click
  $("a#calendar_add_work_appointment").click(function() {
    var form = add_work_appt_form;
    // start date and provider fields are fixed when adding new work appointments
    // set current provider as initial provider_id and provider_type
    $(form).find("input#initial_provider_id").val(current_provider.get("id"));
    $(form).find("input#initial_provider_type").val(current_provider.get("type"));
    // force refresh of service, provider, duration selections
    $(form).find("select#service_id").change();
    //force_provider_selected(form, current_provider.get("id"), current_provider.get("type"));
    // disable providers select
    //$(form).find("select#provider").attr('disabled', 'disabled');
    // set mark as
    $(form).find("input#mark_as").val(current_appt.get("mark_as"));
    // set start date field, and disable
    var normalized_date = current_appt.get("date"); // e.g. 20100805
    var calendar_date   = convert_yymmdd_string_to_mmddyy(normalized_date)
    $(form).find("input#start_date").val(calendar_date);
    $(form).find("input#start_date").addClass('disabled');
    $(form).find("input#start_date").attr('disabled', 'disabled');
    // clear start_at, customer fields
    $(form).find("input#start_time").val('');
    $(form).find("input#customer_name").val('');
    $(form).find("input#customer_id").val('');
    // set start time
    $(form).find("input#start_time").val(current_appt.get("start_ampm")); // e.g 03:00 pm
    // set creator id field, hide creator div used to show creator for edits
    $(form).find("input#creator_id").val(current_user.get("id"));
    $(form).find("div#creator").addClass('hide');
    // enable capacity
    $(form).find("input#capacity").removeAttr('disabled');
    $(form).find("input#capacity").val('');
    // hide appointment show details div
    $(form).find("div#show_details").addClass('hide');
    // set form url and method
    //$(form).attr('action', appointment_create_work_path);
    //$(form).attr('method', 'post');
    // show submit_add, hide submit_edit
    $(form).find("#submit_edit").addClass('hide');
    $(form).find("#submit_add").removeClass('hide');
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
    var duration      = $(this).find("select#duration option:selected").val();
    var capacity      = $(this).find("input#capacity").val();
    var mark_as       = services.get(service_id).get("mark_as");

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

    if (!duration) {
      alert("Please specify the duration");
      return false; 
    }

    if (!customer_id && mark_as == 'work') {
      alert("Please select a customer");
      return false; 
    }

    // normalize time format
    var start_time = convert_time_ampm_to_string(start_time)
    // normalize date format
    var start_date = convert_date_to_string(start_date);

    var start_date_time = start_date + 'T' + start_time;

    if (capacity == '' && mark_as == 'work') {
      // check capacity, allow callback to handle response and detemine whether we should continue
      var check_capacity_url = check_provider_capacity_path.replace(/:provider_type/, provider_type).replace(/:provider_id/, provider_id).replace(/:start_time/, start_date_time).replace(/:duration/, duration);
      $.get(check_capacity_url, {}, function(data) { check_capacity_response(data) }, "json");
      // hide add button, show checking div
      $(this).find('div#submit_add').addClass('hide');
      $(this).find('div#checking').removeClass('hide');
      return false;
    }

    // replace hidden tag start_at with formatted version
    $(this).find("input#start_at").attr('value', start_date_time);

    // set provider_type, provider_id hidden fields; disable provider field
    $(this).find("input#provider_type").attr('value', provider_type);
    $(this).find("input#provider_id").attr('value', provider_id);
    $(this).find("select#provider").attr('disabled', 'disabled');

    // disable start_date, start_time field
    $(this).find("input#start_date").attr('disabled', 'disabled');
    $(this).find("input#start_time").attr('disabled', 'disabled');

    // set mark_as for free vs work apointments
    $(this).find("input#mark_as").attr('value', mark_as);

    if (mark_as == 'work') {
      // add/edit work appointment
      if (current_appt.get("id") == 0) {
        var appt_url = appointment_create_work_path;
        var method   = 'post'
      } else {
        var appt_url = appointment_update_work_path.replace(/:id/, current_appt.get("id"));
        var method   = 'put'
      }
    } else {
      // add/edit free appointment
      if (current_appt.get("id") == 0) {
        var appt_url = appointment_create_free_path.replace(/:provider_type/, provider_type).replace(/:provider_id/, provider_id).replace(/:start_time/, start_date_time).replace(/:duration/, duration);
        var method   = 'post'
      } else {
        var appt_url = appointment_update_free_path.replace(/:id/, current_appt.get("id"));
        var method   = 'put'
      }
    }

    // set form url and method
    $(this).attr('action', appt_url);
    $(this).attr('method', method);

    // serialize form
    data = $(this).serialize();
    //alert("form action: " + this.action + ", form serialize: " + data);

    // check if its a post or put
    if ($(this).attr('method') == 'put') {
      // put
      var action = 'update';
      $.put(this.action, data, null, "script");
    } else {
      // post
      var action = 'add';
      $.post(this.action, data, null, "script");
    }

    // enable start_time field
    $(this).find("input#start_time").removeAttr('disabled');

    // hide add and edit buttons, show adding or updating div
    $(this).find('div#submit_add').addClass('hide');
    $(this).find('div#submit_edit').addClass('hide');
    $(this).find('div#checking').addClass('hide');

    if (action == 'add') {
      $(this).find('div#adding').removeClass('hide');
    } else {
      $(this).find('div#updating').removeClass('hide');
    }

    return false;
  })
}

function check_capacity_response(data) {
  var capacity = data.capacity;
  var form     = $("form#add_work_appointment_form");

  if (capacity < 1) {
    yesno = confirm("Creating this appointment will overbook the provider.  Are you sure you want to continue?");
    if (yesno == false)
    {
      // show add button
      $(form).find("div#submit_add").removeClass('hide');
      $(form).find("div#checking").addClass('hide');
      return false;
    }
  }

  // set capacity, disable field, and click submit to add appointment
  $(form).find("input#capacity").val(capacity);
  $(form).find("input#capacity").attr('disabled', 'disabled');
  $(form).submit();
}

$.fn.init_edit_work_appointment = function() {
  // open add appointment dialog on click
  $("a#calendar_edit_work_appointment").click(function() {
    // use the add work appointment form
    var form = add_work_appt_form;
    // enable start_date field
    $(form).find("input#start_date").removeAttr('disabled');
    // fill in appointment values for the edit form
    var appointment_div   = $(this).closest("div.appointment");
    var appt_id           = current_appt.get("id");
    var mark_as           = current_appt.get("mark_as");
    var start_date        = convert_yymmdd_string_to_mmddyy(current_appt.get("schedule_day"));
    var start_time        = current_appt.get("start_time");
    var duration          = current_appt.get('duration');       // e.g. 3600
    var service_name      = current_appt.get('service');        // e.g. 'Haircut'
    var customer_name     = current_appt.get('customer');       // e.g. 'Joe'
    var customer_id       = current_appt.get('customer_id');    // e.g. '5'
    var provider          = current_appt.get('provider');       // e.g. 'users/11'
    var creator           = current_appt.get('creator');        // e.g. 'Johnny'
    var update_path       = appointment_update_work_path.replace(/:id/, appt_id);
    var cancel_path       = appointment_cancel_path.replace(/:id/, appt_id);
    //var show_path         = appointment_show_path.replace(/:id/, appt_id);
    $(form).find("input#mark_as").val(mark_as);
    $(form).find("input#start_date").val(start_date);
    $(form).find("input#start_time").val(start_time);
    $(form).find("select#service_id").val(service_name).attr('selected', 'selected');
    $(form).find("select#service_id").change();
    $(form).find("select#duration").val(duration).attr('selected', 'selected'); // set duration after service
    $(form).find("input#customer_name").val(customer_name);
    $(form).find("input#customer_id").val(customer_id);
    // select current appointment provider, and disable field
    $(form).find("select#provider").val(provider).attr('selected', 'selected');
    //$(form).find("select#provider").attr('disabled', 'disabled');
    // set creator, and show creator div
    $(form).find("div#creator").removeClass('hide');
    $(form).find("h4#creator_name").text(creator);
    // set capacity
    $(form).find("input#capacity").removeAttr('disabled');
    $(form).find("input#capacity").val('1');
    // set cancel appointment path
    $(form).find("a#cancel_work_appointment").attr('href', cancel_path);
    // set appointment show path, show div
    //$(form).find("a#show_details").attr('href', show_path);
    //$(form).find("div#show_details").removeClass('hide');
    // set form url and method
    $(form).attr('action', update_path);
    $(form).attr('method', 'put');
    // show submit_edit
    $(form).find("#submit_edit").removeClass('hide');
    $(form).find("#submit_add").addClass('hide');
    // open dialog
    $("div.dialog#add_work_appointment_dialog").dialog('open');
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

$(document).ready(function() {
  $(document).init_schedule_datepicker();
  $(document).init_schedule_timepicker();
  $(document).init_add_work_appointment();
  $(document).init_edit_work_appointment();
})