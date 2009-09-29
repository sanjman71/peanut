$.fn.init_user_rpx_login = function() {
  $("iframe").load(function() {
    $("#rpx_login_loading").hide();
  });
}

$(document).ready(function() {
  $(document).init_user_rpx_login();
})
