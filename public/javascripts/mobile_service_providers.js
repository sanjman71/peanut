var current_service_id = 0;

$.fn.init_provider_services = function(select_id, provider_key) {
  // remove all services
  $(select_id).removeOption(/./);
  
  // add 'Pick a Service' option, mark as selected
  $(select_id).addOption('', 'Select a Service', true);
  
  $.each(provider_services.get(provider_key), function(index, service_tuple) {
    // add the service to the select box
    $(select_id).addOption(service_tuple[0], service_tuple[1], false);
  })
}

$.fn.init_service = function() {
  // find the selected service
  var service_id = $('select#service_id').val();
  var service = services.get(service_id);

  // check if its a valid service
  if (service == undefined) { current_service_id = 0; }

  // set current service id
  current_service_id = service_id;
}

$.fn.init_service_providers = function() {
  if ($("select#provider").size() == 0) { return; }

  if ($("select#provider").hasClass("anyone"))
  {
    var allow_anyone_provider = true;
  } else {
    var allow_anyone_provider = false;
  }

  // remove all providers
  $('select#provider').removeOption(/./);

  try {
    // use javascript variable to find the current provider id and type
    var current_provider_id   = current_provider.get('id');
    var current_provider_type = current_provider.get('type');
  } catch(e) {
    // use document value to find the current provider id and type
    var current_provider_id   = $('#initial_provider_id').attr("value") || 0;
    var current_provider_type = $('#initial_provider_type').attr("value");
  }

  // add providers who provide the selected service
  var num_providers = 0;
  var providers     = service_providers.get(current_service_id);

  $.each(providers, function(index, provider_tuple) {
    // add the provider type and id (e.g. users/3) as the type, and the provider name as the value
    klass = provider_tuple[2]
    id    = provider_tuple[0]
    name  = provider_tuple[1]
    $('select#provider').addOption(klass+'/'+id, name, (id == current_provider_id) && (klass == current_provider_type));
    num_providers += 1;
  })

  // add the special 'Anyone' provider iff a service has been selected and the service has 0 or > 1 providers
  if (current_service_id != 0 && (num_providers == 0 || num_providers > 1) && allow_anyone_provider)
  {
    $('select#provider').addOption(0, "Anyone", 0 == current_provider_id);
  }
}

$.fn.init_service_duration = function() {
  // if we don't have a duration selector or a service selector, we don't bother with this
  if (($('select#duration').size() == 0) || ($('select#service_id').size() == 0)) {
    return;
  }

  // find the selected service
  var service_id = $('select#service_id').val();
  var service = services.get(service_id);
  // check if its a valid service
  if (service == undefined) { return; }

  // set the duration selected value based on the selected service
  var duration_seconds        = service.get("duration_seconds");
  var duration_words          = service.get("duration_words");
  var allow_custom_duration   = service.get("duration_custom");

  // update default duration text and the selected duration
  $("input#duration_words").val(duration_words);
  $("select#duration").val(duration_seconds).attr("selected", 'selected');

  // check if the selected service allows a custom duration
  if (allow_custom_duration == 1)
  {
    // show the duration select div
    $(".duration.change").show();
  } else {
    // hide the duration select div
    $(".duration.change").hide();
  }

  // Make sure the provider_id and provider_type fields are updated, if they exist
  //update_provider();
}

$.fn.init_select_service_change = function() {
  // when a service is selected, set the service provider and the default service duration
  $("select#service_id").change(function() {
    $(document).init_service();
    $(document).init_service_providers();
    $(document).init_service_duration();
    return false;
  })
}

$(document).ready(function() {
  $(document).init_select_service_change();
})
