$(document).ready(function() {
//  $(document).init_highlight_invoice_chargeables();
  $(document).init_add_chargeables(); // Don't need to re-bind
  $(document).init_change_chargeable_prices();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_ujs_links();
//  $(document).init_highlight_invoice_chargeables();
  $(document).reset_chargeables();
  $(document).init_change_chargeable_prices();
})
