var jQT = new $.jQTouch({cacheGetRequests: false, statusBar: 'black'});

var current_provider_name   = '';
var current_provider_id     = 0;
var current_provider_type   = 'users'
var current_provider_calendar_show_path = "/users/:provider_id/calendar/range/:start_date..:end_date";
var current_schedule_date   = '';

$.fn.init_login_submit = function() {
  $("form#login_form").submit(function() {
    // post request and handle the response
    $.ajax({
      type: $(this).attr('method'),
      url: $(this).attr('action'),
      dataType: 'json',
      data: $(this).serialize(),
      complete: function(req) {
        if (req.status == 200) {
          // click on after login lick
          $("a#after_login").click();
        } else {
          alert("There was an error logging in. Try again.");
        }
      }
    });
    
    return false;
  })
}

function set_current_provider(provider_name, provider_id) {
  current_provider_name = provider_name;
  current_provider_id = provider_id;
  // set provider name
  $("a#provider_name").text(current_provider_name);
  // show provider menu
  $("ul#provider_menu").show();
  // clear any old provider schedule dates
  $("div.schedule_date ul li.appointment").remove();
  $("div.schedule_date ul li.capacity").remove();
  $("div.schedule_date ul li.loading").show();
}

function reset_provider_schedule_date(date) {
  $("div.schedule_date#provider_schedule_" + date + " ul li.appointment").remove();
  $("div.schedule_date#provider_schedule_" + date + " ul li.capacity").remove();
  $("div.schedule_date#provider_schedule_" + date + " ul li.loading").show();
}

$.fn.init_providers = function() {
  $("a#pick_provider").bind('tap click', function() {
    if ($(this).attr('provider_id') != current_provider_id) {
      // initialize js variables
      set_current_provider($(this).text(), $(this).attr('provider_id'));
    }
    // pop
    jQT.goBack();
    return false;
  })

  $("div#provider_schedule").bind("pageAnimationEnd", function(e, info) {
    if (info.direction == 'out') return;
    // set title
    $(this).find("div.toolbar h1").text(current_provider_name + "'s Schedule");
  })

  $("div.schedule_date").bind("pageAnimationEnd", function(e, info) {
    if (info.direction == 'out') return;
    // set title
    $(this).find("div.toolbar h1").text(current_provider_name + "'s Schedule");
    // set current schedule date
    current_schedule_date = $(this).attr('date');
    // check if this date's schedule has already been loaded
    var loaded = $(this).find("ul li.loading:visible").size();
    if (loaded == 0) return;    
    // build calendar show date range path
    var date = $(this).attr('date');
    var path = current_provider_calendar_show_path.replace(/:provider_id/, current_provider_id).replace(/:start_date/, date).replace(/:end_date/, date);
    // get the user's calendar
    $.get(path, {}, null, "script");
  })
}

$.fn.init_appointments = function() {
  $("div#add_work_appointment").bind("pageAnimationEnd", function(e, info) {
    if (info.direction == 'out') return;
    // initialize form data
    $(this).find("input#start_date").val(current_schedule_date);
    $(this).find("input#provider_id").val(current_provider_id);
    $(this).find("input#provider_type").val(current_provider_type);
  })

  $("form#add_work_appointment_form").submit(function() {
    // validate fields
    var service_id    = $(this).find("select#service_id").val();
    var customer_id   = $(this).find("input#customer_id").val();
    var start_date    = $(this).find("input#start_date").val();
    var start_time    = $(this).find("input#start_time").val();

    if (start_time == '') {
      alert("Please select a start time");
      return false;
    }

    if (customer_id == '') {
      alert("Please select a customer");
      return false;
    }

    // normalize time format
    var start_time = convert_time_ampm_to_string(start_time)
    // normalize date format
    //var start_date = convert_date_to_string(start_date);

    // initialize start_at with formatted version
    $(this).find("input#start_at").attr('value', start_date + 'T' + start_time);

    // disable start_date, start_time field
    $(this).find("input#start_date").attr('disabled', 'disabled');
    $(this).find("input#start_time").attr('disabled', 'disabled');

    // disable customer_name field
    $(this).find("input#customer_name").attr('disabled', 'disabled');

    //alert("serialize: " + $(this).serialize());
    //return false;

    // post request and handle the response
    $.ajax({
      type: $(this).attr('method'),
      url: $(this).attr('action'),
      dataType: 'json',
      data: $(this).serialize(),
      complete: function(req) {
        if (req.status == 200) {
          alert("Your appointment was created.")
          // pop
          jQT.goBack();
        } else {
          alert("There was an error creating your appointment.");
        }
      }
    });

    // reset schedule in all cases
    reset_provider_schedule_date(start_date);

    // re-enable all input fields that are not 'readonly'
    $(this).find("input").not('.readonly').removeAttr('disabled');

    return false;
  })
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
  $(document).init_login_submit();
  $(document).init_providers();
  $(document).init_appointments();
  $(document).init_autocomplete_customers();
})
