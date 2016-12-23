//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require bootstrap-sprockets
//= require_tree .

document.addEventListener("turbolinks:load", function() {
  $('button.archive_selected, button.unarchive_selected').click(function () { toggleArchive(); });
  $('input.archive, input.unarchive').change(function() {
    marked = $(".table-notifications input:checked");
    if ( marked.length > 0 ) {
      $('button.archive_selected, button.unarchive_selected').show();
    } else {
      $('button.archive_selected, button.unarchive_selected').hide();
    }
  });
  $('.toggle-star').click(function() {
    $(this).toggleClass("star-active star-inactive")
    $.get('/notifications/'+$(this).data('id')+'/star')
  });
  $('.sync .octicon').on('click', function() {
    $(this).toggleClass('spinning')
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
  window.current_id = undefined

  $(document).keydown(function(e) {
    var shortcutFunction = shortcuts[e.which]
    if (shortcutFunction) { shortcutFunction(e) }
  });
}

var shortcuts = {
  74:  cursorDown,      // j
  75:  cursorUp,        // k
  83:  toggleStar,      // s
  88:  markCurrent,     // x
  89:  toggleArchive,   // y
  13:  openCurrentLink, // Enter
  79:  openCurrentLink, // o
  191: openModal,       // ?
  190: sync,            // .
  82:  sync             // r
}

function cursorDown() {
  moveCursor('up')
}

function cursorUp() {
  moveCursor('down')
}

function markCurrent() {
  checkbox = $('td.current').parent().find("input[type=checkbox]")
  checkbox.prop('checked', function (i, value) {
    return !value;
  });
  checkbox.change();
}

function toggleArchive() {
  if ( $(".table-notifications tr").length == 0 ) return;

  var cssClass, value;
  
  if ( $(".archive_toggle").hasClass("archive_selected") ) {
    cssClass = '.archive'
    value = true
  } else {
    cssClass = '.unarchive'
    value = false
  }

  marked = $(".table-notifications input:checked");
  if ( marked.length > 0 ) {
    ids = marked.map(function() { return this.value; }).get();
  } else {
    ids = [ $('td.current input'+ cssClass).val() ];
  }
  $.post( "/notifications/archive_selected", { 'id[]': ids, 'value': value } ).done(function () {
    // calculating new position of the cursor
    current = $('td.current').parent();
    while ( $.inArray(current.find('input').val(), ids) > -1 && current.next().length > 0) {
      current = current.next();
    }
    window.current_id = current.find('input').val();
    if ( $.inArray(window.current_id, ids ) > -1 ) {
      window.current_id = $(".table-notifications input:not(:checked)").last().val();
    } 
    Turbolinks.visit("/"+location.search);
  });
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

function moveCursor(upOrDown) {
  var current = $('td.current');
  var parent = $(current).parent()
  var target = upOrDown === 'up' ? parent.next() : parent.prev()
  if(target.length > 0) {
    $(current).removeClass("current");
    $(target).find('td').first().addClass("current");
    row_index += upOrDown === 'up' ? 1 : -1;
  }
}

function recoverPreviousCursorPosition() {
  if ( current_id == undefined ) {
    row_index = Math.min(row_index, $(".table-notifications tr").length);
    row_index = Math.max(row_index, 1);
  } else {
    row_index = $("input[value=" + current_id + "]").parents('tr').index() + 1;
    current_id = undefined;
  }
  $(".table-notifications tbody tr:nth-child(" + row_index + ")").first().find("td").first().addClass("current");
}

function loadTurbolinksArchiveURL(link, route) {
  Turbolinks.visit('/notifications/'+$(link).val()+'/'+route+location.search)
}
