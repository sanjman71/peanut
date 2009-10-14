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

$(document).ready(function() {
  $(document).init_new_message();
})