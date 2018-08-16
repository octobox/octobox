//= require jquery3
//= require jquery_ujs
//= require turbolinks
//= require local-time
//= require popper
//= require bootstrap/util
//= require bootstrap/collapse
//= require bootstrap/alert
//= require bootstrap/tooltip
//= require bootstrap/dropdown
//= require bootstrap/modal
//= require_tree .

function getDisplayedRows() {
  return $(".js-table-notifications tr.notification")
}

// gets all marked rows (or unmarked rows if unmarked is true)
function getMarkedRows(unmarked) {
  return unmarked ? getDisplayedRows().has("input:not(:checked)") : getDisplayedRows().has("input:checked")
}

function getIdFromThread() {
  return [$('#notification-thread').data('id')]
}

function getIdsFromRows(rows) {
  return $('button.select_all').hasClass('all_selected') ?
    'all' : $.map(rows, function(row) {return $(row).find("input").val()})
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

function moveCursorToClickedRow(event) {
  // Don't event.preventDefault(), since we want the normal clicking behavior for links, starring, etc
  var oldCurrent = getCurrentRow();
  var target = $(this);
  setRowCurrent(oldCurrent, false);
  setRowCurrent(target, true);
}

var unread_count = 0;

function updateFavicon() {
  $.get( "/notifications/unread_count", function(data) {
    if (data["count"] !== unread_count) {
      unread_count = data["count"]

      var title = 'Octobox';
      if (unread_count > 0) {
        title += ' (' + unread_count +')';
      }
      window.document.title = title;

      var old_link = document.getElementById('favicon-count');
      if ( old_link ) {
        $(old_link).remove();
      }

      var canvas = document.createElement('canvas'),
        ctx,
        img = document.createElement('img'),
        link = document.getElementById('favicon').cloneNode(true),
        txt = unread_count + '';

      link.id = "favicon-count";

      if (canvas.getContext) {
        canvas.height = canvas.width = 32;
        ctx = canvas.getContext('2d');

          img.onload = function () {
            ctx.drawImage(this, 0, 0);

            if (unread_count > 0){
              ctx.fillStyle = '#f93e00';
              ctx.font = 'bold 20px "helvetica", sans-serif';

              var width = ctx.measureText(txt).width;
              ctx.fillRect(0, 0, width+4, 24);

              ctx.fillStyle = '#fff';
              ctx.fillText(txt, 2, 20);
            }

            link.href = canvas.toDataURL('image/png');
            document.body.appendChild(link);
          };

        img.src = "/favicon-32x32.png";
      }
    }
  });
}

document.addEventListener("turbolinks:load", function() {
  enableKeyboardShortcuts();

  if($("#help-box").length){
    $('button.archive_selected, button.unarchive_selected').click(toggleArchive);
    $('button.select_all').click(toggleSelectAll);
    $('button.mute_selected').click(mute);
    $('button.mark_read_selected').click(markReadSelected);
    $('tr.notification').click(moveCursorToClickedRow);

    $('input.archive, input.unarchive').change(function() {
      if ( hasMarkedRows() ) {
        $('button.archive_selected, button.unarchive_selected, button.mute_selected').show().css("display", "inline-block");
        if ( !hasMarkedRows(true) ) {
          $(".js-select_all").prop('checked', true).prop('indeterminate', false);
          $('button.select_all').show().css("display", "inline-block");
        } else {
          $(".js-select_all").prop('checked', false).prop('indeterminate', true);
          $('button.select_all').hide();
        }
      } else {
        $(".js-select_all").prop('checked', false).prop('indeterminate', false);
        $('button.archive_selected, button.unarchive_selected, button.mute_selected, button.select_all').hide();
      }
      var marked_unread_length = getMarkedRows().filter('.active').length;
      if ( marked_unread_length > 0 ) {
        $('button.mark_read_selected').show().css("display", "inline-block");
      } else {
        $('button.mark_read_selected').hide();
      }
    });
    $('.toggle-star').click(function() {
      $(this).toggleClass("star-active star-inactive");
      $.post('/notifications/'+$(this).data('id')+'/star')
    });
    $('a.sync').on('click', function() {
      $('.sync .octicon').toggleClass('spinning')
    });
    recoverPreviousCursorPosition();

    $('.js-select_all').change(function() {
      checkAll($(".js-select_all").prop('checked'))
    })

    if(!('ontouchstart' in window))
    {
      $('[data-toggle="tooltip"]').tooltip()
    }

    updateFavicon()
  }
});


document.addEventListener("turbolinks:before-cache", function() {
  $('td.js-current').removeClass("current js-current");
});

$(document).on('click', '[data-toggle="offcanvas"]', function () {
  $('.flex-content').toggleClass('active')
});

function enableKeyboardShortcuts() {
  // Add shortcut events only once
  if (window.row_index !== undefined) return;

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
  74:  previous,          // j
  75:  next,              // k
  83:  toggleStar,        // s
  88:  markCurrent,       // x
  89:  toggleArchive,     // y
  69:  toggleArchive,     // e
  77:  mute,              // m
  13:  openCurrentLink,   // Enter
  79:  openCurrentLink,   // o
  191: openModal,         // ?
  190: sync,              // .
  82:  sync,              // r
  27:  escPressed,        // esc
};

function previous() {
  getDisplayedRows().length ? moveCursor('up') : $('.btn.previous')[0].click();
}

function next() {
  getDisplayedRows().length ? moveCursor('down') : $('.btn.next')[0].click();
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
  var ids = getDisplayedRows().length ? getIdsFromRows(getMarkedOrCurrentRows()) : getIdFromThread();
  $.post( "/notifications/mute_selected" + location.search, { 'id[]': ids}).done(function() {resetCursorAfterRowsRemoved(ids)});
}

function markReadSelected() {
  if (getDisplayedRows().length === 0) return;
  var rows = getMarkedOrCurrentRows();
  rows.addClass('blur-action');
  $.post("/notifications/mark_read_selected" + location.search, {'id[]': getIdsFromRows(rows)}).done(function () {
    rows.removeClass('blur-action')
    rows.removeClass('active');
    updateFavicon();
  })
}

function markRead(id) {
  $.post( "/notifications/"+id+"/mark_read").done(function() {
    updateFavicon();
  });
  $('#notification-'+id).removeClass('active');
}

function toggleArchive() {
  var cssClass, value;

  if ( $(".archive_toggle").hasClass("archive_selected") ) {
    cssClass = '.archive'
    value = true
  } else {
    cssClass = '.unarchive'
    value = false
  }

  var ids = getDisplayedRows().length ? getIdsFromRows(getMarkedOrCurrentRows()) : getIdFromThread();
  $.post( "/notifications/archive_selected" + location.search, { 'id[]': ids, 'value': value } ).done(function() {resetCursorAfterRowsRemoved(ids)});
}

function toggleSelectAll() {
  $.map($('button.select_all > span'), function( val, i ) {
    $(val).toggleClass('bold')
  });
  $('button.select_all').toggleClass('all_selected')
}

function resetCursorAfterRowsRemoved(ids) {
  if(getDisplayedRows().length){
    var current = getCurrentRow();
    while ( $.inArray(getIdsFromRows(current)[0], ids) > -1 && current.next().length > 0) {
      current = current.next();
    }
    while ( $.inArray(getIdsFromRows(current)[0], ids) > -1 && current.prev().length > 0) {
      current = current.prev();
    }
    window.current_id = getIdsFromRows(current)[0];
  }
  Turbolinks.visit("/"+location.search);
}

function toggleStar() {
  getDisplayedRows().length ? getCurrentRow().find('.toggle-star').click() : $('.toggle-star')[0].click();
}

function openModal() {
  $("#help-box").modal({ keyboard: false });
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

function escPressed(e) {
  if ($("#help-box").is(':visible')) {
    $("#help-box").modal('hide');
  } else {
    clearFilters();
  }
}

function clearFilters() {
  Turbolinks.visit("/");
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

var lastCheckedNotifcation = null;
// handle shift+click multiple check
$(document).ready(function() {
  var notifcationCheckboxes = $('input.archive[type="checkbox"]');
  notifcationCheckboxes.click(function(e) {
    if(!lastCheckedNotifcation) {
      lastCheckedNotifcation = this;
      return;
    }

    if(e.shiftKey) {
      var start = notifcationCheckboxes.index(this);
      var end = notifcationCheckboxes.index(lastCheckedNotifcation);

      notifcationCheckboxes.slice(Math.min(start,end), Math.max(start,end)+ 1).prop('checked', lastCheckedNotifcation.checked);

    }

    lastCheckedNotifcation = this;
  });
});
