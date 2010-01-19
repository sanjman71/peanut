$.fn.init_tryit = function() {
  $("form#tryit").submit(function() {
    // validate name and email
    var name  = $(this).find("input#name").val();
    var email = $(this).find("input#email").val();
    
    if (name == '') {
      alert("Please enter a name");
      return false;
    }
    
    if (validate_email_address(email) == false) {
      alert("Please enter a valid email address");
      return false;
    }

    return true;
  })
}

$(document).ready(function() {
  $(document).init_tryit();
})