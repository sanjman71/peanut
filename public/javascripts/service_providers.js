var service_providers = new Array();

$.fn.init_service_providers = function () {
  // build service_providers array
  $(".service_providers .service_provider").each(function(index, service_provider)
  {
    var service_id        = $(service_provider).attr("service_id");
    var schedulable_id    = $(service_provider).attr("schedulable_id");
    var schedulable_name  = $(service_provider).attr("schedulable_name");
    var schedulable_type  = $(service_provider).attr("schedulable_type");

    // create an array with the service id, schedulable id and name
    service_providers.push([service_id, schedulable_id, schedulable_name, schedulable_type]);
  });
}

$.fn.init_schedulables = function () {
  // find the selected service
  var service_id = $('#service_id').val();
  
  // remove all schedulables
  $('#schedulable').removeOption(/./);
  
  // find the schedulable initially selected
  var initial_schedulable_id = $('#initial_schedulable_id').attr("value");
  var initial_schedulable_type = $('#initial_schedulable_type').attr("value");
  
  // add schedulables who provide the selected service
  var num_providers = 0;
  $.each(service_providers, function (index, service_provider) {
    if (service_provider[0] == service_id)
    {
      // add the schedulable type and id (e.g. users/3) as the type, and the schedulable name as the value 
      $('#schedulable').addOption(service_provider[3]+'/'+service_provider[1], service_provider[2], (service_provider[1] == initial_schedulable_id) && (service_provider[3] == initial_schedulable_type));
      num_providers += 1;
    }
  })
  
  // add the special 'Anyone' schedulable iff a service has been selected and the service has 0 or > 1 providers
  if (service_id != 0 && (num_providers == 0 || num_providers > 1)) {
    $('#schedulable').addOption(0, "Anyone", 0 == initial_schedulable_id);
  }
  
  if (service_id != 0) {
    // remove any error visuals
    $("#what_text").removeClass("highlight");
  }
}

$(document).ready(function() {
  $(document).init_service_providers();
  $(document).init_schedulables();
    
  // when a service is selected, rebuild the schedulable service provider select list
  $("#service_id").change(function () {
    $(document).init_schedulables();
    return false;
  })
})