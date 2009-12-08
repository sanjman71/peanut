$.fn.init_toggle_user_calendar = function() {
  $(".checkbox.calendar").live('click', function() {
    // hide checkbox and label
    $(this).hide();
    $(this).siblings(".checkbox.label").hide();
    // show progress bar
    $(this).siblings(".checkbox.progress").show();
    // post data
    $.post($(this).attr("url"), {}, null, "script");
    return false;
  });
}

$.fn.init_toggle_user_company_manager = function() {
  $(".checkbox.manager").live('click', function() {
    // hide checkbox and label
    $(this).hide();
    $(this).siblings(".checkbox.label").hide();
    // show progress bar
    $(this).siblings(".checkbox.progress").show();
    // post data
    $.post($(this).attr("url"), {}, null, "script");
    return false;
  });
}

$.fn.init_user_create_submit = function() {
  $("input#user_create_submit").click(function() {
    var user_name = $("input#user_name").attr('value');

    if (user_name == '') {
      alert("Please enter a user name");
      return false
    }

    var user_email = $("input#user_email").attr('value');

    if (user_email == '') {
      alert("Please enter a user email");
      return false
    }
    
    if (validate_email_address(user_email) == false) {
      alert("Please enter a valid email address");
      return false;
    }
    
    if (check_user_password_fields(true) == false) {
      return false;
    }

    return true;
  })
}

$.fn.init_user_update_submit = function() {
  $("input#user_update_submit").click(function() {
    // check phone fields
    if (check_user_phone_fields() == false) {
      return false;
    }
    
    // check password fields
    if (check_user_password_fields(false) == false) {
      return false;
    }
    
    return true;
  })
}

function check_user_password_fields(password_required) {
  // check that password is visible
  if (!$("input#user_password").is(":visible")) {
    // password is not visible, skip validation
    return true;
  }

  var password  = $("input#user_password").attr('value');
  var password2 = $("input#user_password_confirmation").attr('value');

  if ((password == '') && (password_required == true)) {
    alert("Please enter a password");
    return false;
  }

  if (password != '') {
    // password confirmation must match
    if (password != password2) {
      alert("Password fields do not match");
      return false;
    }
  }

  return true;
}

function check_user_phone_fields() {
  var phone_address = $("input#phone_address").attr('value');
  var phone_name    = $("input#phone_name").attr('value');
  
  // phone address should not be empty
  if (phone_address != '') {
    if (phone_name == '') {
      alert("Please add a valid phone name");
      return false;
    }
  }

  // phone name should not be empty
  if (phone_name != '') {
    if (phone_address == '') {
      alert("Please add a valid phone number");
      return false;
    }
  }

  return true;
}

$(document).ready(function() {
  $(document).init_toggle_user_calendar();  // re-bind after an ajax call using jquery live()
  $(document).init_toggle_user_company_manager();  // re-bind after an ajax call using jquery live()
  $(document).init_user_update_submit();
  $(document).init_user_create_submit();
})
