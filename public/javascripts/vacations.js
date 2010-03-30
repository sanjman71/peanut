$.fn.init_add_vacation = function() {
  $("a#add_vacation_save").click(function() {
    var start_date = $(this).closest("div#add_vacation").find('input#start_date').val();
    var end_date   = $(this).closest("div#add_vacation").find('input#end_date').val();

    if (!start_date) {
      alert("Please enter a start date");
      return false;
    }

    if (!end_date) {
      alert("Please enter an end date");
      return false;
    }

    if (!validate_start_before_equal_end_date(start_date, end_date)) {
      alert("The start date must be before the end date");
      return false;
    }

    var start_date  = convert_date_to_string(start_date);
    var end_date    = convert_date_to_string(end_date);

    $.post(this.href, {"start_date":start_date, "end_date":end_date}, null, "script");

    // show progress
    $(this).closest("#actions").replaceWith("<img src='/images/bounce.gif'>");

    return false;
  })
  
  $("a#add_vacation").click(function() {
    $("div#add_vacation_link").addClass('hide');
    $("div#add_vacation").removeClass('hide');
    return false;
  })

  $("a#add_vacation_cancel").click(function() {
    $("div#add_vacation_link").removeClass('hide');
    $("div#add_vacation").addClass('hide');
    return false;
  })
}

$.fn.init_vacation_datepicker = function() {
  $(".vacation.datepicker").datepicker({minDate: '0m', maxDate: '+6m'});
}

$(document).ready(function() {
  $(document).init_add_vacation();
  $(document).init_vacation_datepicker();
})