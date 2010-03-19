var service_providers     = new Array();
var services              = new Array();
var allow_anyone_provider = false;

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
    var service_id                = $(service).attr("service_id");
    var allow_custom_duration     = $(service).attr("allow_custom_duration");
    var service_duration_in_words = $(service).attr("service_duration");
    var service_duration_in_secs  = $(service).attr("service_duration_in_secs");

    // populate array with the custom duration and service duration info
    services.push([service_id, allow_custom_duration, service_duration_in_words, service_duration_in_secs]);
  });
}

$.fn.init_providers = function () {
  if ($("select#provider").size() == 0) {
    return;
  }

  if ($("select#provider").hasClass("anyone"))
  {
    allow_anyone_provider = true;
  }

  // find the selected service
  var service_id = $('#service_id').val();
  
  // remove all providers
  $('select#provider').removeOption(/./);
  
  // find the provider initially selected
  var initial_provider_id = $('#initial_provider_id').attr("value");
  var initial_provider_type = $('#initial_provider_type').attr("value");
  
  // add providers who provide the selected service
  var num_providers = 0;
  
  $.each(service_providers, function (index, service_provider) {
    if (service_provider[0] == service_id)
    {
      // add the provider type and id (e.g. users/3) as the type, and the provider name as the value 
      $('select#provider').addOption(service_provider[3]+'/'+service_provider[1], service_provider[2], (service_provider[1] == initial_provider_id) && (service_provider[3] == initial_provider_type));
      num_providers += 1;
    }
  })

  // add the special 'Anyone' provider iff a service has been selected and the service has 0 or > 1 providers
  if (service_id != 0 && (num_providers == 0 || num_providers > 1) && allow_anyone_provider)
  {
    $('select#provider').addOption(0, "Anyone", 0 == initial_provider_id);
  }
  
}

$.fn.init_duration = function() {
  // If we don't have a duration selector or a service selector, we don't bother with this
  if (($('select#duration').size() == 0) || ($('select#service_id').size() == 0)) {
    return;
  }

  // set the duration selected value based on the selected service

  // find the selected service
  var service_id = $('select#service_id').val();

  var allow_custom_duration = false;
  
  // Search for the default duration for this service
  $.each(services, function (index, service) {
    if (service[0] == service_id)
    {
      if (service[1] == 1)
      {
        // the service allows a custom duration
        allow_custom_duration = true;
      }
      
      // update default duration text and the selected duration
      $("div#duration_in_words").html(service[2]);
      $("select#duration").val(service[3]).attr("selected", 'selected');
    }
  })
  
  // check if the selected service allows a custom duration
  if (allow_custom_duration)
  {
    // show the duration select div
    $(".duration .change").show();
  } else {
    // hide the duration select div
    $(".duration .change").hide();
  }

  // Make sure the provider_id and provider_type fields are updated, if they exist
  update_provider();

}

$.fn.init_select_change = function() {
  // when a provider is selected, set the provider id and type
  $("select#provider").change(function () {
    update_provider();
  })

  // when a service is selected, rebuild the provider service provider select list
  $("select#service_id").change(function () {
    $(document).init_providers();
    $(document).init_duration();
    return false;
  })
}

function update_provider() {
  // make sure we have a provider selector on the page and a provider has been selected
  if (($("select#provider").size() == 0) || ($("select#provider option:selected").size() == 0)) {
    return;
  }

  // split selected provider value into provider type and id
  var tuple           = $("select#provider option:selected").attr("value").split("/");
  var provider_type   = tuple[0];
  var provider_id     = tuple[1];
}

// force the specified provider in the specified form to be selected
function force_provider_selected(form, provider_id, provider_type) {
  // find any service provided by the provider
  var provider_service_id = find_any_provider_service(provider_id, provider_type);
  if (provider_service_id == 0) { return; } // no provider service found
  // mark the service as selected and trigger a select change event
  $(form).find("select#service_id").val(provider_service_id).attr('selected', 'selected');
  $(form).find("select#service_id").change();
}

function find_any_provider_service(provider_id, provider_type) {
  // service provider tuple => [service id, provider id, provider name, provider type]
  for(i=0; i < service_providers.length; i++) {
    if ((service_providers[i][1] == provider_id) && (service_providers[i][3] == provider_type)) {
      return service_providers[i][0];
    }
  }
  // no provider services found
  return 0;
}

$(document).ready(function() {
  $(document).init_service_providers();
  $(document).init_services();
  $(document).init_providers();
  $(document).init_duration();
  $(document).init_select_change();    
})
