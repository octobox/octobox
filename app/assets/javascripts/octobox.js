var Octobox = (function() {

  var checkSelectAll = function() {
    $(".js-select_all").click();
  };

  var getCurrentRow = function() {
    return getDisplayedRows().has("td.js-current");
  };

  var getDisplayedRows = function() {
    return $(".js-table-notifications tr.notification");
  };

  var setRowCurrent = function(row, add) {
    var classes = "current js-current";
    var td = row.find("td.notification-checkbox");
    add ? td.addClass(classes) : td.removeClass(classes);
  };

  var moveCursorToClickedRow = function(event) {
    // Don't event.preventDefault(), since we want the
    // normal clicking behavior for links, starring, etc
    var oldCurrent = getCurrentRow();
    var target = $(event.target);

    setRowCurrent(oldCurrent, false);
    setRowCurrent(target, true);
  };

  var updateFavicon = function () {
    $.get( "/notifications/unread_count", function(data) {
      if (data.count !== unread_count) {
        unread_count = data.count;

        var title = "Octobox";
        if (unread_count > 0) {
          title += " (" + unread_count + ")";
        }
        window.document.title = title;

        var old_link = document.getElementById("favicon-count");
        if ( old_link ) {
          $(old_link).remove();
        }

        var canvas = document.createElement("canvas"),
          ctx,
          img = document.createElement("img"),
          link = document.getElementById("favicon").cloneNode(true),
          txt = unread_count + "";

        link.id = "favicon-count";

        if (canvas.getContext) {
          canvas.height = canvas.width = 32;
          ctx = canvas.getContext("2d");

            img.onload = function () {
              ctx.drawImage(this, 0, 0);

              if (unread_count > 0){
                ctx.fillStyle = "#f93e00";
                ctx.font = "bold 20px 'helvetica', sans-serif";

                var width = ctx.measureText(txt).width;
                ctx.fillRect(0, 0, width+4, 24);

                ctx.fillStyle = "#fff";
                ctx.fillText(txt, 2, 20);
              }

              link.href = canvas.toDataURL("image/png");
              document.body.appendChild(link);
            };

          img.src = "/favicon-32x32.png";
        }
      }
    });
  };

  var enableTooltips = function() {
    if(!("ontouchstart" in window))
    {
      $("[data-toggle='tooltip']").tooltip();
    }
  };

  var enableKeyboardShortcuts = function() {
    // Add shortcut events only once
    if (window.row_index !== undefined) return;

    window.row_index = 1;
    window.current_id = undefined;

    $(document).keydown(function(e) {
      // disable shortcuts for the seach box
      if (e.target.id !== "search-box" && !e.ctrlKey && !e.altKey  && !e.shiftKey && !e.metaKey) {
        var shortcutFunction = shortcuts[e.which];
        if (shortcutFunction) { shortcutFunction(e) }
      }
    });
  };

  var checkAll = function() {
    var checked = $(".js-select_all").prop("checked")
    getDisplayedRows().find("input").prop("checked", checked).trigger("change");
  };

  var mute = function() {
    if (getDisplayedRows().length === 0) return;
    if ( $(".js-table-notifications tr").length === 0 ) return;
    var ids = getIdsFromRows(getMarkedOrCurrentRows());
    $.post( "/notifications/mute_selected" + location.search, { "id[]": ids}).done(function() {resetCursorAfterRowsRemoved(ids)});
  };

  var markReadSelected = function() {
    if (getDisplayedRows().length === 0) return;
    var rows = getMarkedOrCurrentRows();
    rows.addClass("blur-action");
    $.post("/notifications/mark_read_selected" + location.search, {"id[]": getIdsFromRows(rows)}).done(function () {
      rows.removeClass("blur-action")
      rows.removeClass("active");
      updateFavicon();
    })
  };

  var toggleArchive = function() {
    if (getDisplayedRows().length === 0) return;

    var cssClass, value;

    if ( $(".archive_toggle").hasClass("archive_selected") ) {
      cssClass = ".archive"
      value = true
    } else {
      cssClass = ".unarchive"
      value = false
    }

    var ids = getIdsFromRows(getMarkedOrCurrentRows());

    $.post( "/notifications/archive_selected" + location.search, { "id[]": ids, "value": value } ).done(function() {resetCursorAfterRowsRemoved(ids)});
  };

  var toggleSelectAll = function() {
    $.map($("button.select_all > span"), function( val, i ) {
      $(val).toggleClass("bold")
    });
    $("button.select_all").toggleClass("all_selected")
  };

  var refreshOnSync = function() {
    if(!$(".js-sync .octicon").hasClass("spinning")){
      $(".js-sync .octicon").addClass("spinning");
    }

    $.ajax({"url": "/notifications/syncing.json", data: {}, error: function(xhr, status) {
        setTimeout(refreshOnSync, 2000)
      }, success: function(data, status, xhr) {
        if (data["error"] != null) {
          $(".sync .octicon").removeClass("spinning");
          $(".header-flash-messages").empty();
          notify(data["error"], "danger")
        } else {
          Turbolinks.visit("/"+location.search);
        }
      }
    });
  };

  var sync = function() {
    if($("a.js-sync.js-async").length) {
      $.get("/notifications/sync.json", this.refreshOnSync);
    } else {
      Turbolinks.visit($("a.js-sync").attr("href"))
    }
  };

  var setAutoSyncTimer = function() {
    var refresh_interval = $(".js-table-notifications").data("refresh-interval");
    if (isNaN(refresh_interval)) return;
    refresh_interval > 0 && setInterval(autoSync, refresh_interval)
  };

  var recoverPreviousCursorPosition = function() {
    if ( current_id === undefined ) {
      row_index = Math.min(row_index, $(".js-table-notifications tr").length);
      row_index = Math.max(row_index, 1);
    } else {
      row_index = $("#notification-"+current_id).index() + 1;
      current_id = undefined;
    }
    $(".js-table-notifications tbody tr:nth-child(" + row_index + ")").first().find("td").first().addClass("current js-current");
  }

  var markRowCurrent = function(row) {
    // Clicking a row marks it current
    $(".current.js-current").removeClass("current js-current");
    row.find("td").first().addClass("current js-current");
  };

  var initShiftClickCheckboxes = function() {
    // handle shift+click multiple check
    var notificationCheckboxes = $("input.archive[type='checkbox']");
    notificationCheckboxes.click(function(e) {
      if(!lastCheckedNotification) {
        lastCheckedNotification = this;
        return;
      }

      if(e.shiftKey) {
        var start = notificationCheckboxes.index(this);
        var end = notificationCheckboxes.index(lastCheckedNotification);

        notificationCheckboxes.slice(Math.min(start,end), Math.max(start,end)+ 1).prop("checked", lastCheckedNotification.checked);
      }

      lastCheckedNotification = this;
    });
  };

  var toggleStarClick = function(row) {
    row.toggleClass("star-active star-inactive");
    $.post("/notifications/"+row.data("id")+"/star")
  };

  var changeArchive = function() {
    if ( hasMarkedRows() ) {
      $("button.archive_selected, button.unarchive_selected, button.mute_selected").show().css("display", "inline-block");
      if ( !hasMarkedRows(true) ) {
        $(".js-select_all").prop("checked", true).prop("indeterminate", false);
        $("button.select_all").show().css("display", "inline-block");
      } else {
        $(".js-select_all").prop("checked", false).prop("indeterminate", true);
        $("button.select_all").hide();
      }
    } else {
      $(".js-select_all").prop("checked", false).prop("indeterminate", false);
      $("button.archive_selected, button.unarchive_selected, button.mute_selected, button.select_all").hide();
    }
    var marked_unread_length = getMarkedRows().filter(".active").length;
    if ( marked_unread_length > 0 ) {
      $("button.mark_read_selected").show().css("display", "inline-block");
    } else {
      $("button.mark_read_selected").hide();
    }
  };

  var removeCurrent = function() {
    $("td.js-current").removeClass("current js-current");
  };

  var toggleOffCanvas = function() {
    $(".flex-content").toggleClass("active")
  };

  function markRead(id) {
    $.post( "/notifications/"+id+"/mark_read").done(function() {
      updateFavicon();
    });
    $("#notification-"+id).removeClass("active");
  };

  var initialize = function() {
    enableKeyboardShortcuts();
    enableTooltips();
    updateFavicon();
    initShiftClickCheckboxes()
    recoverPreviousCursorPosition();
    setAutoSyncTimer();

    // Sync Handling
    if($(".js-is_syncing").length){ refreshOnSync() }
    if($(".js-start_sync").length){ sync() }
    if($(".js-initial_sync").length){ sync() }
  };

  // private methods

  var getDisplayedRows = function() {
    return $(".js-table-notifications tr.notification")
  };

  var getMarkedRows = function(unmarked) {
    // gets all marked rows (or unmarked rows if unmarked is true)
    return unmarked ? getDisplayedRows().has("input:not(:checked)") : getDisplayedRows().has("input:checked")
  };

  var getIdsFromRows = function(rows) {
    return $("button.select_all").hasClass("all_selected") ?
      "all" : $.map(rows, function(row) {return $(row).find("input").val()})
  };

  var hasMarkedRows = function(unmarked) {
    // returns true if there are any marked rows (or unmarked rows if unmarked is true)
    return getMarkedRows(unmarked).length > 0
  };

  var getCurrentRow = function() {
    return getDisplayedRows().has("td.js-current")
  };

  var getMarkedOrCurrentRows = function() {
    return hasMarkedRows() ? getMarkedRows() : getCurrentRow()
  };

  var cursorDown = function() {
    moveCursor("up")
  };

  var cursorUp = function() {
    moveCursor("down")
  };

  var markCurrent = function() {
    getCurrentRow().find("input[type=checkbox]").click();
  };

  var resetCursorAfterRowsRemoved = function(ids) {
    var current = getCurrentRow();
    while ( $.inArray(getIdsFromRows(current)[0], ids) > -1 && current.next().length > 0) {
      current = current.next();
    }
    while ( $.inArray(getIdsFromRows(current)[0], ids) > -1 && current.prev().length > 0) {
      current = current.prev();
    }

    window.current_id = getIdsFromRows(current)[0];
    Turbolinks.visit("/"+location.search);
  };

  var toggleStar = function() {
    toggleStarClick(getCurrentRow().find(".toggle-star"))
  };

  var openModal = function() {
    $("#help-box").modal({ keyboard: false });
  };

  var openCurrentLink = function(e) {
    e.preventDefault(e);
    getCurrentRow().find("td.notification-subject .link")[0].click();
  };

  var notify = function(message, type) {
    var alert_html = [
      "<div class='alert alert-" + type + " fade show'>",
      "   <button class='close' data-dismiss='alert'>x</button>",
      message,
      "</div>"
    ].join("\n");
    $(".header-flash-messages").append(alert_html);
  };

  var autoSync = function() {
    hasMarkedRows() || sync()
  };

  var escPressed = function(e) {
    if ($("#help-box").is(":visible")) {
      $("#help-box").modal("hide");
    } else {
      clearFilters();
    }
  };

  var clearFilters = function() {
    Turbolinks.visit("/");
  };

  var scrollToCursor = function() {
    var current = $("td.js-current");
    var table_offset = $(".js-table-notifications").position().top;
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
  };

  var setRowCurrent = function(row, add) {
    var classes = "current js-current";
    var td = row.find("td.notification-checkbox");
    add ? td.addClass(classes) : td.removeClass(classes)
  };

  var moveCursor = function(upOrDown) {
    var oldCurrent = getCurrentRow();
    var target = upOrDown === "up" ? oldCurrent.next() : oldCurrent.prev();
    if(target.length > 0) {
      setRowCurrent(oldCurrent, false);
      setRowCurrent(target, true);
      scrollToCursor();
    }
  };

  var shortcuts = {
    65:  checkSelectAll,   // a
    68:  markReadSelected, // d
    74:  cursorDown,       // j
    75:  cursorUp,         // k
    83:  toggleStar,       // s
    88:  markCurrent,      // x
    89:  toggleArchive,    // y
    69:  toggleArchive,    // e
    77:  mute,             // m
    13:  openCurrentLink,  // Enter
    79:  openCurrentLink,  // o
    191: openModal,        // ?
    190: sync,             // .
    82:  sync,             // r
    27:  escPressed,       // esc
  }
  var unread_count = 0;
  var lastCheckedNotification = null;

  return {
    moveCursorToClickedRow: moveCursorToClickedRow,
    checkAll: checkAll,
    mute: mute,
    markReadSelected: markReadSelected,
    toggleArchive: toggleArchive,
    toggleSelectAll: toggleSelectAll,
    sync: sync,
    markRowCurrent: markRowCurrent,
    toggleStarClick: toggleStarClick,
    changeArchive: changeArchive,
    initialize: initialize,
    removeCurrent: removeCurrent,
    toggleOffCanvas: toggleOffCanvas,
    markRead: markRead
  }
})();
