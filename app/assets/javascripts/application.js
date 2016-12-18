//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require js.cookie
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

  if(Cookies.get('shortcuts') == "true") {
    $('.table-notifications tbody tr').first().find("td").first().addClass("current");
  }
  
  // Keyboard Shortcuts
  
  toggle_shortcuts = function() {
    enabled = Cookies.get('shortcuts');
    if (enabled == "true") {
      Cookies.set('shortcuts', false);
      $('.table-notifications td').removeClass("current");
    } else {
      Cookies.set('shortcuts', true);
      $('.table-notifications tbody tr').first().find("td").first().addClass("current");
    }
  }
  
  $('.toggle-shortcuts').click(function(e) {
    e.preventDefault();
    toggle_shortcuts();
  });
});

// Add key events only once

$( document ).ready(function() {
  
  if(Cookies.get('shortcuts') == undefined) {
    Cookies.set('shortcuts', false);
  }

  $(document).keydown(function(e) {
    if ( e.which == 74 ) {
      current = $('td.current');
      next = $(current).parent().next();
      if(next.length > 0) {
        $(current).removeClass("current");
        $(next).find('td').first().addClass("current");
      }
    }

    if ( e.which == 75 ) {
      current = $('td.current');
      prev = $(current).parent().prev();
      if(prev.length > 0) {
        $(current).removeClass("current");
        $(prev).find('td').first().addClass("current");
      }
    }

    if ( e.which == 83 ) {
      if(Cookies.get('shortcuts') == "true") {
        $('td.current').parent().find('.toggle-star').click();
      }
    }

    if ( e.which == 65 ) {
      if(Cookies.get('shortcuts') == "true") {
        $('td.current').parent().find('.archive').click();
      }
    }
  });
});
