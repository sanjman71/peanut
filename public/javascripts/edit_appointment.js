$.fn.init_edit_appointment = function() {
  $("form#edit_appointment_form").submit(function () {
    // Provider is built into the form when it's generated - the end user doesn't provide this information.
    var service_id  = $("form#edit_appointment_form select#appointment_service_id").val();
    var customer_id = $("form#edit_appointment_form input#appointment_customer_id").val();
    var start_date  = $("form#edit_appointment_form input#start_date").val();
    var start_time  = $("form#edit_appointment_form input#start_time").val();
  
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
    $("form#edit_appointment_form input#appointment_start_at").attr('value', start_date + 'T' + start_time);
    // force end_at to be recalculated while saving the appointment
    $("form#edit_appointment_form input#appointment_end_at").attr('value', '');

    // disable start_time field
    $("form#edit_appointment_form input#appointment_start_time").attr('disabled', 'disabled');

    // serialize form
    data = $(this).serialize();
    //alert("form serialize: " + data);
    //return false;

    // enable start_time field
    $("form#edit_appointment_form input#appointment_start_time").removeAttr('disabled');

    // post
    $.post(this.action, data, null, "script");
    $(this).find('input[type="submit"]').replaceWith("<h3 class ='submitting'>Updating...</h3>");
    return false;
  })
}

$.fn.init_appointment_datepicker = function() {
  $(".edit_appointment input.datepicker:not(.hasDatepicker) ").datepicker({minDate: '0', maxDate: '+6m'});
}

$.fn.init_appointment_timepicker = function() {
  $(".edit_appointment input.timepicker").timepickr({convention:12, left:0});
}

var customers = new Array();
$.fn.init_autocomplete_customers = function() {
  // Set up the autocomplete
  // Setup help for the JSON solution from here: http://blog.schuager.com/2008/09/jquery-autocomplete-json-apsnet-mvc.html
  // and here: http://www.it-eye.nl/weblog/2008/08/23/using-jquery-autocomplete-with-grails-and-json/
  // This will dynamically invoke the index function on the customers controller, asking for JSON data
  // The parse option is used to parse the JSON result into rows, each containing all the data for the row, the value displayed and the formatted value
  // The formatItem option is also used to format the rows displayed in the pulldown
  $("#appointment_customer_name").autocomplete($("#appointment_customer_name").attr("url"),
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

  $("#appointment_customer_name").result(function(event, data, formatted) {
    // set the customer id
    $("#customer_id").attr("value", data.id);
  });

}

$(document).ready(function() {
  $(document).init_appointment_timepicker();
  $(document).init_appointment_datepicker();
  $(document).init_autocomplete_customers();
  $(document).init_edit_appointment();
})
