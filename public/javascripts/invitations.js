$.fn.init_user_invite_submit = function() {
  $("input#user_invite_submit").click(function() {
    var email_address = $("input#invitation_recipient_email").attr('value');

    if (email_address == '') {
      alert("Please enter an email address");
      return false
    }

    if (validate_email_address(email_address) == false) {
      alert("Please enter a valid email address");
      return false;
    }

    return true;
  })
}

$(document).ready(function() {
  $(document).init_user_invite_submit();
})
