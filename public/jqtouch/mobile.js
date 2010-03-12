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
  $("div.schedule_date ul li.nothing").remove();
  $("div.schedule_date ul li.loading").show();
}

function reset_provider_schedule_date(date) {
  $("div.schedule_date#provider_schedule_" + date + " ul li.appointment").remove();
  $("div.schedule_date#provider_schedule_" + date + " ul li.capacity").remove();
  $("div.schedule_date#provider_schedule_" + date + " ul li.nothing").remove();
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
    // set title, info
    $(this).find("div.toolbar h1").text(current_provider_name + "'s Schedule");
    $(this).find("div.info").text(current_provider_name + "'s Schedule");
  })

  $("div.schedule_date").bind("pageAnimationEnd", function(e, info) {
    if (info.direction == 'out') return;
    // set title, info
    $(this).find("div.toolbar h1").text(current_provider_name + "'s Schedule");
    $(this).find("div.info").text(current_provider_name + "'s Schedule");
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
    $(this).find("li#start_date").text(current_schedule_date);
    $(this).find("input#provider_id").val(current_provider_id);
    $(this).find("input#provider_type").val(current_provider_type);
  })

  $("form#add_work_appointment_form").submit(function() {
    // validate fields
    var customer_id   = $(this).find("select#customer_id option:selected").val() || '';
    var start_date    = $(this).find("#start_date").text();
    var start_time    = $(this).find("select#start_time option:selected").val();
    var start_ampm    = $(this).find("select#start_ampm option:selected").val();

    if (start_time == '') {
      alert("Please select a start time");
      return false;
    }

    if (start_ampm == '') {
      alert("Please select am or pm");
      return false;
    }

    if (customer_id == '') {
      alert("Please select a customer");
      return false;
    }

    // normalize time format, e.g. "3:00 am" => 030000
    var start_time_ampm = convert_time_ampm_to_string(start_time + " " + start_ampm)
    // normalize date format
    //var start_date = convert_date_to_string(start_date);

    // initialize start_at with formatted version
    $(this).find("input#start_at").attr('value', start_date + 'T' + start_time_ampm);

    // disable start_date, start_time field
    $(this).find("input#start_date").attr('disabled', 'disabled');
    $(this).find("select#start_time").attr('disabled', 'disabled');
    $(this).find("select#start_ampm").attr('disabled', 'disabled');

    // disable customer_search field
    $(this).find("input#live_search_for_customers").attr('disabled', 'disabled');

    //alert("serialize: " + $(this).serialize());

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
    $(this).find("input,select").not('.readonly').removeAttr('disabled');

    return false;
  })
}

// Prevent a method from being called too often
// One use is to throttle live search requests
Function.prototype.sleep = function (millisecond_delay) {
  if(window.sleep_delay != undefined) clearTimeout(window.sleep_delay);
  var function_object = this;
  window.sleep_delay  = setTimeout(function_object, millisecond_delay);
};

// live customers search
$.fn.init_live_customers_search = function () {
  $("input#live_search_for_customers").keyup(function() {
    var search_url  = $(this).attr('url');
    var search_term = this.value;
    // check for min length
    if (search_term.length < 3) { return false; }
    // excecute search, throttle how often its called
    var search_execution = function () {
      $.get(search_url, {q : search_term}, null, "script");
      // show search progress bar
      //$('#search_progress').show();
    }.sleep(1000);
    
    return false;
  })
}

$(document).ready(function() {
  $(document).init_login_submit();
  $(document).init_providers();
  $(document).init_appointments();
  $(document).init_live_customers_search();
})
