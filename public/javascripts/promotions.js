$.fn.init_promotion_create_submit = function() {
  $("input#promotion_create_submit").click(function() {
    // validate fields
    var promotion_code      = $("input#promotion_code").val();
    var promotion_uses      = $("input#promotion_uses_allowed").val();
    var promotion_discount  = $("input#promotion_discount").val();

    if (promotion_code == '') {
      alert("Please enter a promotion code");
      return false;
    }

    if (promotion_uses == '') {
      alert("Please enter a promotion uses value");
      return false;
    }

    if (promotion_discount == '') {
      alert("Please enter a promotion discount");
      return false;
    }

    return true;
  })
}

$(document).ready(function() {
  $(".datepicker").datepicker({minDate: +0, maxDate: '+6m'});
  $(document).init_promotion_create_submit();
})