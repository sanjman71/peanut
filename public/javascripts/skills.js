var skills = new Array();

$.fn.init_skills = function () {
  $.getJSON("/javascripts/skillset.js", function(json) {
    // Initialize skills array
    $.each(json, function (index, tuple) {
      skills.push(tuple);
    })
    
    // Initalize the rest of the page after the skills have been set
    $(document).init_people();
    $(document).init_search_button();
  })
  
}

$.fn.init_people = function () {
  // Find selected service
  var service_id = $('#service_id').val();
  
  // Remove all people
  $('#person_id').removeOption(/./);
  
  // Find person initially selected
  var initial_person_id = $('#initial_person_id').attr("value");
  
  // Add special anyone person
  $('#person_id').addOption(0, "Anyone", 0 == initial_person_id);
  
  // Add people providing selected service
  $.each(skills, function (index, skill) {
    if (skill[0] == service_id)
    {
      $('#person_id').addOption(skill[1], skill[2], skill[1] == initial_person_id);
    }
  })
}

$.fn.init_search_button = function () {
  // Find selected service
  var service_id = $('#service_id').val();
  
  // Hide search button unless a service is selected
  if (service_id == 0) {
    $("#search").hide();
  } else {
    $("#search").show();
  }
}

$(document).ready(function() {
  $(document).init_skills();
  
  // Binds service select dropdown
  $("#service_id").change(function () {
    $(document).init_people();
    $(document).init_search_button();
    return false;
  })
})