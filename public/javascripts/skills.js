var skills = new Array();

$.fn.init_skills = function () {
  // build skills array
  $(".skills .skill").each(function(index, skill)
  {
    var service_id  = $(skill).attr("service_id");
    var person_id   = $(skill).attr("person_id");
    var person_name = $(skill).attr("person_name");

    // create an array with the service id, person id and name
    skills.push([service_id, person_id, person_name]);
  });
}

$.fn.init_people = function () {
  // find the selected service
  var service_id = $('#service_id').val();
  
  // remove all people
  $('#person_id').removeOption(/./);
  
  // find the person initially selected
  var initial_person_id = $('#initial_person_id').attr("value");
  
  // add the special anyone person
  $('#person_id').addOption(0, "Anyone", 0 == initial_person_id);
  
  // add people providing the selected service
  $.each(skills, function (index, skill) {
    if (skill[0] == service_id)
    {
      $('#person_id').addOption(skill[1], skill[2], skill[1] == initial_person_id);
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
  $(document).init_people();
  $(document).init_search_button();
    
  // when a service is selected, rebuild the people select list and change the search button state
  $("#service_id").change(function () {
    $(document).init_people();
    $(document).init_search_button();
    return false;
  })
})