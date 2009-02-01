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

// Add a membership (person to service mapping)
$.fn.init_new_membership = function () {
  // Bind to person drop-down used to create memberships
  $("#person_id").change(function () {
    $("#membership_resource_id").attr("value", $("#person_id option:selected").attr("value"));
    $.post($("#new_membership").attr("action"), $("#new_membership").serialize(), null, "script");
    return false;
  })
} 

// Add a new object (e.g. person, service, product)
$.fn.init_new_object = function(form_id) {
  // validate the form by binding a callback to the submit function
  $(form_id).validate({
    // handle form errors by highlighting the required field 
    showErrors: function(errorMap, errorList) {
      $(".required").addClass('highlighted');
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
    // handle form errors by highlighting the required field 
    showErrors: function(errorMap, errorList) {
      $(".required").addClass('highlighted');
    },
    // don't validate until the form is submitted and we call valid
    onfocusout: false,
    onkeyup: false,
    onsubmit: false
  });
  
  $("#add_free_time_form").submit(function () {
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
       // handle form errors by highlighting the required field 
       $(".required").addClass('highlighted');
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
    // note: the validate function has already been caled at this point, but I'm not
    // sure how to get its result w/o calling valid explicitly here
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
    // replace the search button with a progress image when its clicked
    $("#search_submit").addClass('hide');
    $("#search_progress").removeClass('hide');
  })
}

// Highlight appointments and show edit/delete options on hover
$.fn.init_highlight_appointments = function () {
  $(".appointment").hover(function () {
    $("#hover_" + this.id).show();
    $(this).addClass("highlighted");},
    function () {
      $("#hover_" + this.id).hide();
      $(this).removeClass("highlighted");
  })
} 

// Show apointments for the selected person
$.fn.init_show_appointments = function () {
  $("#person_id").change(function () {
    var href = '/people/' + this.value + '/appointments';
    window.location = href;
    return false;
  })
}

// Highlights timeslots and show edit/delete options on hover
$.fn.init_highlight_timeslots = function () {
  $(".timeslot").hover(function () {
    $("#hover_" + this.id).show();
    $(this).addClass("highlighted");},
    function () {
      $("#hover_" + this.id).hide();
      $(this).removeClass("highlighted");
  })
} 

// Live people search
$.fn.init_live_people_search = function () {
  $("#live_search_for_people").keyup(function () {
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

// Initialize location switcher allowing users to change the current location
$.fn.init_switch_locations = function() {
  $('#location_switcher li').hover(
    // add block class for internet explorer
    function() { 
      $('ul', this).css('display', 'block');
      $('#location_switcher_link').addClass('hide');
    },
    function() { 
      $('ul', this).css('display', 'none'); 
      $('#location_switcher_link').removeClass('hide');
    }
  );
}

// Replace all ujs classes with ajax post calls
// Todo: figure out how to ask the user to confirm before executing a call
$.fn.init_ujs_links = function () {
  // Replace regular links with ajax calls
  $("a.ujs").attr("ujs", function() { return this.href })
  $("a.ujs").attr("href","javascript:void(0)")

  $("a.ujs").click(function() {
    // Check if its a rails delete link
    if ($(this).attr("class").match(/delete/i))
      var params = {_method : 'delete'};
      
    // Check if a confirmation is required
    if ($(this).attr("class").match(/confirm/i)) {
      question  = $(this).attr("question") || "Are you sure?"
      yesno     = confirm(question);
      
      if (yesno == false)
        return false;
    }
    
    $.post($(this).attr("ujs"), params, null, "script");
    return false;
  })
}

$(document).ready(function() {
  // Initialize all ujs links
  $(document).init_ujs_links();
  $(document).init_switch_locations();
  
  $(document).init_schedule_search();
})

