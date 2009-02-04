$.fn.init_datepicker = function () {
  $(".datepicker").datepicker({minDate: +0});
}

// initialize links to remove a free time listing
$.fn.init_remove_links = function () {
  $("a.remove").click(function() {
    $(this).parents(".free_time").remove();
    return false;
  });
}

$.fn.init_add_free_time = function () {
  // validate the form by binding a callback to the submit function
  $("#add_free_time_form").validate({
    // handle form errors 
    showErrors: function(errorMap, errorList) {
      // highlight blank fields
      $(".required:blank").addClass('highlighted');
    },
    // don't validate until the form is submitted and we call valid
    onfocusout: false,
    onkeyup: false,
    onsubmit: false
  });
  
  // do an ajax form post on submit
  $("#add_free_time_form").submit(function () {
    if ($(this).valid()) {
      $.post(this.action, $(this).serialize(), null, "script");
      // hide the submit button and show the progress bar
      $(this).find("#submit").hide();
      $(this).find("#progress").show();
    }
    return false;
  });
}

$(document).ready(function() {
  // initialize all datepicker objects
  $(document).init_datepicker();
  $(document).init_add_free_time();
  
  $("#add_more_dates").click(function() {
    var $free_time      = $(".free_time")
    
    // clone last free_time div, increment div id
    var $new_free_time  = $free_time.slice(-1).clone();
    var new_index       = $free_time.length + 1
    
    // set new ids on new div
    $new_free_time.find(".time_range").attr("id", "time_range_" + new_index);
    $new_free_time.find("input.datepicker").attr("id", "date_" + new_index);
    $new_free_time.find("input#index").attr("value", new_index);
    $new_free_time.find(".success").attr("id", "success_" + new_index);
    $new_free_time.find(".error").attr("id", "error_" + new_index);
    $new_free_time.find(".remove").attr("id", "remove_" + new_index);
    
    // remove 'hasDatePicker' used to mark an object as having a calendar
    $new_free_time.find("input.datepicker").removeClass("hasDatepicker").removeClass('highlighted');
    
    // reset start_at, end_at values
    $new_free_time.find("input#start_at").attr("value", '').removeClass('highlighted');
    $new_free_time.find("input#end_at").attr("value", '').removeClass('highlighted');
    
    // enable 'remove' link
    $new_free_time.find("a.remove").show();
        
    // hide error, success divs
    $new_free_time.find(".success").hide();
    $new_free_time.find(".error").hide();
    
    // append object to free time list
    $("#free_time_list").append($new_free_time);
    
    // add datepickers for unbound objects
    $(document).init_datepicker();

    // initialize free time remove links
    $(document).init_remove_links();
    
    return false;
  });
  
})
