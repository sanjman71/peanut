// add free time for a schedulable on a specific day
$.fn.init_add_single_free_time = function() {
  // validate the form by binding a callback to the submit function
  $("#add_single_free_time_form").validate({
    // handle form errors
    showErrors: function(errorMap, errorList) {
      // highlight blank fields, and set focus on first blank field
      $(".required:blank").addClass('highlighted');
      $(".required:blank:first").focus();
    },
    // don't validate until the form is submitted and we call valid
    onfocusout: false,
    onkeyup: false,
    onsubmit: false
  });
  
  $("#add_single_free_time_form").submit(function () {
    // reset any previous form errors beforing validating
    $(".required").removeClass('highlighted');
    if ($(this).valid()) {
      $.post(this.action, $(this).serialize(), null, "script");
      $(this).find("#submit").hide();
      $(this).find("#progress").show();
    }
    return false;
  })
}


// show appointment data (e.g. edit/delete links) on hover
$.fn.init_show_appointment_on_hover = function () {
  $(".appointment").hover(
    function () {
      $("#hover_" + this.id).show();
    },
    function () {
      $("#hover_" + this.id).hide();
    }
  )
} 

// show calendar for the selected schedulable
$.fn.init_select_calendar_show_schedulable = function () {
  $("#show_schedulable").change(function () {
    var href = '/' + this.value + '/calendar';
    window.location = href;
    return false;
  })
}

// edit calendar for the selected schedulable
$.fn.init_select_calendar_edit_schedulable = function () {
  $("#edit_schedulable").change(function () {
    var href = '/' + this.value + '/calendar/edit';
    window.location = href;
    return false;
  })
}

$(document).ready(function() {

  $(document).init_add_single_free_time();
  $(document).init_select_calendar_show_schedulable();
  $(document).init_select_calendar_edit_schedulable();
  $(document).init_show_appointment_on_hover();
  
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
  
  // bind to the 'afterClick' event, which means the user picked a time on the slider
  $(".slider .time").bind("afterClick", function() {
    // show display time based on the time picked
    var display_time = $(this).text() + " " + $(this).attr("ampm");
    var display_id   = $(this).attr("display");
    $("#" + display_id).text(display_time);
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
    
    // hide the submit button and show the progress bar
    $(this).find("#submit").hide();
    $(this).find("#progress").show();
    
    return false;
  });
  
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_select_calendar_show_schedulable();
})
