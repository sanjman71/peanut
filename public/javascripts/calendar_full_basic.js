// add appointment for a provider on a specific day
$.fn.init_full_calendar = function() {
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
      // initialize parameters, show add work appointment dialog
      current_appt.put("id", 0);
      current_appt.put("date", $.fullCalendar.formatDate(start, "yyyyMMdd"));
      current_appt.put("start_ampm", $.fullCalendar.formatDate(start, "hh:mm tt"));
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
      data = {"provider_id":event.appt_provider.split('/')[1], "provider_type":event.appt_provider.split('/')[0], "days":dayDelta, "minutes":minuteDelta};
      console.log(data);
      var appt_move_url = appointment_move_path.replace(/:appointment_id/, event.appt_id);
      console.log(appt_move_url)
      $.put(appt_move_url, data, function(data) { check_move_response(data, revertFunc) }, "json");
    },
    eventClick: function(calEvent, jsEvent, view) {
      // initialize parameters, show edit work appointment dialog
      //alert('Event: ' + calEvent.appt_id);
      current_appt.put("id", calEvent.appt_id);
      current_appt.put("mark_as", calEvent.appt_mark_as);
      current_appt.put("schedule_day", calEvent.appt_schedule_day);
      current_appt.put("start_time", calEvent.appt_start_time);
      current_appt.put("duration", calEvent.appt_duration);
      current_appt.put("service", calEvent.appt_service);
      current_appt.put("customer", calEvent.appt_customer);
      current_appt.put("customer_id", calEvent.appt_customer_id);
      current_appt.put("provider", calEvent.appt_provider);
      current_appt.put("creator", calEvent.appt_creator);
      // change the border color just for fun
      //$(this).css('border-color', 'red');
      $("a#calendar_edit_work_appointment").click();
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
}

$(document).ready(function() {
  $(document).init_full_calendar();
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