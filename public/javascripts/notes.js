// Add a new note
$.fn.init_add_note = function () {
  $("#new_note").submit(function () {
    if ($("#note_comment").attr("value") == '') {
      alert("Note is empty");
      return false;
    }
    
    $.post(this.action, $(this).serialize(), null, "script");
    return false;
  })
} 

$(document).ready(function() {
  $(document).init_add_note();
})