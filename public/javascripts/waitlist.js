// search waitlist for the selected provider
$.fn.init_select_search_waitlist_provider = function () {
  $("#search_provider").change(function () {
    var href = '/' + this.value + '/waitlist';
    window.location = href;
    return false;
  })
}

$(document).ready(function() {

  $(document).init_select_search_waitlist_provider();

})
