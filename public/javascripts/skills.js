var skills = new Array();

$.fn.init_skills = function () {
  // build skills array
  $(".skills .skill").each(function(index, skill)
  {
    var service_id        = $(skill).attr("service_id");
    var schedulable_id    = $(skill).attr("schedulable_id");
    var schedulable_name  = $(skill).attr("schedulable_name");
    var schedulable_type  = $(skill).attr("schedulable_type");

    // create an array with the service id, schedulable id and name
    skills.push([service_id, schedulable_id, schedulable_name, schedulable_type]);
  });
}

$.fn.init_schedulables = function () {
  // find the selected service
  var service_id = $('#service_id').val();
  
  // remove all schedulables
  $('#schedulable_id').removeOption(/./);
  
  // find the schedulable initially selected
  var initial_schedulable_id = $('#initial_schedulable_id').attr("value");
  
  // add the special anyone schedulable
  $('#schedulable_id').addOption(0, "Anyone", 0 == initial_schedulable_id);
  
  // add schedulable providing the selected service
  $.each(skills, function (index, skill) {
    if (skill[0] == service_id)
    {
      $('#schedulable_id').addOption(skill[3]+'/'+skill[1], skill[2], skill[1] == initial_schedulable_id);
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
  $(document).init_schedulables();
  $(document).init_search_button();
    
  // when a service is selected, rebuild the schedulable select list and change the search button state
  $("#service_id").change(function () {
    $(document).init_schedulables();
    $(document).init_search_button();
    return false;
  })
})