// edit calendar for the selected provider
$.fn.init_select_calendar_new_block_provider = function () {
  $("#edit_provider").change(function () {
    var href = '/' + this.value + '/calendar/block/new';
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
      var $new_date = $("input#date_template").clone();

      // set value, id attributes
      $new_date.attr("value", $(this).attr("id"));
      $new_date.attr("id", $(this).attr("id"));

      // add date class
      $new_date.addClass('date');

      // append date object input field to free time list
      $("div#dates").append($new_date);
    }
    else 
    {
      // remove date object input field
      remove_id = "input#" + $(this).attr("id")
      $("div#dates").find(remove_id).remove();
    }

    // update dates selected count
    var date_count  = $(".date").length;
    var date_text   = date_count + " dates selected";

    if (date_count == 0) { date_text = "No dates selected" }
    if (date_count == 1) { date_text = "1 date selected" }

    $("#date_count").text(date_text);
  });
}

$.fn.init_timepicker_block = function() {
  $(".timepicker").timepickr({
      convention:12,
      select: function() {
        //alert(this.value);
      }
    });
}

$.fn.init_add_block_free_time_form = function () {
  $("form#add_block_free_time_form").submit(function () {
    // check for at least 1 date, and start and end times
    var date_count  = $(".date").length;
    var start_at    = $("#start_at").attr('value');
    var end_at      = $("#end_at").attr('value');
    
    if (date_count == 0) {
      alert("Please select at least 1 date");
      return false;
    }
    
    if (!start_at) {
      alert("Please select a start time");
      return false;
    }

    if (!end_at) {
      alert("Please select an end time");
      return false;
    }
    
    // normalize time format, validate that start_at < end_at
    var start_at = convert_time_ampm_to_string(start_at)
    var end_at   = convert_time_ampm_to_string(end_at)
    
    if (!(start_at <= end_at)) {
      alert("The start time must be earlier than the end time");
      return false;
    }
    
    // replace start_at and end_at values
    $("#start_at").attr("value", start_at);
    $("#end_at").attr("value", end_at);
    
    // remove template input fields before the submit
    $("input#date_template").remove();
    
    // ajax post
    $.post(this.action, $(this).serialize(), null, "script");
    
    // show progress indicator
    $("#submit_wrapper").replaceWith("<h3 class='submitting' style='text-align: center;'>Adding ...</h3>");
    
    return false;
  });
}

$(document).ready(function() {
  $(document).init_select_calendar_new_block_provider();
  $(document).init_select_calendar_dates();
  $(document).init_timepicker_block();
  $(document).init_add_block_free_time_form();
})
