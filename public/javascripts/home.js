$(document).ready(function() {
  $("#header-tabs").tabs({selected: -1, ajaxOptions: { async: null, cache: true }})

  $("#header-tabs").bind('tabsselect', function(event, ui) {
    // simple implentation that uses static array of tab elements
    site_tabs = ['companies', 'signup']
    site_href = location.href.split("/")[3];
    
    // find all tab elements
    $("li.ui-state-default").each(function(i) {
      if (site_tabs[i] == site_href) {
        $(this).addClass('ui-state-active');
      }
    })

    var url = $.data(ui.tab, 'load.tabs');
    console.debug("tab url: " + url);

    return false;
  });

  // select the first tab
  console.debug("selecting tab");
  $('#header-tabs').tabs('select', 0);
  console.debug("selected: " + $('#header-tabs').tabs('option', 'selected'));

  $("#header-tabs li a").click(function() {
    location.href = $(this).attr('url');
    return false;
  })
})