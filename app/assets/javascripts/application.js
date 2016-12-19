//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap
//= require_tree .

document.addEventListener("turbolinks:load", function() {
  $('.archive').click(function() {
    Turbolinks.visit('/notifications/'+$(this).val()+'/archive'+location.search)
  });
  $('.unarchive').click(function() {
    Turbolinks.visit('/notifications/'+$(this).val()+'/unarchive'+location.search)
  });
  $('.toggle-star').click(function() {
    $(this).toggleClass("fa-star fa-star-o")
    $.get('/notifications/'+$(this).data('id')+'/star')
  });

  // Set current notification for navigation
  $('.table-notifications tbody tr').first().find("td").first().addClass("current");
});

// Add key events only once

$( document ).ready(function() {
  $(document).keydown(function(e) {
    if ( e.which == 74 ) {  // j
      current = $('td.current');
      next = $(current).parent().next();
      if(next.length > 0) {
        $(current).removeClass("current");
        $(next).find('td').first().addClass("current");
      }
    }
    if ( e.which == 75 ) { // k
      current = $('td.current');
      prev = $(current).parent().prev();
      if(prev.length > 0) {
        $(current).removeClass("current");
        $(prev).find('td').first().addClass("current");
      }
    }
    if ( e.which == 83 ) { // s
      $('td.current').parent().find('.toggle-star').click();
    }
    if ( e.which == 89 ) { // y
      $('td.current').parent().find('.archive').click();
    }
    if ( e.which == 191 ) { // ?
      $("#help-box").modal();
    }
  });
});
