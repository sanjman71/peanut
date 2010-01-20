$.fn.init_location_submit = function() {
  $("form#edit_location_form").submit(function () {
    var street_address  = $(this).find("input#location_street_address").val();
    var city            = $(this).find("input#location_city").val();

    if (street_address == '') {
      alert("Please enter a street address");
      return false;
    }
    
    if (city == '') {
      alert("Please enter a city");
      return false;
    }

    $(this).find('div#submit').replaceWith("<h3 class ='submitting'>Adding...</h3>");
    return true;
  })
}

$(document).ready(function() {
  $(document).init_location_submit();
})