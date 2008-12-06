// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
jQuery.ajaxSetup({ 
  'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")}
})

//jQuery.noConflict()

$("service_id").change(function () {
  var str = "";
  $("select option:selected").each(function () {
        str += $(this).text() + " ";
      });
  $("div").text(str);
})
.change();

