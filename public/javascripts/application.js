// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
})

$.ajaxSetup({
  data: { authenticity_token : AUTH_TOKEN }
})

// Prevent a method from being called too often
// One use is to throttle live search requests
Function.prototype.sleep = function (millisecond_delay) {
  if(window.sleep_delay != undefined) clearTimeout(window.sleep_delay);
  var function_object = this;
  window.sleep_delay  = setTimeout(function_object, millisecond_delay);
};

// Reset all elements of a form
/*$.fn.reset_form = function(id) {
  $('#'+id).each(function() {
    this.reset();
  })
}
*/

// Add a service provider mapping a service to a provider
$.fn.init_add_service_provider = function() {
  $("#provider").change(function () {
    // split selected provider value into provider type and id
    var tuple           = $("#provider option:selected").attr("value").split("/");
    var provider_type   = tuple[0];
    var provider_id     = tuple[1];
    $("#service_provider_provider_id").attr("value", provider_id);
    $("#service_provider_provider_type").attr("value", provider_type);
    $.post($("#new_service_provider").attr("action"), $("#new_service_provider").serialize(), null, "script");
    return false;
  })
}

// Add a company to resource mapping
$.fn.init_add_company_resource = function() {
  $(".add_company_resource").click(function() {
    resource_type = $(this).attr("resource_type");
    resource_id   = $(this).attr("resource_id");
    $.post($(this).attr("href"), {"resource[resource_type]" : resource_type, "resource[resource_id]" : resource_id}, null, "script");
    return false;
  })
}

// Add a new object (e.g. person, service, product)
/*
$.fn.init_new_object = function(form_id) {
  // validate the form by binding a callback to the submit function
  $(form_id).validate({
    // handle form errors 
    showErrors: function(errorMap, errorList) {
      // highlight blank fields
      $(".required:blank").addClass('highlighted');
      $(".required").focus();
    },
    // don't validate until the form is submitted and we call valid
    onfocusout: false,
    onkeyup: false,
    onsubmit: false
  });
  
  // do an ajax form post on submit
  $(form_id).submit(function () {
    if ($(this).valid()) {
      $.post(this.action, $(this).serialize(), null, "script");
      // hide the submit button and show the progress bar
      $(this).find("#submit").hide();
      $(this).find("#progress").show();
    }
    return false;
  })
}
*/

// Search for an appointment by its confirmation code
$.fn.init_search_appointments_by_confirmation_code = function () {
  // validate the form by binding a callback to the submit function
  $("#search_appointments_form").validate({
     showErrors: function(errorMap, errorList) {
       // highlight blank fields only
       $(".required:blank").addClass('highlighted');
       $("#appointment_code").focus();
     },
     // don't validate until the form is submitted and we call valid
     onfocusout: false,
     onkeyup: false,
     onsubmit: false
    }
  );
  
  // do an ajax form post on submit
  $("#search_appointments_form").submit(function () {
    // validate the form, and submit iff its valid
    if ($(this).valid()) {
      $.post(this.action, $(this).serialize(), null, "script");
      // hide the submit button and show the progress bar
      $(this).find("#submit").hide();
      $(this).find("#progress").show();
    }
    return false;
  })
}

// Live customers search
$.fn.init_live_customers_search = function () {
  $("#live_search_for_customers").keyup(function () {
    var search_url  = this.url;
    var search_term = this.value;
    // excecut search, throttle how often its called
    var search_execution = function () {
      $.get(search_url, {q : search_term}, null, "script");
      // show search progress bar
      $('#search_progress').show();
    }.sleep(300);
    
    return false;
  })
}

// Highlight invoice chargeable items
$.fn.init_highlight_invoice_chargeables = function () {
  $(".chargeable").hover(function () {
    $(this).addClass("highlighted");},
    function () {
      $(this).removeClass("highlighted");
  })
} 

// Add a new chargeable line itme to an invoice
$.fn.init_add_chargeables = function () {
  // Add the selected service to an invoice
  $("#service_id").change(function () {
    $.post($("#add_chargeable_service").attr("action"), $("#add_chargeable_service").serialize(), null, "script");
    return false;
  })
  // Add the selected product to an invoice
  $("#product_id").change(function () {
    $.post($("#add_chargeable_product").attr("action"), $("#add_chargeable_product").serialize(), null, "script");
    return false;
  })
}

$.fn.init_change_chargeable_prices = function() {
  // update the price
  $(".price.update").submit(function () {
    $.post(this.action, $(this).serialize(), null, "script");
    return false;
  })

  // hide price, show edit price
  $(".price.edit").click(function () {
    $('#' + $(this).attr("hide")).addClass('hide');
    $('#' + $(this).attr("click")).removeClass('hide');
    return false;
  })

  // cancel edit price, show price
  $(".price.edit.cancel").click(function () {
    $('#' + $(this).attr("hide")).addClass('hide');
    $('#' + $(this).attr("click")).removeClass('hide');
    return false;
  })
}

// Reset the chargeables select list to the first value
$.fn.reset_chargeables = function () {
  $("#service_id").attr("selectedIndex", 0);
  $("#product_id").attr("selectedIndex", 0);
}

// Change session location onchange
$.fn.init_change_location = function() {
  // $("select#location_id").change(function () {
  //   var href = '/locations/' + this.value + '/select';
  //   window.location = href;
  //   return false;
  // })
}

$.fn.init_toggle_dates = function() {
  // show dates and hide links
  $('#show_dates').bind(
    'click',
    function() {
      $('#dates').show();
      $('#links').hide();
      return false;
    }
  );
  
  // show links and hide dates
  $('#show_links').bind(
    'click',
    function() {
      $('#links').show();
      $('#dates').hide();
      return false;
    }
  );
}

// Replace all ujs classes with ajax post calls; ask user for confirmation if required.
$.fn.init_ujs_links = function () {
  $("a.ujs").live('click', function() {
    // Check if its a rails delete link
    if ($(this).attr("class").match(/delete/i))
      var params = {_method : 'delete'};
      
    // Check if a confirmation is required
    if ($(this).attr("class").match(/confirm/i)) {
      question  = $(this).attr("question") || "Are you sure?"
      yesno     = confirm(question);
      
      if (yesno == false)
      {
        return false;
      }
    }
    
    $.post($(this).attr("href"), params, null, "script");
    return false;
  });
}

// initialize rounded corners
$.fn.init_rounded_corners = function () {
  $('.rounded').corners();
}

$.fn.init_log_entries = function () {
  $("a#show_add_event_form").click(function(){
    $('#add_event_form').toggle();
  })
  $("a.show_message_body").click(function(){
    $(this).parent().next('.message_body_text').toggle();
  })
}

// build date time string from date, time args
// date => 20100101
// time => 183000
function build_date_time_string(date, time) {
  // parseDate returns a string with format: 'Mon Jan 25 2010 00:00:00: GMT-0600 (CST)
  var date  = $.datepicker.parseDate('yymmdd', date).toString();
  // keep the day of week and date part
  var date  = date.match(/^(\w{3,3} \w{3,3} \d{2,2} \d{4,4})/)[1]
  // convert military time to ampm time
  var time  = convert_time_military_to_ampm_string(time);

  var dt    = date + " @ " + time;
  return dt;
}

// convert mm/dd/yyyy date to yyyymmdd string
function convert_date_to_string(s) {
  re    = /(\d{2,2})\/(\d{2,2})\/(\d{4,4})/
  match = s.match(re);
  if (!match) {
    s = ''
  } else {
    s = match[3] + match[1] + match[2]
  }
  return s
}

// convert yyyymmdd string to mm/dd/yyyy
function convert_string_to_date(s) {
  re    = /(\d{4,4})(\d{2,2})(\d{2,2})/
  match = s.match(re);
  if (!match) {
    s = ''
  } else {
    s = match[2] + '/' + match[3] + '/' + match[1]
  }
  return s
}

// convert '03:00 pm' time format to 'hhmmss' 24 hour time format
function convert_time_ampm_to_string(s) {
  re      = /(\d{2,2}):(\d{2,2}) (am|pm)/
  match   = s.match(re);

  // convert hour to integer, leave minute as string
  hour    = parseInt(match[1], 10); 
  minute  = match[2];
  ampm    = match[3]

  if (ampm == 'pm' && hour != 12) {
    // add 12 for pm, unless hour == 12
    hour += 12;
  }

  value = hour < 10 ? "0" + hour.toString() : hour.toString()
  value += minute + "00";
  return value;
}

// convert '150000' time format to '3 pm' 12 hour time format
function convert_time_military_to_ampm_string(s) {
  re      = /(\d{2,2})(\d{2,2})(\d{2,2})/
  match   = s.match(re);

  // convert hour to integer
  hour    = parseInt(match[1], 10);
  minute  = match[2]

  // adjust hour and set ampm
  hour    = (hour < 12) ? hour : hour-12
  ampm    = (hour < 12) ? 'am' : 'pm'

  value   = hour.toString();
  value   += ":" + minute + " " + ampm;
  return value;
}

function validate_email_address(email_address) {
  var email_regex = /^[a-zA-Z0-9\+._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
  if (email_regex.test(email_address) == false) {
    return false;
  }
  return true;
}

function validate_phone_number(phone_number) {
  var phone_regex = /^[0-9]+$/;
  if (phone_regex.test(phone_number) == false) {
    return false;
  }
  return true;
}

// returns true if the start date is < the end date
// start_date => e.g. 01/01/2010
// end_date => e.g. 02/01/2010
function validate_start_before_end_date(start_date, end_date) {
  start_date = new Date(start_date);
  end_date   = new Date(end_date);
  return ((start_date < end_date) ? true : false);
}

function validate_start_before_equal_end_date(start_date, end_date) {
  start_date = new Date(start_date);
  end_date   = new Date(end_date);
  return ((start_date <= end_date) ? true : false);
}

$(document).ready(function() {
  // initialize all ujs links
  $(document).init_ujs_links();
  // initialize change location select link
  $(document).init_change_location();
  // initialize rounded corners
  $(document).init_rounded_corners();
  // show tabs
  $("div#tabs").show();
})

