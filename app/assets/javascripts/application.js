//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap-sprockets
//= require_tree .

document.addEventListener("turbolinks:load", function() {
  $('.unarchive').click(function() {
    Turbolinks.visit('/notifications/'+$(this).val()+'/unarchive'+location.search)
  });
  $('.toggle-star').click(function() {
    $(this).toggleClass("star-active star-inactive")
    $.get('/notifications/'+$(this).data('id')+'/star')
  });
});

// Navigation

$( document ).ready(function() {

  var row_index = 1;
  var current_id = undefined;
  
  archive = function() {
    marked = $(".table-notifications input:checked");
    if ( marked.length > 0 ) {
      ids = marked.map(function() { return this.value; }).get();
    } else {
      current_id = $('td.current input.archive').val();
      ids = [ current_id ];
    }
    $.post( "/notifications/archive_selected", { 'id[]': ids } ).done(function () {
      // calculating new position of the cursor
      current = $('td.current').parent();
      while ( $.inArray(current.find('input').val(), ids) > -1 && current.next().length > 0) {
        current = current.next();
      }
      current_id = current.find('input').val();
      if ( $.inArray(current_id, ids ) > -1 ) {
        row_index -= ids.length;
        current_id = undefined;
      } 
      Turbolinks.visit("/"+location.search);
    });
    return;
  }
  
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
      checkbox = $('td.current').parent().find("input[type=checkbox]")
      checkbox.prop('checked', function (i, value) {
        return !value;
      });
      checkbox.change();
    }
    if ( e.which == 83 ) { // s
      $('td.current').parent().find('.toggle-star').click();
    }
    if ( e.which == 89 ) { // y
      if ( $(".table-notifications tr").length == 0 ) return;
      archive();
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
    if ( current_id == undefined ) {
      row_index = Math.min(row_index, $(".table-notifications tr").length);
      row_index = Math.max(row_index, 1);
    } else {
      row_index = $("input[value=" + current_id + "]").parents('tr').index() + 1;
      current_id = undefined;
    }  
    $(".table-notifications tbody tr:nth-child(" + row_index + ")").first().find("td").first().addClass("current");

    $('button.archive_selected').click(function () { archive(); });
    
    $('input.archive').change(function() {
      marked = $(".table-notifications input:checked");
      if ( marked.length > 0 ) {
        $('button.archive_selected').show();
      } else {
        $('button.archive_selected').hide();
      }
    });
  });
});

// Navigation END

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
