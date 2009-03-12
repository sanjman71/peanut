// Search schedules for available appointments
$.fn.init_search_openings = function() {
  $("#search_submit").click(function() {
    // validate search inputs
    var service_id = $('#service_id').val();

    if (service_id == "0") {
      // alert the user
      alert("Please select a service");
      return false;
    }
    
    // remove duration change element if its not visible
    if (!$(".duration .change").is(":visible")) {
      $(".duration .change").remove();
    }
    
    // post the search query
    $.post($("#search_openings_form").attr("action"), $("#search_openings_form").serialize(), null, "script");

    // replace the search button with a progress image onsubmit
    $("#search_submit").hide();
    $("#search_progress").show();
    
    return false;
  })
}


$(document).ready(function() {
  $(document).init_highlight_timeslots();
  $(document).init_search_openings();
  
  // rounded corners
  $('#search_submit').corners("7px");
  
  // show sliders
  $(".pick_time").click(function () {
    var $slider = $(this).siblings(".slider");
    
    if ($slider.is(":hidden")) {
      // hide all sliders
      $(".slider").hide();
    
      // show this specific slider
      $(this).siblings(".slider").show();
    } else {
      // hide this slider
      $slider.hide();
    }

    // hide all book it divs
    $(".book_it").hide();
    
    return false;
  })
  
  // bind to the 'afterClick' event, which means the user picked a time on the slider
  $(".slider .time").bind("afterClick", function() {
    var $book_it  = $(this).parents(".appointment").find(".book_it");
    var book_time = $(this).text() + " " + $(this).attr("ampm");
    var book_url  = $book_it.find("a").attr("url").replace(/(\d+T)(\d{4,4})(\d+)/, "$1" + $(this).attr("id") + "$3");
    
    if (!$book_it.is(":visible")) {
      // hide all other book it links
      $(".book_it").hide();
      
      // show the book it link
      $book_it.show();
    }
    
    // change book it url and text
    $book_it.find("a").attr("href", book_url);
    $book_it.find("a").text("Book " + book_time);
  })
  
  // set hover states to show selected date, ignore past dates
  $(".weekday.free:not(.past),.weekend.free:not(.past)").hover(
    function() {
      // highlight date
      $(this).addClass('hover');
      
      // hide all appointment dates except this one
      $(".appointments.date").hide();
      $("#appointments_" + $(this).attr("id")).show();
    },
    function() {
      // un-highlight date
      $(this).removeClass('hover');
      // show all dates
      $(".appointments.date").show();
    }
  );
  
})
