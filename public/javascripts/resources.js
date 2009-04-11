// add a resource
$.fn.init_add_resource = function() {
  // validate the form on submit
  $("#new_resource").submit(function () {
    if ($("#resource_name").attr("value") == '') {
      alert("Please enter a resource name");
      $("#resource_name").focus();
      return false;
    }
    
    return true;
  })
}

$(document).ready(function() {
  $(document).init_add_resource();
})