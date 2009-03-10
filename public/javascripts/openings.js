$(document).ready(function() {
  $(document).init_highlight_timeslots();
  $(document).init_search_openings();
  
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
  
})
