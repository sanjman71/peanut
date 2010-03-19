$.fn.init_user_invitation = function() {
  $("form#new_invitation").submit(function() {
    var email_address = $("input#invitation_recipient_email").attr('value');

    if (email_address == '') {
      alert("Please enter an email address");
      return false
    }

    if (validate_email_address(email_address) == false) {
      alert("Please enter a valid email address");
      return false;
    }

    // post
    $.post(this.action, $(this).serialize(), null, 'script')
    // add progress message
    $(this).find("#submit").html('Sending ...');

    return false;
  })

}

$(document).ready(function() {
  $(document).init_user_invitation();
})
