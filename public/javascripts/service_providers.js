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
  
  // add the special anyone schedulable
  $('#schedulable').addOption(0, "Anyone", 0 == initial_schedulable_id);
  
  // add schedulable providing the selected service
  $.each(service_providers, function (index, service_provider) {
    if (service_provider[0] == service_id)
    {
      $('#schedulable').addOption(service_provider[3]+'/'+service_provider[1], service_provider[2], (service_provider[1] == initial_schedulable_id) && (service_provider[3] == initial_schedulable_type));
    }
  })
}

$.fn.init_search_button = function () {
  // find the selected service
  var service_id = $('#service_id').val();
  
  // only show the search button if a service is selected (service id of 0 means no service)
  if (service_id == 0) {
    $("#search_submit").attr("disabled","disabled");
  } else {
    $("#search_submit").removeAttr("disabled");
  }
}

$(document).ready(function() {
  $(document).init_service_providers();
  $(document).init_schedulables();
  $(document).init_search_button();
    
  // when a service is selected, rebuild the schedulable select list and change the search button state
  $("#service_id").change(function () {
    $(document).init_schedulables();
    $(document).init_search_button();
    return false;
  })
})