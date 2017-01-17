//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require local_time
//= require bootstrap-sprockets
//= require_tree .

function getDisplayedRows() {
  return $(".js-table-notifications tr.notification")
}

// gets all marked rows (or unmarked rows if unmarked is true)
function getMarkedRows(unmarked) {
  return unmarked ? getDisplayedRows().has("input:not(:checked)") : getDisplayedRows().has("input:checked")
}

function getIdsFromRows(rows) {
  return $.map(rows, function(row) {return $(row).find("input").val()})
}

// returns true if there are any marked rows (or unmarked rows if unmarked is true)
function hasMarkedRows(unmarked) {
  return getMarkedRows(unmarked).length > 0
}

function getCurrentRow() {
  return getDisplayedRows().has('td.js-current')
}

function getMarkedOrCurrentRows() {
  return hasMarkedRows() ? getMarkedRows() : getCurrentRow()
}

document.addEventListener("turbolinks:load", function() {
  $('button.archive_selected, button.unarchive_selected').click(toggleArchive);
  $('button.mute_selected').click(mute);
  $('button.mark_read_selected').click(markReadSelected);

  $('input.archive, input.unarchive').change(function() {
    if ( hasMarkedRows() ) {
      var prop = hasMarkedRows(true) ? 'indeterminate' : 'checked';
      $(".js-select_all").prop(prop, true);
      $('button.archive_selected, button.unarchive_selected, button.mute_selected').removeClass('hidden');
    } else {
      $(".js-select_all").prop('checked', false);
      $('button.archive_selected, button.unarchive_selected, button.mute_selected').addClass('hidden');
    }
    var marked_unread_length = getMarkedRows().filter('.active').length;
    if ( marked_unread_length > 0 ) {
      $('button.mark_read_selected').removeClass('hidden');
    } else {
      $('button.mark_read_selected').addClass('hidden');
    }
  });
  $('.toggle-star').click(function() {
    $(this).toggleClass("star-active star-inactive");
    $.get('/notifications/'+$(this).data('id')+'/star')
  });
  $('.sync .octicon').on('click', function() {
    $(this).toggleClass('spinning')
  });
  recoverPreviousCursorPosition();

  $('.js-select_all').change(function() {
    checkAll($(".js-select_all").prop('checked'))
  })

  $('[data-toggle="tooltip"]').tooltip()
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
  window.row_index = 1;
  window.current_id = undefined;

  $(document).keydown(function(e) {
    // disable shortcuts for the seach box
    if (e.target.id !== 'search-box') {
      var shortcutFunction = shortcuts[e.which];
      if (shortcutFunction) { shortcutFunction(e) }
    }
  });
}

var shortcuts = {
  65:  checkSelectAll,    // a
  68:  markReadSelected,  // d
  74:  cursorDown,        // j
  75:  cursorUp,          // k
  83:  toggleStar,        // s
  88:  markCurrent,       // x
  89:  toggleArchive,     // y
  69:  toggleArchive,     // e
  77:  mute,              // m
  13:  openCurrentLink,   // Enter
  79:  openCurrentLink,   // o
  191: openModal,         // ?
  190: sync,              // .
  82:  sync               // r
};

function cursorDown() {
  moveCursor('up')
}

function cursorUp() {
  moveCursor('down')
}

function markCurrent() {
  getCurrentRow().find("input[type=checkbox]").click();
}

function checkAll(checked) {
  getDisplayedRows().find('input').prop("checked", checked).trigger('change');
}

function checkSelectAll() {
  $(".js-select_all").click()
}

function mute() {
  if (getDisplayedRows().length === 0) return;
  if ( $(".js-table-notifications tr").length === 0 ) return;
  var ids = getIdsFromRows(getMarkedOrCurrentRows());
  $.post( "/notifications/mute_selected", { 'id[]': ids}).done(resetCursorAfterRowsRemoved(ids));
}

function markReadSelected() {
  if (getDisplayedRows().length === 0) return;
  var rows = getMarkedOrCurrentRows();
  $.post("/notifications/mark_read_selected", {'id[]': getIdsFromRows(rows)}).done(function () {
    rows.removeClass('active');
  })
}

function markRead(id) {
  $.get( "/notifications/"+id+"/mark_read");
  $('#notification-'+id).removeClass('active');
}

function toggleArchive() {
  if (getDisplayedRows().length === 0) return;

  [cssClass, value] = $(".archive_toggle").hasClass("archive_selected") ?
    ['.archive', true] : ['.unarchive', false];

  var ids = getIdsFromRows(getMarkedOrCurrentRows());

  $.post( "/notifications/archive_selected", { 'id[]': ids, 'value': value } ).done(resetCursorAfterRowsRemoved(ids));
}

function resetCursorAfterRowsRemoved(ids) {
  var current = getCurrentRow();
  while ( $.inArray(getIdsFromRows(current)[0], ids) > -1 && current.next().length > 0) {
    current = current.next();
  }
  window.current_id = getIdsFromRows(current)[0];
  if ( $.inArray(window.current_id, ids ) > -1 ) {
    window.current_id = getIdsFromRows(getMarkedRows(true).last())[0];
  }
  Turbolinks.visit("/"+location.search);
}

function toggleStar() {
  getCurrentRow().find('.toggle-star').click();
}

function openModal() {
  $("#help-box").modal();
}

function openCurrentLink(e) {
  e.preventDefault(e);
  getCurrentRow().find('td.notification-subject .link')[0].click();
}

function sync() {
  $("a.sync").click();
}

function autoSync() {
  hasMarkedRows() || sync()
}

function setAutoSyncTimer() {
  var refresh_interval = $('.js-table-notifications').data('refresh-interval');
  if (isNaN(refresh_interval)) return;
  refresh_interval > 0 && setInterval(autoSync, refresh_interval)
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

function setRowCurrent(row, add) {
  var classes = 'current js-current';
  var td = row.find('td.notification-checkbox');
  add ? td.addClass(classes) : td.removeClass(classes)
}

function moveCursor(upOrDown) {
  var oldCurrent = getCurrentRow();
  var target = upOrDown === 'up' ? oldCurrent.next() : oldCurrent.prev();
  if(target.length > 0) {
    setRowCurrent(oldCurrent, false);
    setRowCurrent(target, true);
    scrollToCursor();
  }
}

function recoverPreviousCursorPosition() {
  if ( current_id === undefined ) {
    row_index = Math.min(row_index, $(".js-table-notifications tr").length);
    row_index = Math.max(row_index, 1);
  } else {
    row_index = $('#notification-'+current_id).index() + 1;
    current_id = undefined;
  }
  $(".js-table-notifications tbody tr:nth-child(" + row_index + ")").first().find("td").first().addClass("current js-current");
}

// Clicking a row marks it current
$(document).ready(function() {
  $("tr.notification").click(function() {
    $(".current.js-current").removeClass("current js-current");
    $( this ).find("td").first().addClass("current js-current");
  })
});
