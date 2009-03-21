$.fn.init_autocomplete_customer_data = function() {
  // post json, override global ajax beforeSend defined in application.js
  $.ajax({
          type: "GET",
          url: $("#customer_search_text").attr("url"),
          dataType: "json",
          beforeSend: function(xhr) {xhr.setRequestHeader("Accept", "application/json");},
          success: function(data) {
            var customers = []
            $.each(data, function(i, item) {
              // add customer data as a hash with keys 'name' and 'id'
              console.log(item.user.name + ":" + item.user.id + ":" + item.user.email);
              customers.push({name:item.user.name, id:item.user.id});
            })
            
            // init autocomplete field with customer data
            $("#customer_search_text").autocomplete(customers, 
                                                   {matchContains:true, formatItem: function(item) {return item.name}});
          }
        });
}

$.fn.init_change_appointment_customer = function() {
  $("#customer_search_text").result(function(event, data, formatted) {
    console.log("selected: " + data.name + ":", data.id);
    // save the search customer selected
    $("#customer_search_id").attr("value", data.id);
  })

  $("a#hide_customer_default").click(function() {
    $("span#customer_default").hide();
    $("span#customer_search").show();
    return false;
  })

  $("a#hide_customer_search").click(function() {
    $("span#customer_search").hide();
    $("span#customer_default").show();
    return false;
  })
}

$.fn.init_confirm_appointment = function() {
  $("#confirm_appointment_submit").click(function() {
    // check if the appointment customer has changed
    var customer_search_id = $("#customer_search_id").attr("value");
    if (customer_search_id != "0") {
      // change the form's customer id
      $("#customer_id").attr("value", customer_search_id);
    }
    
    // post the search query
    $.post($("#confirm_appointment_form").attr("action"), $("#confirm_appointment_form").serialize(), null, "script");
    
    // show progress bar
    $(this).hide();
    $("#confirm_appointment_submit_progress").show();
    
    return false;
  })
}

$(document).ready(function() {
  $(document).init_add_free_time(); // don't need to rebind after an ajax call
  $(document).init_select_schedulable_for_calendar_show();
  $(document).init_search_appointments_by_confirmation_code();  // don't need to rebind after an ajax call
  $('#appointment_code').focus();
  $('#appointment_time_range_start_at').focus();

  Date.firstDayOfWeek = 7;
  Date.format = 'mm/dd/yyyy';

  $(document).init_datepicker({start_date : (new Date()).asString(), end_date : (new Date()).addMonths(1).asString(), max_days:10});
  $(document).init_toggle_dates();

  // rounded corners
  $('.rounded').corners();
  
  $(document).init_autocomplete_customer_data();
  $(document).init_change_appointment_customer();
  $(document).init_confirm_appointment();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_select_schedulable_for_calendar_show();
})
