//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap-sprockets
//= require_tree .

document.addEventListener("turbolinks:load", function() {
  $('.archive').click(function() {
    loadTurbolinksArchiveURL(this, 'archive')
  });
  $('.unarchive').click(function() {
    loadTurbolinksArchiveURL(this, 'unarchive')
  });
  $('.toggle-star').click(function() {
    $(this).toggleClass("star-active star-inactive")
    $.get('/notifications/'+$(this).data('id')+'/star')
  });
  $('a.sync').on('click', function() {
    $(this).find('.octicon').toggleClass('spinning')
  });
  recoverPreviousCursorPosition()
});

document.addEventListener("turbolinks:before-cache", function() {
  $('td.current').removeClass("current");
});

// Add shortcut events only once
$(document).ready(enableKeyboardShortcuts);

$(document).on('click', '[data-toggle="offcanvas"]', function () {
  $('.row-offcanvas').toggleClass('active')
});

if(!('ontouchstart' in window))
{
  $(function () {
    $('[data-toggle="tooltip"]').tooltip()
  })
}

function enableKeyboardShortcuts() {
  window.row_index = 1

  $(document).keydown(function(e) {
    var shortcutFunction = shortcuts[e.which]
    if (shortcutFunction) { shortcutFunction(e) }
  });
}

var shortcuts = {
  74:  cursorDown,      // j
  75:  cursorUp,        // k
  83:  toggleStar,      // s
  89:  archive,         // y
  13:  openCurrentLink, // Enter
  79:  openCurrentLink, // o
  191: openModal,       // ?
  190: sync,            // .
  82:  sync             // r
}

function cursorDown() {
  current = $('td.current');
  next = $(current).parent().next();
  if(next.length > 0) {
    $(current).removeClass("current");
    $(next).find('td').first().addClass("current");
    row_index += 1;
  }
}

function cursorUp() {
  current = $('td.current');
  prev = $(current).parent().prev();
  if(prev.length > 0) {
    $(current).removeClass("current");
    $(prev).find('td').first().addClass("current");
    row_index -= 1;
  }
}

function archive() {
  clickCurrentRow('.archive')
}

function toggleStar() {
  clickCurrentRow('.toggle-star')
}

function openModal() {
  $("#help-box").modal();
}

function openCurrentLink(e) {
  e.preventDefault(e);
  $('td.current').parent().find('.link')[0].click();
}

function sync() {
  $("a.sync").click();
}

function clickCurrentRow(cssClass) {
  $('td.current').parent().find(cssClass).click();
}

function recoverPreviousCursorPosition() {
  row_index = Math.min(row_index, $(".table-notifications tr").length);
  row_index = Math.max(row_index, 1);
  $(".table-notifications tbody tr:nth-child(" + row_index + ")").first().find("td").first().addClass("current");
}

function loadTurbolinksArchiveURL(link, route) {
  Turbolinks.visit('/notifications/'+$(link).val()+'/'+route+location.search)
}
