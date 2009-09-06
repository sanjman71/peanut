var customers = new Array();

// show appointments for the selected customer
$.fn.init_select_appointments_customer = function () {
  $("#customer").change(function () {
    var href = '/customers/' + this.value + '/appointments';
    window.location = href;
    return false;
  })
}

$.fn.init_autocomplete_customers = function() {
  // post json, override global ajax beforeSend defined in application.js
  $.ajax({
          type: "GET",
          url: $("#customer_search_text").attr("url"),
          dataType: "json",
          async:false,
          beforeSend: function(xhr) {xhr.setRequestHeader("Accept", "application/json");},
          success: function(data) {
            $.each(data, function(i, item) {
              // add customer data as a hash with keys 'name' and 'id'
              console.log(item.user.name + ":" + item.user.id + ":" + item.user.email);
              customers.push({name:item.user.name, id:item.user.id});
            })
            
            // init autocomplete field with customer data
            $("#customer_search_text").autocomplete(customers, 
                                                   {matchContains:true, minChars:0, formatItem: function(item) {return item.name}});
          }
        });
}

$.fn.show_appointment_customer = function() {
  // hide search view, show default text view
  $("span#customer_search").hide();
  $("span#customer_default").fadeIn(200);
  // clear customer text
  $("#customer_search_text").attr("value", '');
}

$.fn.init_change_appointment_customer = function() {
  // called when the user selects a customer from the autocomplete list
  $("#customer_search_text").result(function(event, data, formatted) {
    console.log("selected: " + data.name + ":", data.id);
    // change the customer name and id
    $("#customer_name").html(data.name);
    $("#customer_id").attr("value", data.id);
    $(document).show_appointment_customer();
  })

  $("a#hide_customer_default").click(function() {
    // initialize the customer collection before the first search, and make it a synchronous call
    if (customers.length == 0) {
      $(document).init_autocomplete_customers();
    }
    $("span#customer_default").hide();
    $("span#customer_search").show();
    return false;
  })

  $("a#hide_customer_search").click(function() {
    $(document).show_appointment_customer();
    return false;
  })
}

$.fn.validate_customer_signup = function() {
  if ($("input#customer_name").size == 0) {
    // no customer signup required
    return true;
  }
  
  customer_name  = $("input#customer_name").attr('value');
  customer_email = $("input#customer_email").attr('value');
  
  if (customer_name == '') {
    alert("Please enter a customer name");
    return false;
  }

  if (customer_email == '') {
    alert("Please enter a customer email");
    return false;
  }

  customer_email_valid    = true;
  customer_email_message  = 'validating email ...';
  
  // show email validation message
  $("#customer_email_validate_message").addClass('grey');
  $("#customer_email_validate_message").removeClass('red');
  $("#customer_email_validate_message").text(customer_email_message)
  $("#customer_email_validate_message").show();
  
  // check if customer email is valid
  $.ajax({
    url : "/users/exists",
    data : {email:customer_email},
    async : false,
    type : "POST",
    dataType : "json",
    success: function(msg)
    {
      if (msg.email == 'ok') {
        customer_email_valid = true;
      } else {
        // invalid email
        customer_email_valid    = false;
        customer_email_message  = msg.email; 
      }
    }
  })

  if (customer_email_valid == false) {
    // show email error message
    $("#customer_email_validate_message").addClass('red');
    $("#customer_email_validate_message").removeClass('grey');
    $("#customer_email_validate_message").text(customer_email_message)
    $("#customer_email_validate_message").show();
  } else {
    // hide email validation message
    $("#customer_email_validate_message").hide();
  }

  return customer_email_valid;
}

$.fn.init_confirm_appointment = function() {
  $("#confirm_appointment_submit").click(function() {
    // validate customer signup
    var submit = $(document).validate_customer_signup();

    if (submit == true) {
      // post the search query
      $.post($("#confirm_appointment_form").attr("action"), $("#confirm_appointment_form").serialize(), null, "script");
    
      // show progress bar
      $(this).hide();
      $("#cancel").hide();
      $("#confirm_appointment_submit_progress").show();
    }
    
    return false;
  })
}

$.fn.init_complete_appointment = function() {
  $("#complete_appointment").click(function() {
    $.post($(this).attr("href"), {}, null, "script");
    // show progress bar
    $(this).hide();
    $("#mark_progress").show();
    return false;
  })
}

$.fn.init_send_message = function() {
  $("#send_message_link").click(function() {
    $(this).hide();
    $("#message").show();
    return false;
  })
  
  $("#send_email_message, #send_sms_message").click(function () {
    var url       = $(this).attr('url');
    var appt_id   = $(this).attr('appointment_id');
    var message   = $("#message_textarea").attr("value");
    
    if (message == '') {
      alert("Message is empty");
      return false;
    }
    
    $.post(url, {appointment_id:appt_id, message:message}, null, "script");

    // show progress bar
    $("#message").hide();
    $("#message_progress").show();
    
    return false;
  })

  $("#cancel_message").click(function() {
    $("#message_textarea").attr("value", '');
    $("#message").hide();
    $("#send_message_link").show();
    return false;
  })
}

$.fn.init_reschedule_appointment = function() {
  $("#reschedule_link").click(function() {
    $.post($(this).attr("href"), {}, null, "script");
    return false;
  })
}

$(document).ready(function() {
  $(document).init_search_appointments_by_confirmation_code();  // don't need to rebind after an ajax call
  //$('#appointment_code').focus();
  $('#appointment_time_range_start_at').focus();

  $(document).init_toggle_dates();
  $(document).init_select_appointments_customer();
  
  $(document).init_change_appointment_customer();
  $(document).init_confirm_appointment();
  $(document).init_complete_appointment();
  $(document).init_send_message();
  $(document).init_reschedule_appointment();
})
