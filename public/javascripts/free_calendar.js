$(document).ready(function() {

  // set hover states to show selected date
  $(".weekday,.weekend").hover(
    function() {
      $(this).addClass('hover');
    },
    function() {
      $(this).removeClass('hover');
    }
  );
  
  // toggle dates as they are selected/un-selected
  $(".weekday,.weekend").click(function () {
    $(this).toggleClass('mark');
    
    if ($(this).hasClass('mark')) 
    {
      // add input field
      
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

    // update running tally of date objects
    var date_count = $(".date").length;
    $("#date_count").text(date_count + " dates selected");
  });
  
  $("#add_free_time_form").submit(function () {
    // if ($(this).valid()) {
      // remove template input field before submit
      $("input#template").remove();
      // ajax post
      $.post(this.action, $(this).serialize(), null, "script");
      // hide the submit button and show the progress bar
      // $(this).find("#submit").hide();
      // $(this).find("#progress").show();
    // }
    return false;
  });
  
})