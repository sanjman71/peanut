$(document).ready(function() {

  // set default slider values
  $("#slider_start").find("#morning").removeClass('hide');
  $("#slider_end").find("#afternoon").removeClass('hide');
  
  $(".slider .time").hover(
    function() {
      $(this).addClass('highlight');
    },
    function() {
      $(this).removeClass('highlight');
    }
  );

  $(".slider .time").click(function () {
    // unmark all marked items from this and all sibling slider divs
    $(this).parents(".slider").find(".mark").removeClass('mark');
    $(this).parents(".slider").siblings(".slider").find(".mark").removeClass('mark');
    
    // mark this object
    $(this).addClass('mark');
    
    // trigger 'afterClick' event
    $(this).trigger("afterClick");
    
    return false;
  });
  
  // change the slider based on the time of day selected
  $("#start_time_of_day").change(function () {
    var time_of_day = $(this).attr("value");
    // hide all slider objects
    $("#slider_start").find(".slider").addClass('hide');
    // show the specified time of day slider
    $("#slider_start").find("#" + time_of_day).removeClass('hide');
    return false;
  })

  $("#end_time_of_day").change(function () {
    var time_of_day = $(this).attr("value");
    // hide all slider objects
    $("#slider_end").find(".slider").addClass('hide');
    // show the specified time of day slider
    $("#slider_end").find("#" + time_of_day).removeClass('hide');
    return false;
  })

})