var jQT = new $.jQTouch({cacheGetRequests: false, statusBar: 'black'});

// Prevent a method from being called too often
// One use is to throttle live search requests
Function.prototype.sleep = function (millisecond_delay) {
  if(window.sleep_delay != undefined) clearTimeout(window.sleep_delay);
  var function_object = this;
  window.sleep_delay  = setTimeout(function_object, millisecond_delay);
};

$.fn.init_login_submit = function() {
  $("form#login_form").submit(function() {
    // post request and handle the response
    $.ajax({
      type: $(this).attr('method'),
      url: $(this).attr('action'),
      dataType: 'json',
      data: $(this).serialize(),
      complete: function(req) {
        if (req.status == 200) {
          // click on after login lick
          $("a#after_login").click();
        } else {
          alert("There was an error logging in. Try again.");
        }
      }
    });

    return false;
  })
}

$(document).ready(function() {
  $(document).init_login_submit();
})
