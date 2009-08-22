$(document).ready(function() {
  // initialize tabs with no tab selected
  $("#tabs").tabs({selected: -1, ajaxOptions: { async: null, cache: true }})

  // bind the tab select event
  $("#tabs").bind('tabsselect', function(event, ui) {
    // find 'current' tab elements
    $("li.ui-state-default.current").each(function(i) {
      $(this).addClass('ui-state-active');
    })

    return false;
  });

  // select any tab to fire the 'tabselect' event
  $('#tabs').tabs('select', 0);

  // handle tab click
  $("#tabs li a").click(function() {
    location.href = $(this).attr('url');
    return false;
  })
})