// build date time string from date, time args
// date => 20100101
// time => 183000
function build_date_time_string(date, time) {
  // parseDate returns a string with format: 'Mon Jan 25 2010 00:00:00: GMT-0600 (CST)
  var date  = $.datepicker.parseDate('yymmdd', date).toString();
  // keep the day of week and date part
  var date  = date.match(/^(\w{3,3} \w{3,3} \d{2,2} \d{4,4})/)[1]
  // convert military time to ampm time
  var time  = convert_time_military_to_ampm_string(time);

  var dt    = date + " @ " + time;
  return dt;
}

// convert mm/dd/yyyy date to yyyymmdd string
function convert_date_to_string(s) {
  re    = /(\d{2,2})\/(\d{2,2})\/(\d{4,4})/
  match = s.match(re);
  if (!match) {
    s = ''
  } else {
    s = match[3] + match[1] + match[2]
  }
  return s
}

// convert yyyymmdd string to mm/dd/yyyy
function convert_yymmdd_string_to_mmddyy(s) {
  re    = /(\d{4,4})(\d{2,2})(\d{2,2})/
  match = s.match(re);
  if (!match) {
    s = ''
  } else {
    s = match[2] + '/' + match[3] + '/' + match[1]
  }
  return s
}

// convert ['03:00 pm', '3:00pm'] time format to 'hhmmss' 24 hour time format
function convert_time_ampm_to_string(s) {
  re      = /(\d{1,2}):{0,1}(\d{2,2})\s{0,1}(am|pm)/
  match   = s.toLowerCase().match(re);

  // convert hour to integer, leave minute as string
  hour    = parseInt(match[1], 10); 
  minute  = match[2];
  ampm    = match[3]

  if (ampm == 'pm' && hour != 12) {
    // add 12 for pm, unless hour == 12
    hour += 12;
  }

  value = hour < 10 ? "0" + hour.toString() : hour.toString()
  value += minute + "00";
  return value;
}

// convert '150000' time format to '3 pm' 12 hour time format
function convert_time_military_to_ampm_string(s) {
  re      = /(\d{2,2})(\d{2,2})(\d{2,2})/
  match   = s.match(re);

  // convert hour to integer
  hour    = parseInt(match[1], 10);
  minute  = match[2]

  // adjust hour and set ampm
  hour    = (hour < 12) ? hour : hour-12
  ampm    = (hour < 12) ? 'am' : 'pm'

  value   = hour.toString();
  value   += ":" + minute + " " + ampm;
  return value;
}

function validate_email_address(email_address) {
  var email_regex = /^[a-zA-Z0-9\+._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$/;
  if (email_regex.test(email_address) == false) { return false; }
  return true;
}

function validate_phone_number(phone_number) {
  // strip out valid non-digits from phone number
  var phone_digits = phone_number.replace(/[ ()-.]/g, '');
  // check that we only have digits remaining
  var phone_regex  = /^[0-9]+$/;
  if (phone_regex.test(phone_digits) == false) { return false; }
  return true;
}

// returns true if the start date is < the end date
// start_date => e.g. 01/01/2010
// end_date => e.g. 02/01/2010
function validate_start_before_end_date(start_date, end_date) {
  start_date = new Date(start_date);
  end_date   = new Date(end_date);
  return ((start_date < end_date) ? true : false);
}

function validate_start_before_equal_end_date(start_date, end_date) {
  start_date = new Date(start_date);
  end_date   = new Date(end_date);
  return ((start_date <= end_date) ? true : false);
}
