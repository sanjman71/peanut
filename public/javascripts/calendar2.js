$(document).ready(function() {
  $('#calendar').fullCalendar({
    defaultView: 'month',
    header: {
              left: 'prev, next, today',
              center: 'title',
              right: 'month, agendaWeek, agendaDay'
            },
    editable: false,
    selectable: {
      agendaDay: true
    },
    selectHelper: true,
    select: function(start, end, allDay) {
      alert("start: " + start);
      var title = prompt("Title");
    },
    dayClick: function(date, allDay, jsEvent, view) {
      //alert("day click: " + view.name + date);
      if (view.name == 'month' || view.name == 'agendaWeek' || view.name == 'week') {
        $('#calendar').fullCalendar('changeView', 'agendaDay');
        $('#calendar').fullCalendar('gotoDate', date);
      }
    },
    allDaySlot: false,
    events: appointments
  });

  $("#goto_date").click(function() {
    var toDate = new Date($(this).attr('date'));
    //alert(toDate);
    $('#calendar').fullCalendar('changeView', 'agendaDay');
    $('#calendar').fullCalendar('gotoDate', toDate);
    return false;
  })
  
  $("div.fc-view-month div.fc-day-number").click(function() {
    alert("day clicked: " + $(this).text());
    return false;
  })
});