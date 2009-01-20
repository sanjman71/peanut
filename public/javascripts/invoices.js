$(document).ready(function() {
//  $(document).init_highlight_invoice_chargeables();
  $(document).init_add_chargeables();
  $(document).init_change_chargeable_prices();

  Date.firstDayOfWeek = 7;
  Date.format = 'mm/dd/yyyy';

  $(function()
  {
    $('.date-pick').datePicker({clickInput:true, createButton:false, startDate:'01/01/2009'});
    $('#start_date').bind(
      'dpClosed',
      function(e, selectedDates)
      {
        var d = selectedDates[0];
        if (d) {
          d = new Date(d);
          $('#end_date').dpSetStartDate(d.addDays(1).asString());
        }
      }
    );
    $('#end_date').bind(
      'dpClosed',
      function(e, selectedDates)
      {
        var d = selectedDates[0];
        if (d) {
          d = new Date(d);
          $('#start_date').dpSetEndDate(d.addDays(-1).asString());
        }
      }
    );
  });
  
  $(function()
  {
    $('#show_dates').bind(
      'click',
      function() {
        $('#dates').show();
        $('#links').hide();
        return false;
      }
    );
    
    $('#show_links').bind(
      'click',
      function() {
        $('#links').show();
        $('#dates').hide();
        return false;
      }
    );
  });
  
})

// Re-bind after an ajax call
$(document).ajaxComplete(function(request, settings) {
  $(document).init_ujs_links();
//  $(document).init_highlight_invoice_chargeables();
  $(document).reset_chargeables();
  $(document).init_add_chargeables();
  $(document).init_change_chargeable_prices();
})
