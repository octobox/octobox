//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require local_time
//= require bootstrap-sprockets
//= require_tree .

document.addEventListener("turbolinks:load", function() {
  $('button.archive_selected, button.unarchive_selected').click(function () { toggleArchive(); });
  $('input.archive, input.unarchive').change(function() {
    var marked = $(".js-table-notifications input:checked");
    if ( marked.length > 0 ) {
      if ($(".js-table-notifications input").length === marked.length){
        $(".js-select_all").prop('checked', true)
      } else {
        $(".js-select_all").prop("indeterminate", true);
      }
      $('button.archive_selected, button.unarchive_selected').removeClass('hidden');
    } else {
      $(".js-select_all").prop('checked', false)
      $('button.archive_selected, button.unarchive_selected').addClass('hidden');
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

  $('.js-select_all').change(function() {
    checkAll($(".js-select_all").prop('checked'))
  })
});

document.addEventListener("turbolinks:before-cache", function() {
  $('td.js-current').removeClass("current js-current");
});

// Add shortcut events only once
$(document).ready(enableKeyboardShortcuts);

$(document).on('click', '[data-toggle="offcanvas"]', function () {
  $('.flex-content').toggleClass('active')
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
    // disable shortcuts for the seach box
    if (e.target.id !== 'search-box') {
      var shortcutFunction = shortcuts[e.which]
      if (shortcutFunction) { shortcutFunction(e) }
    }
  });
}

var shortcuts = {
  65:  checkSelectAll, // a
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
  checkbox = $('td.js-current').parent().find("input[type=checkbox]")
  checkbox.prop('checked', function (i, value) {
    return !value;
  });
  checkbox.change();
}

function checkAll(checked) {
  $(".js-table-notifications input").prop("checked", checked).trigger('change');
}

function checkSelectAll() {
  var allSelected = $(".js-select_all").prop('checked')
  $(".js-select_all").prop('checked', !allSelected).trigger('change')
}

function toggleArchive() {
  if ( $(".js-table-notifications tr").length === 0 ) return;

  var cssClass, value;

  if ( $(".archive_toggle").hasClass("archive_selected") ) {
    cssClass = '.archive'
    value = true
  } else {
    cssClass = '.unarchive'
    value = false
  }

  marked = $(".js-table-notifications input:checked");
  if ( marked.length > 0 ) {
    ids = marked.map(function() { return this.value; }).get();
  } else {
    ids = [ $('td.js-current input'+ cssClass).val() ];
  }
  $.post( "/notifications/archive_selected", { 'id[]': ids, 'value': value } ).done(function () {
    // calculating new position of the cursor
    current = $('td.js-current').parent();
    while ( $.inArray(current.find('input').val(), ids) > -1 && current.next().length > 0) {
      current = current.next();
    }
    window.current_id = current.find('input').val();
    if ( $.inArray(window.current_id, ids ) > -1 ) {
      window.current_id = $(".js-table-notifications input:not(:checked)").last().val();
    }
    Turbolinks.visit("/"+location.search);
  });
}

function toggleStar() {
  $('td.js-current').parent().find('.toggle-star').click();
}

function openModal() {
  $("#help-box").modal();
}

function openCurrentLink(e) {
  e.preventDefault(e);
  $('td.js-current').parent().find('.link')[0].click();
}

function sync() {
  $("a.sync").click();
}

function autoSync() {
  marked = $(".js-table-notifications input:checked")
  if ( marked.length === 0 ) {
    sync()
  }
}

function setAutoSyncTimer() {
  refresh_interval = $('.js-table-notifications').data('refresh-interval');
  if (isNaN(refresh_interval)) {
    return;
  }
  if (refresh_interval > 0) {
    setInterval(autoSync, refresh_interval)
  }
}

$(document).ready(setAutoSyncTimer);

function scrollToCursor() {
  var current = $('td.js-current');
  var table_offset = $('.js-table-notifications').position().top;
  var cursor_offset = current.offset().top;
  var cursor_relative_offset = current.position().top;
  var cursor_height = current.height();
  var menu_height = $(".js-octobox-menu").height();
  var scroll_top = $(document).scrollTop();
  var window_height = $(window).height();
  if ( cursor_offset < menu_height + scroll_top ) {
    $("html, body").animate({
      scrollTop: table_offset + cursor_relative_offset - cursor_height
    }, 0);
  }
  if ( cursor_offset > scroll_top + window_height - cursor_height ) {
    $("html, body").animate({
      scrollTop: cursor_offset - window_height + 2*cursor_height
    }, 0);
  }
}

function moveCursor(upOrDown) {
  var current = $('td.js-current');
  var parent = $(current).parent()
  var target = upOrDown === 'up' ? parent.next() : parent.prev()
  if(target.length > 0) {
    $(current).removeClass("current js-current");
    $(target).find('td').first().addClass("current js-current");
    row_index += upOrDown === 'up' ? 1 : -1;
    scrollToCursor();
  }
}

function recoverPreviousCursorPosition() {
  if ( current_id === undefined ) {
    row_index = Math.min(row_index, $(".js-table-notifications tr").length);
    row_index = Math.max(row_index, 1);
  } else {
    row_index = $("input[value=" + current_id + "]").parents('tr').index() + 1;
    current_id = undefined;
  }
  $(".js-table-notifications tbody tr:nth-child(" + row_index + ")").first().find("td").first().addClass("current js-current");
}

function loadTurbolinksArchiveURL(link, route) {
  Turbolinks.visit('/notifications/'+$(link).val()+'/'+route+location.search)
}

// Clicking a row marks it current
$(document).ready(function() {
  $("tr.notification").click(function() {
    $(".current.js-current").removeClass("current js-current");
    $( this ).find("td").first().addClass("current js-current");
  })
});
