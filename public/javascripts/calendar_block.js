// edit calendar for the selected provider
$.fn.init_select_calendar_new_block_provider = function () {
  $("#edit_provider").change(function () {
    var href = '/' + this.value + '/calendar/block/edit';
    window.location = href;
    return false;
  })
}

$.fn.init_select_calendar_dates = function() {
  // set hover states to show selected date, ignore past dates
  $(".weekday:not(.past),.weekend:not(.past)").hover(
    function() {
      // highlight date
      $(this).addClass('hover');
      // show free_work notes
      var id = $(this).attr("id");
      $("#free_work_" + id).show();
    },
    function() {
      $(this).removeClass('hover');
      // hide free/work notes
      var id = $(this).attr("id");
      $("#free_work_" + id).hide();
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
}

$.fn.init_timepicker = function() {
  $(".timepicker").timepickr({
      convention:12,
      select: function() {
        //alert(this.value);
      }
    });
}

$.fn.init_add_block_free_time_form = function () {
  $("#add_block_free_time_form").submit(function () {
    // check for at least 1 date, and start and end times
    var date_count  = $(".date").length;
    var start_time  = $("#start_time").attr('value');
    var end_time    = $("#end_time").attr('value');
    
    if (date_count == 0) {
      alert("Please select at least 1 date");
      return false;
    }
    
    if (!start_time) {
      alert("Please select a start time");
      return false;
    }

    if (!end_time) {
      alert("Please select an end time");
      return false;
    }
    
    // normalize time format, validate that start_at < end_at
    var start_at = convert_time_ampm_to_string(start_time)
    var end_at   = convert_time_ampm_to_string(end_time)
    
    if (!(start_at <= end_at)) {
      alert("The start time must be earlier than the end time");
      return false;
    }
    
/*    alert("start: " + start_at + " end: " + end_at);
    return false;
*/    
    // set start_at and end_at values
    $("#start_at").attr("value", start_at);
    $("#end_at").attr("value", end_at);
    
    // remove template input field before submit
    $("#start_time").remove();
    $("#end_time").remove();
    
    // ajax post
    $.post(this.action, $(this).serialize(), null, "script");
    
    // hide the submit button and show the progress bar
    $(this).find("#submit").hide();
    $(this).find("#progress").show();
    
    return false;
  });
}

$(document).ready(function() {

  $(document).init_select_calendar_new_block_provider();
  $(document).init_select_calendar_dates();
  $(document).init_timepicker();
  $(document).init_add_block_free_time_form();
})
