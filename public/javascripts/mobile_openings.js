var openings_provider_name  = '';
var openings_provider_id    = 0;
var openings_provider_key   = '';  // e.g. 'users/11'
var openings_schedule_date  = '';  // e.g. 20100101
var openings_schedule_time  = '';  // e.g. 1300

function set_openings_provider(provider_name, provider_id, provider_key) {
  openings_provider_name  = provider_name;
  openings_provider_id    = provider_id;
  openings_provider_key   = provider_key;
}

$.fn.init_openings = function() {
  $("form#search_openings_form").submit(function() {
    var service_id = $(this).find('#service_id').val();

    if (service_id == '0') {
      // alert the user
      alert("Please select a service");
      return false;
    }

    // hide submit button
    $(this).find(".submit").hide();
    $(this).next(".info").show();

    // post request and handle the response
    $.ajax({
      type: $(this).attr('method'),
      url: $(this).attr('action'),
      dataType: 'json',
      data: $(this).serialize(),
      success: function(data) {
        // redirect to openings index path
        window.location = data.redirect;
      }
    });

    return false;
  })

  $("a#pick_provider").bind('tap click', function() {
    set_openings_provider($(this).text(), $(this).attr('provider_id'), $(this).attr('provider_key'));
    return true;
  })

  $("a.bookit.prepare").click(function() {
    // prepare bookit date and time variables
    openings_schedule_date = $(this).closest("ul").attr('id');
    openings_schedule_time = $(this).attr('time');
  
    // build human readable date and time
    var when = $(this).closest("div").find("li.date").text() + " @ " + $(this).text();

    // prepare confirmation form
    $("li#service").text("Service: " + openings_service_name);
    $("li#with").text("With: " + openings_provider_name);
    $("li#when").text("When: " + when);

    return true;
  })

  $("a.bookit.confirm").click(function() {
    // build schedule url
    var datetime  = openings_schedule_date + "T" + openings_schedule_time;
    var url       = schedule_path.replace(/:provider_type\/:provider_id/, openings_provider_key).replace(/:datetime/, datetime);
    var method    = 'post';
    // add customer id to data hash
    var data      = {"customer_id":current_user_id};

    // hide link, show info
    $(this).closest("ul").hide();
    $(this).closest("div").find(".info").show();

    // post request and handle the response
    $.ajax({
      type: method,
      url: url,
      dataType: 'json',
      data: data,
      complete: function(req) {
        if (req.status == 200) {
          alert("Your appointment was confirmed.");
        } else {
          alert("There was an error confirming your appointment.");
        }
        // refresh by going back to openings path
        window.location = openings_path;
      }
    });

    return false;
  })
}

$(document).ready(function() {
  $(document).init_openings();

  // click search button if flag is set
  if (show_search == 1) { $("a#search_button").click(); }
})