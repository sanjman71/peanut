$.fn.init_autocomplete_customer_data = function() {
  // post json, override global ajax beforeSend defined in application.js
  $.ajax({
          type: "POST",
          url: "/users/index",
          dataType: "json",
          beforeSend: function(xhr) {xhr.setRequestHeader("Accept", "application/json");},
          success: function(data) {
            var customers = []
            $.each(data, function(i, item) {
              console.log(item.user.name + ":" + item.user.id);
              customers.push(item.user.name)
            })
            
            // init autocomplete field with customer info
            $("#customer_search_text").autocomplete(customers, {autofill:false, matchContains:true});
          }
        });
}

$.fn.init_change_appointment_customer = function() {
  // test autocomplete
  var data = "Sanjay Killian Sam Kirby".split(" ");
  //$("#customer_search_text").autocomplete(data, {autofill:false});
  
  $("#customer_search_text").result(function(event, data, formatted) {
    console.log("result: " + data);
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

$(document).ready(function() {
  $(document).init_add_free_time(); // don't need to rebind after an ajax call
  $(document).init_select_schedulable_for_calendar_show();
  $(document).init_highlight_appointments();
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
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_select_schedulable_for_calendar_show();
  $(document).init_highlight_appointments();
})
