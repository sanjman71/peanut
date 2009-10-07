$(document).ready(function() {
//  $(document).init_highlight_invoice_chargeables();
  $(document).init_add_chargeables();
  $(document).init_change_chargeable_prices();

  Date.firstDayOfWeek = 7;
  Date.format = 'mm/dd/yyyy';

  $(document).init_datepicker({start_date : (new Date()).addMonths(-3).asString(), end_date : (new Date()).addDays(1).asString(), max_days:6});
  $(document).init_toggle_dates();
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
//  $(document).init_highlight_invoice_chargeables();
  $(document).reset_chargeables();
  $(document).init_add_chargeables();
  $(document).init_change_chargeable_prices();
})
