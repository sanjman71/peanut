$.fn.init_datepicker = function () {
  $(".datepicker").datepicker({minDate: +0});
}

$(document).ready(function() {
  $(document).init_datepicker();
  
  // $("#start_datepicker").each(function(index)
  // {
  //   datepicker({minDate: +0});
  // });
  //   
  // $("#end_datepicker").each(function(index)
  // {
  //   datepicker({minDate: +0});
  // });
  
  // add datepicker to all datepicker objects
  // $(".datepicker").datepicker({minDate: +0});
  
  $("#add_more_dates").click(function() {
    var $dates    = $(".date")
    
    // clone last date div, increment div id, remove class 'hasDatePicker'
    var $new_date = $dates.slice(-1).clone();
    var new_index = $dates.length + 1
    $new_date.find("input.datepicker").attr("id", "date_" + new_index);
    $new_date.find("input.datepicker").removeClass("hasDatepicker");
    $("#dates").append($new_date);
    
    // add datepickers for unbound datepicker objects
    $(document).init_datepicker();
    
    return false;
  });
  
})
