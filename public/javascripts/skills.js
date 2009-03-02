var skills = new Array();

$.fn.init_skills = function () {
  // build skills array
  $(".skills .skill").each(function(index, skill)
  {
    var service_id    = $(skill).attr("service_id");
    var resource_id   = $(skill).attr("resource_id");
    var resource_name = $(skill).attr("resource_name");
    var resource_type = $(skill).attr("resource_type");

    // create an array with the service id, resource id and name
    skills.push([service_id, resource_id, resource_name, resource_type]);
  });
}

$.fn.init_resources = function () {
  // find the selected service
  var service_id = $('#service_id').val();
  
  // remove all resources
  $('#resource_id').removeOption(/./);
  
  // find the resource initially selected
  var initial_resource_id = $('#initial_resource_id').attr("value");
  
  // add the special anyone resource
  $('#resource_id').addOption(0, "Anyone", 0 == initial_resource_id);
  
  // add resource providing the selected service
  $.each(skills, function (index, skill) {
    if (skill[0] == service_id)
    {
      $('#resource_id').addOption(skill[3]+'/'+skill[1], skill[2], skill[1] == initial_resource_id);
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
  $(document).init_skills();
  $(document).init_resources();
  $(document).init_search_button();
    
  // when a service is selected, rebuild the resource select list and change the search button state
  $("#service_id").change(function () {
    $(document).init_resources();
    $(document).init_search_button();
    return false;
  })
})