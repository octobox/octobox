//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap-sprockets
//= require_tree .

document.addEventListener("turbolinks:load", function() {
  $('.archive').click(function() {
    Turbolinks.visit('/notifications/'+$(this).val()+'/archive'+location.search)
  });
  $('.unarchive').click(function() {
    Turbolinks.visit('/notifications/'+$(this).val()+'/unarchive'+location.search)
  });
  $('.toggle-star').click(function() {
    $(this).toggleClass("star-active star-inactive")
    $.get('/notifications/'+$(this).data('id')+'/star')
  });
});

// Add key events only once

$( document ).ready(function() {

  var row_index = 1
  
  $(document).keydown(function(e) {
    if ( e.which == 74 ) {  // j
      current = $('td.current');
      next = $(current).parent().next();
      if(next.length > 0) {
        $(current).removeClass("current");
        $(next).find('td').first().addClass("current");
        row_index += 1;
      }
    }
    if ( e.which == 75 ) { // k
      current = $('td.current');
      prev = $(current).parent().prev();
      if(prev.length > 0) {
        $(current).removeClass("current");
        $(prev).find('td').first().addClass("current");
        row_index -= 1;
      }
    }
    if ( e.which == 88 ) { // x
      $('td.current').parent().find("input[type=checkbox]").prop('checked', function (i, value) {
        return !value;
      });
    }
    if ( e.which == 83 ) { // s
      $('td.current').parent().find('.toggle-star').click();
    }
    if ( e.which == 89 ) { // y
      if ( $(".table-notifications tr").length == 0 ) return;
      
      marked = $(".table-notifications input:checked");
      if ( marked.length > 0 ) {
        ids = marked.map(function() { return this.value; }).get();
      } else {
        current_id = $('td.current input.archive').val();
        ids = [ current_id ];
      }
      $.post( "/notifications/archive_selected", { 'id[]': ids } ).done(function () {
        row_index -= ids.length;
        Turbolinks.visit("/"+location.search);
      });
    }
    if ( e.which == 13 || e.which == 79 ) { // Enter | o
      e.preventDefault();
      $('td.current').parent().find('.link')[0].click();
    }
    if ( e.which == 191 ) { // ?
      $("#help-box").modal();
    }
    if ( e.which == 190 || e.which == 82) { // . | r
      $("a.sync").click();
    }
  });
  
  document.addEventListener("turbolinks:before-cache", function() {
    $('td.current').removeClass("current");
  });
  
  document.addEventListener("turbolinks:load", function() {
    row_index = Math.min(row_index, $(".table-notifications tr").length);
    row_index = Math.max(row_index, 1);
    $(".table-notifications tbody tr:nth-child(" + row_index + ")").first().find("td").first().addClass("current");
  });
});

$(document).on('click', '[data-toggle="offcanvas"]', function () {
  $('.row-offcanvas').toggleClass('active')
});

$(document).on('click', '.sync', function () {
  $('.sync .octicon').toggleClass('spinning')
});

if(!('ontouchstart' in window))
{
  $(function () {
    $('[data-toggle="tooltip"]').tooltip()
  })
}
