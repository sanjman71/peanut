var service_providers = new Array();
var services          = new Array();

$.fn.init_service_providers = function () {
  // build service_providers array
  $(".service_providers.hide .service_provider").each(function(index, service_provider)
  {
    var service_id     = $(service_provider).attr("service_id");
    var provider_id    = $(service_provider).attr("provider_id");
    var provider_name  = $(service_provider).attr("provider_name");
    var provider_type  = $(service_provider).attr("provider_type");
    
    // populate array with the service id, provider id and name
    service_providers.push([service_id, provider_id, provider_name, provider_type]);
  });
}

$.fn.init_services = function() {
  // build services array
  $(".services.hide .service").each(function(index, service)
  {
    var service_id            = $(service).attr("service_id");
    var allow_custom_duration = $(service).attr("allow_custom_duration");
    var service_duration      = $(service).attr("service_duration");

    // populate array with the custom duration and service duration info
    services.push([service_id, allow_custom_duration, service_duration]);
  });
}

$.fn.init_providers = function () {
  // find the selected service
  var service_id = $('#service_id').val();
  
  // remove all providers
  $('#provider').removeOption(/./);
  
  // find the provider initially selected
  var initial_provider_id = $('#initial_provider_id').attr("value");
  var initial_provider_type = $('#initial_provider_type').attr("value");
  
  // add providers who provide the selected service
  var num_providers = 0;
  
  $.each(service_providers, function (index, service_provider) {
    if (service_provider[0] == service_id)
    {
      // add the provider type and id (e.g. users/3) as the type, and the provider name as the value 
      $('#provider').addOption(service_provider[3]+'/'+service_provider[1], service_provider[2], (service_provider[1] == initial_provider_id) && (service_provider[3] == initial_provider_type));
      num_providers += 1;
    }
  })

  var allow_custom_duration     = false;
  var default_duration_in_words = '';

  $.each(services, function (index, service) {
    if (service[0] == service_id)
    {
      if (service[1] == 1)
      {
        // the service allows a custom duration
        allow_custom_duration = true;
      }
      
      // store the service duration string
      default_duration_in_words = service[2];
    }
  })
  
  // add the special 'Anyone' provider iff a service has been selected and the service has 0 or > 1 providers
  if (service_id != 0 && (num_providers == 0 || num_providers > 1)) {
    $('#provider').addOption(0, "Anyone", 0 == initial_provider_id);
  }
  
  // check if the selected service allows a custom duration
  if (allow_custom_duration)
  {
    // show the duration select div
    $(".duration .change").show();
  } else {
    // hide the duration select div
    $(".duration .change").hide();
  }

  // update default duration text
  $("#duration_in_words").html(default_duration_in_words);
}

$.fn.init_default_duration = function() {
  // set the duration selected value based on the duration text
  var duration_text = $("#duration_in_words").text().replace("Typically ", '');
  $("select#duration option:contains(" + duration_text + ")").attr("selected", 'selected');
}

$(document).ready(function() {
  $(document).init_service_providers();
  $(document).init_services();
  $(document).init_providers();
    
  // when a service is selected, rebuild the provider service provider select list
  $("#service_id").change(function () {
    $(document).init_providers();
    $(document).init_default_duration();
    return false;
  })
})