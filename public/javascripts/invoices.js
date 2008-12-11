$(document).ready(function() {
  $(document).init_highlight_invoice_chargeables();
  $(document).init_add_chargeable();

  // Re-initialize after an ajax update
  $("#add_chargeable").ajaxComplete(function(request, settings){
    $(document).init_ujs_links();
    $(document).init_highlight_invoice_chargeables();
    $(document).init_add_chargeable();
  })
})