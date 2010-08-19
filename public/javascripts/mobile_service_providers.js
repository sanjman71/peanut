// Modes can be 'services' or 'providers'
// 'services'   - changing services drives the available providers
// 'providers'  - changing providers drives the available services
var sp_select_mode     = '';

// Initialize services list based on the specified provider
// provider_key => e.g. 'users/18'
// form_select_list => e.g. "select#select_id"
// selected_service_id => e.g. '1'
$.fn.init_provider_services = function(provider_key, form_select_list, selected_service_id) {
  // remove all services
  $(form_select_list).removeOption(/./);
  
  if (selected_service_id == 0) {
    // add 'Pick a Service' option, mark as selected
    $(form_select_list).addOption('', 'Select a Service', true);
  }

  $.each(provider_services.get(provider_key), function(index, service_tuple) {
    // add the service to the select box, tuple is [service_id, service_name]
    $(form_select_list).addOption(service_tuple[0], service_tuple[1], selected_service_id == service_tuple[0]);
  })
}

// Find the current selected service
$.fn.get_service = function() {
  var service_id = $('select#service_id').val();
  var service    = services.get(service_id);

  // check if its a valid service
  if (service == undefined) { return 0; }

  return service_id;
}

// Initialize providers list based on the specified service
$.fn.init_service_providers = function(service_id) {
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
  var providers     = service_providers.get(service_id);

  $.each(providers, function(index, provider_tuple) {
    // add the provider type and id (e.g. users/3) as the type, and the provider name as the value
    klass = provider_tuple[2]
    id    = provider_tuple[0]
    name  = provider_tuple[1]
    $('select#provider').addOption(klass+'/'+id, name, (id == current_provider_id) && (klass == current_provider_type));
    num_providers += 1;
  })

  // add the special 'Anyone' provider iff a service has been selected and the service has 0 or > 1 providers
  if (service_id != 0 && (num_providers == 0 || num_providers > 1) && allow_anyone_provider)
  {
    $('select#provider').addOption(0, "Anyone", 0 == current_provider_id);
  }
}

// Set the service duration based on the current selected service
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
}

// Service changed
$.fn.init_select_service_change = function() {
  $("select#service_id").change(function() {
    var service_id = $(document).get_service();
    if (sp_select_mode == 'services') {
      // set the providers collection if services drive the interface
      $(document).init_service_providers(service_id);
    }
    // always set the service duration when the service is changed
    $(document).init_service_duration();
    return false;
  })
}

// Provider changed
$.fn.init_select_provider_change = function() {
  // set services list based on new provider
  $("select#provider").change(function() {
    var provider_key = $('select#provider').val();
    $(document).init_provider_services(provider_key, "select#service_id", -1);
    return false;
  })
}

$(document).ready(function() {
  if (sp_select_mode == 'services') {
    $(document).init_select_service_change();
  } else if (sp_select_mode == 'providers') {
    $(document).init_select_service_change();
    $(document).init_select_provider_change();
  }
})
