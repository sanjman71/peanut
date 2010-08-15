$(document).ready(function() {
  $('#calendar').fullCalendar({
    defaultView: 'month',
    header: {
              left: 'prev, next, today',
              center: 'title',
              right: 'month, agendaWeek, agendaDay'
            },
    editable: true,
    selectable: {
      agendaDay: true
    },
    selectHelper: true,
    select: function(start, end, allDay) {
      // initialize parameters, add work appointment
      current_appt_date       = $.fullCalendar.formatDate(start, "yyyyMMdd");
      current_appt_start_ampm = $.fullCalendar.formatDate(start, "hh:mm tt");
      $("a#calendar_add_work_appointment").click();
      //var title = prompt("Title");
    },
    dayClick: function(date, allDay, jsEvent, view) {
      //alert("day click: " + view.name + date);
      if (view.name == 'month' || view.name == 'agendaWeek' || view.name == 'week') {
        // change to agenda day view for the specified date
        $('#calendar').fullCalendar('changeView', 'agendaDay');
        $('#calendar').fullCalendar('gotoDate', date);
      }
    },
    eventDrop: function(event,dayDelta,minuteDelta,allDay,revertFunc) {
      //alert("event " + event.appt_id + ":" + event.appt_type + " drop - " + "day:" + dayDelta + " minute:" + minuteDelta);
      data = {"provider_id":event.provider_id, "provider_type":event.provider_type, "days":dayDelta, "minutes":minuteDelta};
      console.log(data);
      var appt_move_url = appointment_move_path.replace(/:appointment_id/, event.appt_id);
      console.log(appt_move_url)
      $.put(appt_move_url, data, function(data) { check_move_response(data, revertFunc) }, "json");
    },
    allDaySlot: false,
    events: appointments
  });

  $("select#service_id").change(function() {
    //console.log("service changed 2");
  });

  // testing
  $("#goto_date").click(function() {
    var toDate = new Date($(this).attr('date'));
    $('#calendar').fullCalendar('changeView', 'agendaDay');
    $('#calendar').fullCalendar('gotoDate', toDate);
    return false;
  })
  
  /*
  $("div.fc-view-month div.fc-day-number").click(function() {
    alert("day clicked: " + $(this).text());
    return false;
  })
  */
});

function check_move_response(data, revertFunc) {
  var status  = data.status;
  var message = data.message;
  alert(message);
  if (status == 'error') {
    revertFunc();
  }
}