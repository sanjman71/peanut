$(document).ready(function() {
  $(document).init_highlight_invoice_chargeables();
  $(document).init_add_chargeable(); // Don't need to re-bind
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_ujs_links();
  $(document).init_highlight_invoice_chargeables();
})
