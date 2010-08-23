var current_provider_name   = '';
var current_provider_id     = 0;
var current_provider_key    = '';  // e.g. 'users/11'
var current_provider_type   = 'users'
var current_provider_calendar_show_path = "/users/:provider_id/calendar/events/:start_date..:end_date";
var current_provider_schedule_loaded = false;
var current_schedule_date   = '';

function set_current_provider(provider_name, provider_id, provider_key) {
  current_provider_name = provider_name;
  current_provider_id = provider_id;
  current_provider_key = provider_key;
  current_provider_schedule_loaded = false;
  // set provider name
  $("a#provider_name").text(current_provider_name);
  // show provider menu
  $("ul#provider_menu").show();
  // clear any old provider schedule dates
  $("div.schedule_date ul li.appointment").remove();
  $("div.schedule_date ul li.capacity").remove();
  $("div.schedule_date ul li.nothing").remove();
  // clear schedule link state, and hide
  $("li.schedule.link").removeClass('work').removeClass('free').removeClass('empty').addClass('hide')
  // show schedule loading
  $("li.schedule.loading").removeClass('hide');
}

function clear_current_provider() {
  current_provider_name = '';
  current_provider_id = 0;
  current_provider_key = '';
  // hide provider menu
  $("ul#provider_menu").hide();
}

function reset_provider_schedule_date(date) {
  $("div.schedule_date#provider_schedule_" + date + " ul li.appointment").remove();
  $("div.schedule_date#provider_schedule_" + date + " ul li.capacity").remove();
  $("div.schedule_date#provider_schedule_" + date + " ul li.nothing").remove();
}

$.fn.init_schedule_providers = function() {
  /*
  $("a#pick_provider").bind('tap click', function() {
    if ($(this).attr('provider_id') != current_provider_id) {
      // initialize js variables
      set_current_provider($(this).text(), $(this).attr('provider_id'), $(this).attr('provider_key'));
    }
    // pop
    jQT.goBack();
    return false;
  })
  */

  // set state when a new schedule provider is selected
  $("select#schedule_provider").change(function() {
    var provider_name = $('select#schedule_provider option:selected').text();
    var provider_key  = $('select#schedule_provider option:selected').val();
    var provider_id   = provider_key.split("/")[1];

    if (provider_id == undefined) {
      // clear provider
      clear_current_provider();
    } else {
      // set new provider
      set_current_provider(provider_name, provider_id, provider_key);
    }
    return false;
  })

  $("div#provider_schedule").bind("pageAnimationEnd", function(e, info) {
    if (info.direction == 'out') return;
    // set title, info
    $(this).find("div.toolbar h1").text(current_provider_name + "'s Schedule");
    $(this).find("div.info").text(current_provider_name + "'s Schedule");
    if (current_provider_schedule_loaded == false) {
      // preload the user's calendar
      var path = current_provider_calendar_show_path.replace(/:provider_id/, current_provider_id).replace(/:start_date/, current_start_date).replace(/:end_date/, current_end_date);
      $.get(path, {}, null, "script");
      current_provider_schedule_loaded = true;
    }
  })

  $("div.schedule_date").bind("pageAnimationEnd", function(e, info) {
    if (info.direction == 'out') return;
    // set title, info
    $(this).find("div.toolbar h1").text(current_provider_name + "'s Schedule");
    $(this).find("div.info").text(current_provider_name + "'s Schedule");
    // set current schedule date
    current_schedule_date = $(this).attr('date');
  })
}

$.fn.init_appointments = function() {
  $("div#add_work_appointment").bind("pageAnimationEnd", function(e, info) {
    if (info.direction == 'out') return;
    // initialize form data
    $(this).find("li#start_date").text(current_schedule_date);
    $(this).find("input#provider_id").val(current_provider_id);
    $(this).find("input#provider_type").val(current_provider_type);
    $(this).find("input#duration_words").val('');
    // intialize provider services
    $(document).init_provider_services(current_provider_key, "select#service_id", 0);
  })

  $("form#add_work_appointment_form").submit(function() {
    // validate fields
    var customer_id   = $(this).find("select#customer_id option:selected").val() || '';
    var service_id    = $(this).find("select#service_id option:selected").val() || '';
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

    if (service_id == '') {
      alert("Please select a service");
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

    // hide submit, show info
    $(this).find(".submit").parent().hide();
    $(this).find(".info").show();

    // post request and handle the response
    $.ajax({
      type: $(this).attr('method'),
      url: $(this).attr('action'),
      dataType: 'json',
      data: $(this).serialize(),
      complete: function(req) {
        if (req.status == 200) {
          alert("Your appointment was created.");
        } else {
          alert("There was an error creating your appointment.");
        }
        // refresh by going back to calendar path
        window.location = calendars_path;
      }
    });

    return false;
  })
}

// live customers search
$.fn.init_live_customers_search = function () {
  $("input#live_search_for_customers").keyup(function() {
    var search_url  = $(this).attr('url');
    var search_term = this.value;
    // check for min length
    if (search_term.length < 3) { return false; }
    // excecute search, throttle how often its called
    var search_execution = function () {
      // show progress, hide results field
      $("li#customer_search_progress").removeClass('hide');
      $("input#customer_search_progress").attr('value', "Searching for '" + search_term + "'");
      $("li#customer_search_results").addClass('hide');
      $.get(search_url, {q : search_term}, null, "script");
      // show search progress bar
      //$('#search_progress').show();
    }.sleep(1000);
    
    return false;
  })
}

$(document).ready(function() {
  $(document).init_schedule_providers();
  $(document).init_appointments();
  $(document).init_live_customers_search();
})
