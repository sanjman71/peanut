$(document).ready(function() {

  $(document).init_select_person_for_free_calendar();
  
  // set hover states to show selected date, ignore past dates
  $(".weekday:not(.past),.weekend:not(.past)").hover(
    function() {
      // highlight date
      $(this).addClass('hover');
      // show unscheduled time
      var id = $(this).attr("id");
      $("#unscheduled_" + id).removeClass('hide');
    },
    function() {
      $(this).removeClass('hover');
      // hide unscheduled time
      var id = $(this).attr("id");
      $("#unscheduled_" + id).addClass('hide');
    }
  );

  // toggle dates as they are selected, ignore past dates
  $(".weekday:not(.past),.weekend:not(.past)").click(function () {
    $(this).toggleClass('mark');
    
    if ($(this).hasClass('mark')) 
    {
      // clone template input field
      var $new_date = $("input#template").clone();
      
      // set value, id attributes
      $new_date.attr("value", $(this).attr("id"));
      $new_date.attr("id", $(this).attr("id"));
      
      // add date class
      $new_date.addClass('date');
      
      // append date object input field to free time list
      $("#dates").append($new_date);
    }
    else 
    {
      // remove date object input field
      remove_id = "input#" + $(this).attr("id")
      $("#dates").find(remove_id).remove();
    }

    // update dates selected count
    var date_count  = $(".date").length;
    var date_text   = date_count + " dates selected";
    
    if (date_count == 0) { date_text = "No dates selected" }
    if (date_count == 1) { date_text = "1 date selected" }
    
    $("#date_count").text(date_text);
  });
  

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
    // unmark all marked items
    $(this).parent().find(".mark").removeClass('mark');
    
    // mark this object
    $(this).addClass('mark');
    
    // show display time
    var display_time = $(this).text() + " " + $(this).attr("ampm");
    var display_id   = $(this).attr("display");
    $("#" + display_id).text(display_time);
  });
  
  // change the slider based on the time of day selected
  $("#start_time_of_day").change(function () {
    var time_of_day = $(this).attr("value");
    // hide all slider objects
    $("#slider_start").find(".slider").addClass('hide')
    // show the specified time of day slider
    $("#slider_start").find("#" + time_of_day).removeClass('hide')
    return false;
  })

  $("#end_time_of_day").change(function () {
    var time_of_day = $(this).attr("value");
    // hide all slider objects
    $("#slider_end").find(".slider").addClass('hide')
    // show the specified time of day slider
    $("#slider_end").find("#" + time_of_day).removeClass('hide')
    return false;
  })
  
  $("#add_free_time_form").submit(function () {
    // check for at least 1 date, and start and end times
    var date_count = $(".date").length;
    var $start_time = $("#slider_start .time.mark");
    var $end_time   = $("#slider_end .time.mark");
    
    if (date_count == 0) {
      alert("Please select at least 1 date");
      return false;
    }
    
    if ($start_time.length == 0) {
      alert("Please select a start time");
      return false;
    }

    if ($end_time.length == 0) {
      alert("Please select an end time");
      return false;
    }
    
    // set start_at and end_at values
    $("#start_at").attr("value", $start_time.attr("id"));
    $("#end_at").attr("value", $end_time.attr("id"));
    
    // remove template input field before submit
    $("input#template").remove();
    
    // ajax post
    $.post(this.action, $(this).serialize(), null, "script");
    
    return false;
  });
  
})