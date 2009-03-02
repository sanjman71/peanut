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

// Add a membership (resource to service mapping)
$.fn.init_new_membership = function() {
  // bind to resource drop-down used to create memberships
  $("#resource_id").change(function () {
    // split selected value into resource id and type
    var tuple         = $("#resource_id option:selected").attr("value").split(",");
    var resource_id   = tuple[0];
    var resource_type = tuple[1];
    $("#membership_resource_id").attr("value", resource_id);
    $("#membership_resource_type").attr("value", resource_type);
    $.post($("#new_membership").attr("action"), $("#new_membership").serialize(), null, "script");
    return false;
  })
}

// Add company/resource mapping
$.fn.init_add_company_resource = function() {
  $(".add_company_resource").click(function() {
    resource_type = $(this).attr("resource_type");
    resource_id   = $(this).attr("resource_id");
    $.post($(this).attr("href"), {"resource[resource_type]" : resource_type, "resource[resource_id]" : resource_id}, null, "script");
    return false;
  })
}

// Add a new object (e.g. person, service, product)
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

// Add free time for a resource on a specific day
$.fn.init_add_free_time = function() {
  // validate the form by binding a callback to the submit function
  $("#add_free_time_form").validate({
    // handle form errors
    showErrors: function(errorMap, errorList) {
      // highlight blank fields, and set focus on first blank field
      $(".required:blank").addClass('highlighted');
      $(".required:blank:first").focus();
    },
    // don't validate until the form is submitted and we call valid
    onfocusout: false,
    onkeyup: false,
    onsubmit: false
  });
  
  $("#add_free_time_form").submit(function () {
    // reset any previous form errors beforing validating
    $(".required").removeClass('highlighted');
    if ($(this).valid()) {
      $.post(this.action, $(this).serialize(), null, "script");
      $(this).find("#submit").hide();
      $(this).find("#progress").show();
    }
    return false;
  })
}

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

// Search schedules for available appointments
$.fn.init_schedule_search = function () {
  $("#schedule_search_form").submit(function () {
    // replace the search button with a progress image onsubmit
    $("#search_submit").addClass('hide');
    $("#search_progress").removeClass('hide');
    return true;
  })
}

// Highlight appointments and show edit/delete options on hover
$.fn.init_highlight_appointments = function () {
  $(".appointment").hover(
    function () {
      $("#hover_" + this.id).show();
      $(this).addClass("highlighted");
    },
    function () {
      $("#hover_" + this.id).hide();
      $(this).removeClass("highlighted");
    }
  )
} 

// Show appointment schedule for the selected resource
$.fn.init_select_resource_for_appointment_calendar = function () {
  $("#resource_id").change(function () {
    var href = '/' + this.value + '/appointments';
    window.location = href;
    return false;
  })
}

// Show free/available calendar for the selected person
$.fn.init_select_person_for_free_calendar = function () {
  $("#resource_id").change(function () {
    var href = '/' + this.value + '/free/calendar';
    window.location = href;
    return false;
  })
}

// Highlights timeslots and show edit/delete options on hover
$.fn.init_highlight_timeslots = function () {
  $(".timeslot").hover(
    function () {
      $("#hover_" + this.id).show();
      $(this).addClass("highlighted");
    },
    function () {
      $("#hover_" + this.id).hide();
      $(this).removeClass("highlighted");
    }
  )
} 

// Live people search
$.fn.init_live_resources_search = function () {
  $("#live_search_for_resources").keyup(function () {
    var search_url  = this.url;
    var search_term = this.value;
    // execute search, throttle how often its called
    var search_execution = function () {
      $.get(search_url, {search : search_term}, null, "script");
      // show search progress bar
      $('#search_progress').show();
    }.sleep(300);
  
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
      $.get(search_url, {search : search_term}, null, "script");
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

// Add a new note
$.fn.init_add_note = function () {
  $("#new_note").submit(function () {
    $.post(this.action, $(this).serialize(), null, "script");
    return false;
  })
} 

// Change session location onchange
$.fn.init_change_location = function() {
  $("select#location_id").change(function () {
    var href = '/locations/' + this.value + '/select';
    window.location = href;
    return false;
  })
}

$.fn.init_datepicker = function(s) {
  var defaults = {start_date : "01/01/2009", end_date : "12/31/2009", max_days : 7}
  s = $.extend({}, defaults, s);
  
  // initialize date picker object
  $('.date-pick').datePicker({clickInput:true, createButton:false, startDate:s.start_date, endDate:s.end_date});

  // bind to start date selected event
  $('#start_date').bind(
    'dpClosed',
    function(e, selectedDates)
    {
      // get selected start date
      var d = selectedDates[0];
      if (d) {
        d = new Date(d);
        // end date must be after the selected start date
        $('#end_date').dpSetStartDate(d.addDays(1).asString());
        // adjust end date based on max days
        $('#end_date').dpSetEndDate(d.addDays(s.max_days).asString());
      }
    }
  );
  
  // bind to end date selected event
  $('#end_date').bind(
    'dpClosed',
    function(e, selectedDates)
    {
      // get selected end date
      var d = selectedDates[0];
      if (d) {
        d = new Date(d);
        // start date must be before the selected end date
        $('#start_date').dpSetEndDate(d.addDays(-1).asString());
      }
    }
  );
  
  // check date fields before submit
  $("#appointment_submit").click(function() {
    var errors = 0;
    
    if ($('#start_date').attr("value") == '') {
      $('#start_date').addClass('highlighted');
      errors += 1;
    } else {
      $('#start_date').removeClass('highlighted');
    }

    if ($('#end_date').attr("value") == '') {
      $('#end_date').addClass('highlighted');
      errors += 1;
    } else {
      $('#end_date').removeClass('highlighted');
    }
    
    if (errors > 0 ) {
      return false
    } else {
      return true;
    }
  })
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
  $("a.ujs").click(function() {
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
  })
}

$(document).ready(function() {
  // initialize all ujs links
  $(document).init_ujs_links();
  // initialize change location select link
  $(document).init_change_location();
})

$(document).ajaxComplete(function(request, settings) {
  // re-initialize all ujs links and any new links
  $(document).init_ujs_links();
})

