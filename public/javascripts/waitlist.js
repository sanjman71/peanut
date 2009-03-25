// search waitlist for the selected schedulable
$.fn.init_select_search_waitlist_schedulable = function () {
  $("#search_schedulable").change(function () {
    var href = '/' + this.value + '/waitlist';
    window.location = href;
    return false;
  })
}

$(document).ready(function() {

  $(document).init_select_search_waitlist_schedulable();

})
