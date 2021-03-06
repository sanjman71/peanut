/*
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
*/

/*
$.fn.init_toggle_user_company_role = function() {
  $(".checkbox.role").live('click', function() {
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
*/

$.fn.init_grant_revoke_user_company_role = function() {
  $("a#show_add_roles").click(function() {
    // reset all spans
    $("span#add_roles").hide();
    $("span#add_roles_text").show();
    // hide this span and show the next
    $(this).closest("span#add_roles_text").hide().next().show();
    return false;
  })

  $("a#cancel_add_roles").click(function() {
    // hide this span and show the previous
    $(this).closest("span#add_roles").hide().prev().show();
    return false;
  })

  $("a#add_role").click(function() {
    var role    = $(this).closest("div.add_roles").find("select#roles option:selected").val();
    var url     = $(this).attr('url').replace(/:role/, role);
    var method  = 'put'
    // its always a put request
    $.put(url, {}, null, "script");
    // show progress text
    $(this).replaceWith('Adding ...')
    return false;
  })

  $("a#remove_role").click(function() {
    $.put(this.href, {}, null, "script");
    // show progress text
    $(this).closest("span.edit_role").replaceWith('Removing ...')
    return false;
  })
}

$.fn.init_user_create_submit = function() {
  $("form#add_user_form").submit(function() {
    var user_name         = $(this).find("input#user_name").attr('value');
    var name_required     = $(this).find("input#user_name").hasClass('required');
    var password_required = $(this).find("input#user_password").hasClass('required');

    if (name_required && user_name == '') {
      alert("Please enter a user name");
      return false;
    }

    var errors = 0

    // check email fields
    $(this).find("div.email_address:visible").each(function() {
      if (check_user_email_fields(this.id) == false) {
        errors += 1;
      }
    })

    if (errors > 0) { return false; }

    // check phone fields
    $(this).find("div.phone_number:visible").each(function() {
      if (check_user_phone_fields(this.id) == false) {
        errors += 1;
      }
    })

    if (errors > 0) { return false; }

    // check password fields
    if (check_user_password_fields("form#add_user_form", password_required) == false) {
      return false;
    }

    // serialize form
    data = $(this).serialize();

    // show progress text
    $(this).find("div#submit").hide();
    $(this).find("div#progress").show();
    
    if (this.action.match(/.json$/)) {
      // post json request and handle json response
      $.post(this.action, data, function(data) { add_user_response(data); }, "json");
      return false;
    } else {
      // post using regular form submit
      return true;
    }
  })

  $("a#add_user_cancel_dialog").click(function() {
    // click on return dialog link
    $("a#add_user_return_dialog").click();
    return false;
  })
  
  $("a#add_user_return_dialog").click(function() {
    // close this dialog, open dialog specified with 'dialog' attribute
    $(this).parents(".dialog").dialog("close");
    var dialog = $(this).attr('dialog');
    $(dialog).dialog("open");
    return false;
  })
}

// handle add user response:
// - on success, response should have user hash containing id and name
// - on failure, response should have user hash with id set to 0 and errors string
function add_user_response(json) {
  //alert("user created: " + json.user.name);

  // hide progress, show submit
  $("form#add_user_form").find("div#progress").hide();
  $("form#add_user_form").find("div#submit").show();

  if (json.user.id == 0) {
    // report the error
    alert(json.user.errors);
  } else {
    // click the return dialog link
    $("a#add_user_return_dialog").click();
  }
}

$.fn.init_user_update_submit = function() {
  $("input#user_update_submit").click(function() {

    var errors = 0

    // check email fields
    $("div.email_address:visible").each(function() {
      if (check_user_email_fields(this.id) == false) {
        errors += 1;
      }
    })

    if (errors > 0) { return false; }

    // check phone fields
    $("div.phone_number:visible").each(function() {
      if (check_user_phone_fields(this.id) == false) {
        errors += 1;
      }
    })

    if (errors > 0) { return false; }

    // check password fields
    if (check_user_password_fields("form.edit_user", false) == false) {
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

$.fn.init_user_add_password = function() {
  $("a#add_password").click(function() {
    // show phone fields
    $("div.password.hide").show();
    // hide link
    $(this).hide();
    return false;
  })
}

$.fn.init_clear_password = function() {
  $("a#clear_password").click(function() {
    $.put($(this).attr('href'), {}, null, "script");
    return false;
  })
}

$.fn.init_manager_reset_password = function() {
  $("a#manager_reset_password").click(function() {
    $.post($(this).attr('href'), {email:$(this).attr('email')}, null, "script");
    return false;
  })
}

$.fn.init_user_add_dialog = function() {
  // initialize add free time dialog
  $("div.dialog#add_user_dialog").dialog({ modal: true, autoOpen: false, hide: 'slide', width: 750, height: 475, open: before_open_user_add_dialog,
                                           show: 'fadeIn(slow)', title: $("div.dialog#add_user_dialog").attr('title') });
}

function before_open_user_add_dialog(event, ui) {
  // clear all form input fields
  $("div.dialog#add_user_dialog :input").not(':button, :submit, :reset, :hidden').val('');
}

$.fn.init_user_login_dialog = function() {

  // initialize login dialog
  $("div.dialog#rpx_login_dialog").dialog({ modal: true, autoOpen: false, hide: 'slide', width: 650, height: 475, show: 'fadeIn(slow)',
                                            title: $("div.dialog#rpx_login_dialog").attr('title') });

  $("span#show_rpx_login_form").click(function() {
    // hide walnut login, show rpx login
    $("div#walnut_login_form").hide();
    $("div#rpx_login_form").show();
    return false;
  })

  $("span#show_walnut_login_form").click(function() {
    // hide rpx login, show walnut login
    $("div#rpx_login_form").hide();
    $("div#walnut_login_form").show();
    return false;
  })
  
  $("span#show_user_signup_form").click(function() {
    // close this dialog
    $("div.dialog#rpx_login_dialog").dialog('close');
    // show add user dialog, set return dialog link, disable escape
    $("div.dialog#add_user_dialog a#add_user_return_dialog").attr('dialog', "div.dialog#rpx_login_dialog");
    $("div.dialog#add_user_dialog").dialog('option', 'closeOnEscape', false);
    $("div.dialog#add_user_dialog").dialog('open');
    return false;
  })

  $("form#login_user_form").submit(function() {
    // check email field
    var email = $(this).find("input#email").val();
    if (email == '') {
      alert("Please enter an email or phone number")
      return false;
    }
    return true;
  })
}

$.fn.open_user_login_dialog = function() {
  $("div.dialog#rpx_login_dialog").dialog('open');
}

$.fn.init_send_message_dialog = function() {
  // initialize send message dialog
  $("div#send_message_dialog").dialog({ modal: true, autoOpen: false, width: 600, height: 375, show: 'fadeIn(slow)', title: $("div#send_message_dialog").attr('title') });

  $("a#send_sms,a#send_email").click(function() {
    // initialize form
    var form = $("form#send_message_form");

    // get phone number or email
    var address = $(this).attr('href');

    // set address, hide subject for sms messages
    $(form).find("input#message_address").val(address);
    $(form).find("input#message_address").attr('disabled', 'disabled');
    if ($(this).attr('id').match(/sms/)) {
      $(form).find("input#message_subject").removeClass('required');
      $(form).find("div#message_subject").addClass('hide');
    } else {
      $(form).find("input#message_subject").addClass('required');
      $(form).find("div#message_subject").removeClass('hide');
    }
    // open dialog
    $("div.dialog#send_message_dialog").dialog('open');

    return false;
  })

  $("form#send_message_form").submit(function() {
    var subject           = $(this).find("input#message_subject").attr('value');
    var subject_required  = $(this).find("input#message_subject").hasClass('required');
    var body              = $(this).find("textarea#message_body").attr('value');
    var body_required     = $(this).find("textarea#message_body").hasClass('required');

    if (subject_required && subject == '') {
      alert("Please enter a message subject");
      return false;
    }

    if (body_required && body == '') {
      alert("Please enter a message body");
      return false;
    }

    // enable address field so it gets serialized
    $(this).find("input#message_address").attr('disabled', '');

    // show progress text
    $(this).find("div#submit").hide();
    $(this).find("div#progress").show();

    return true;
  })
}

function check_user_password_fields(id, password_required) {
  // check that password is visible
  if (!$(id).find("input#user_password").is(":visible")) {
    // password is not visible, skip validation
    return true;
  }

  var password  = $(id).find("input#user_password").val();
  var password2 = $(id).find("input#user_password_confirmation").val();

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
  var email_address   = $("#"+id).find("input#email_address").attr('value');
  var email_required  = $("#"+id).find("input#email_address").hasClass('required');

  if (email_required && (email_address == '')) {
    // email is required
    alert("Please enter a user email");
    return false;
  }

  if ((email_address != '') && (validate_email_address(email_address) == false)) {
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
    alert("Please enter a valid phone number");
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
  $(document).init_live_users_search();
  $(document).init_grant_revoke_user_company_role();
  $(document).init_user_add_email();
  $(document).init_user_add_phone();
  $(document).init_user_add_password();
  $(document).init_user_update_submit();
  $(document).init_user_create_submit();
  $(document).init_clear_password();
  $(document).init_manager_reset_password();
  $(document).init_user_add_dialog();
  $(document).init_user_login_dialog();
  $(document).init_send_message_dialog();
})
