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
    var user_name     = $("input#user_name").attr('value');
    var name_required = $("input#user_name").hasClass('required');

    if (name_required && user_name == '') {
      alert("Please enter a user name");
      return false;
    }

    var errors = 0

    // check email fields
    $("div.email_address").each(function() {
      if (check_user_email_fields(this.id) == false) {
        errors += 1;
      }
    })

    if (errors > 0) { return false; }

    // check phone fields
    $("div.phone_number").each(function() {
      if (check_user_phone_fields(this.id) == false) {
        errors += 1;
      }
    })

    if (errors > 0) { return false; }

    // check password fields
    if (check_user_password_fields(true) == false) {
      return false;
    }

    return true;
  })
}

$.fn.init_user_update_submit = function() {
  $("input#user_update_submit").click(function() {

    var errors = 0

    // check email fields
    $("div.email_address").each(function() {
      if (check_user_email_fields(this.id) == false) {
        errors += 1;
      }
    })

    if (errors > 0) { return false; }

    // check phone fields
    $("div.phone_number").each(function() {
      if (check_user_phone_fields(this.id) == false) {
        errors += 1;
      }
    })

    if (errors > 0) { return false; }

    // check password fields
    if (check_user_password_fields(false) == false) {
      return false;
    }

    return true;
  })
}

$.fn.init_user_add_email = function() {
  $("a#add_email").click(function() {
    // show email fields
    $("div.email_address.hide").show();
    // hide link
    $(this).hide();
    return false;
  })
}

$.fn.init_user_add_phone = function() {
  $("a#add_phone").click(function() {
    // show phone fields
    $("div.phone_number.hide").show();
    // hide link
    $(this).hide();
    return false;
  })
}

$.fn.init_manager_reset_password = function() {
  $("a#manager_reset_password").click(function() {
    $.post($(this).attr('href'), {email:$(this).attr('email')}, null, "script");
    return false;
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

function check_user_email_fields(id) {
  var user_email      = $("#"+id).find("input#user_email").attr('value');
  var email_required  = $("#"+id).find("input#user_email").hasClass('required');

  if (email_required && (user_email == '')) {
    // email is required
    alert("Please enter a user email");
    return false;
  }

  if ((user_email != '') && (validate_email_address(user_email) == false)) {
    // email address is invalid
    alert("Please enter a valid email address");
    return false;
  }
  
  return true;
}

function check_user_phone_fields(id) {
  var phone_address     = $("#"+id).find("input#phone_address").attr('value');
  var phone_name        = $("#"+id).find("select#phone_name").val();
  var address_required  = $("#"+id).find("input#phone_address").hasClass('required');

  if (address_required && (phone_address == '')) {
    // phone address is required
    alert("Please enter a phone number");
    return false;
  }

  if ((phone_address == '') && (phone_name != '')) {
    // phone name, but no address
    alert("Please enter a phone number");
    return false;
  }

  if (phone_address != '' && (validate_phone_number(phone_address) == false)) {
    // phone address is invalid
    alert("Please enter a valid phone number using digits only");
    return false;
  }

  if ((phone_address != '') && (phone_name == '')) {
    // phone address, but no name
    alert("Please select a phone name");
    return false;
  }

  return true;
}

$(document).ready(function() {
  $(document).init_toggle_user_calendar();  // re-bind after an ajax call using jquery live()
  $(document).init_toggle_user_company_manager();  // re-bind after an ajax call using jquery live()
  $(document).init_user_add_email();
  $(document).init_user_add_phone();
  $(document).init_user_update_submit();
  $(document).init_user_create_submit();
  $(document).init_manager_reset_password();
})
