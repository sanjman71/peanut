$.fn.init_new_message = function() {
  $("a#send_message_button").click(function() {
    // validate message fields
    subject = $("input#message_subject").attr('value'); 
    body    = $("textarea#message_body").attr('value');

    if (!subject) {
      alert("Please enter a subject");
      return false;
    }

    if (!body) {
      alert("Please enter a message body");
      return false;
    }
    
    $.post($("form#new_message").attr('action'), $("form#new_message").serialize(), null, "script");
    // show progress message
    $(this).replaceWith("<h5 class='submitting' style='text-align: center;'>Sending ...</h5>");
    return false;
  })
}

$.fn.init_message_details = function() {
  // show icon on message hover
  $("div.message").hover(function () {
    $(this).find("span#message_details_icon").css('visibility', 'visible');
    }, function () {
    $(this).find("span#message_details_icon").css('visibility', 'hidden');
  })

  // get message details
  $("a.message.details").click(function() {
    url = $(this).attr('href') + ".js";
    $.get(url, {}, null, "script");
    return false;
  })
}

$(document).ready(function() {
  $(document).init_new_message();
  $(document).init_message_details();
})