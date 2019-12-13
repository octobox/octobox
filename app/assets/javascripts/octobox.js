var Octobox = (function() {

  var checkSelectAll = function() {
    $(".js-select_all").click();
  };

  var updatePinnedSearchCounts = function(pinned_search) {
    var pinned_search = $(pinned_search);
    $.get(pinned_search.data('url'), function(data) {
      pinned_search.html(data.count);
    }).fail(function() {
      pinned_search.remove(); // Remove the total value if there's an error
    });
  }

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
      setFavicon(data.count)
    });
  };

  var setFavicon = function(count) {
    if (count !== unread_count) {
      unread_count = count;

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
  }

  var enableTooltips = function() {
    if(!("ontouchstart" in window))
    {
      $("[data-toggle='tooltip']").tooltip();
    }
  };

  var enablePopOvers = function() {
    var showTimer;

    $('[data-toggle="popover"]').popover({ trigger: "manual" , html: true})
    .on("mouseenter", function () {
      if (showTimer) {
        clearTimeout(showTimer);
      }

      var _this = this;
      showTimer = setTimeout(function () {
        showTimer = undefined
        $(_this).popover("show");
        $(".popover").on("mouseleave", function () {
            $(_this).popover('hide');
        });
      }, 500);
    }).on("mouseleave", function () {
      if (showTimer) {
        clearTimeout(showTimer);
        return;
      }

      var _this = this;
      setTimeout(function () {
        if (!$(".popover:hover").length) {
          $(_this).popover("hide");
        }
      }, 300);
    });
  }

  var enableKeyboardShortcuts = function() {
    // Add shortcut events only once
    if (window.row_index !== undefined) return;

    window.row_index = 1;
    window.current_id = undefined;

    $(document).keydown(function(e) {
      // disable shortcuts for the seach and comment
      if ($("#help-box").length && !["search-box","comment_body"].includes(e.target.id)  && !e.ctrlKey && !e.metaKey) {
        var shortcutFunction = (!e.shiftKey ? shortcuts : shiftShortcuts)[e.which] ;
        if (shortcutFunction) { shortcutFunction(e) }
        return;
      }

      // escape search and comment
      if(["search-box", "comment_body"].includes(e.target.id) && e.which === 27) shortcuts[27](e);

      // post comment form on CMD-enter
      if(["comment_body"].includes(e.target.id) && (e.metaKey || e.ctrlKey) && e.which == 13) $('#reply').submit();
    });
  };

  var checkAll = function() {
    var checked = $(".js-select_all").prop("checked")
    getDisplayedRows().find("input").prop("checked", checked).trigger("change");
  };

  var muteThread = function() {
    var id = $('#notification-thread').data('id');
    mute(id);
  } ;

  var muteSelected = function() {
    if (getDisplayedRows().length === 0) return;
    if ( $(".js-table-notifications tr").length === 0 ) return;
    var ids = getIdsFromRows(getMarkedOrCurrentRows());
    mute(ids);
  };

  var mute = function(ids){
    var result = confirm("Are you sure you want to mute?");
    if (result) {
      $.post( "/notifications/mute_selected" + location.search, { "id[]": ids})
      .done(function() {
        resetCursorAfterRowsRemoved(ids);
        updateFavicon();
      })
      .fail(function(){
        notify("Could not mute notification(s)", "danger");
      });
    }
  };

  var markReadSelected = function() {
    if (getDisplayedRows().length === 0) return;
    var rows = getMarkedOrCurrentRows();
    rows.addClass("blur-action");
    $.post("/notifications/mark_read_selected" + location.search, {"id[]": getIdsFromRows(rows)})
    .done(function () {
      rows.removeClass("blur-action");
      rows.removeClass("active");
      updateFavicon();
    })
    .fail(function(){
        notify("Could not mark notification(s) read", "danger");
    });
  };

  var toggleArchive = function() {
    if ($(".archive_toggle").hasClass("archive_selected")) {
      archiveSelected()
    } else {
      unarchiveSelected()
    }
  };

  var archiveSelected = function(){
    if (getDisplayedRows().length === 0) return;
    var ids = getIdsFromRows(getMarkedOrCurrentRows());
    archive(ids, true);
  }

  var unarchiveSelected = function(){
    if (getDisplayedRows().length === 0) return;
    var ids = getIdsFromRows(getMarkedOrCurrentRows());
    archive(ids, false);
  }

  var archiveThread = function(){
    var id = $('#notification-thread').data('id');
    archive([id], true);
  }

  var unarchiveThread = function(){
    var id = $('#notification-thread').data('id');
    archive([id], false);
  }

  var archive = function(ids, value){
    $.post( "/notifications/archive_selected" + location.search, { "id[]": ids, "value": value } )
    .done(function() {
      resetCursorAfterRowsRemoved(ids);
      updateFavicon();
    })
    .fail(function(){
      notify("Could not archive notification(s)", "danger");
    });
  }

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
          notify(data["error"], "danger")
        } else {
          Turbolinks.visit("/"+location.search);
        }
      }
    });
  };

  var sync = function() {
    if($("a.js-sync.js-async").length) {
      $.get("/notifications/sync.json", refreshOnSync);
    } else {
      if(!$(".js-sync .octicon").hasClass("spinning")){
        $(".js-sync .octicon").addClass("spinning");
      }
      Turbolinks.visit($("a.js-sync").attr("href"))
      $(".sync .octicon").removeClass("spinning");
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
    var notificationCheckboxes = $(".notification-checkbox .custom-checkbox input");
    $(".notification-checkbox .custom-checkbox").click(function(e) {
      e.preventDefault();
      window.getSelection().removeAllRanges(); // remove all text selected

      if(!lastCheckedNotification) {
        // No notifications selected
        lastCheckedNotification = $(this).find("input");
        lastCheckedNotification.prop("checked", !lastCheckedNotification.prop("checked")).trigger('change');
        return;
      }

      if(e.shiftKey) {
        var start = notificationCheckboxes.index($(this).find("input"));
        var end = notificationCheckboxes.index(lastCheckedNotification);
        var selected = notificationCheckboxes.slice(Math.min(start,end), Math.max(start,end) + 1)
        selected.prop("checked", lastCheckedNotification.prop("checked")).trigger('change');
        lastCheckedNotification = $(this).find("input");
        return;
      }

      lastCheckedNotification = $(this).find("input");
      lastCheckedNotification.prop("checked", !lastCheckedNotification.prop("checked")).trigger('change');
    });
  };

  var toggleStarClick = function(row) {
    star(row.data("id"))
  };

  var star = function(id){
    $('#notification-thread').data('id') == id ? $('#thread').find('.toggle-star').toggleClass("star-active star-inactive") : null;
    $("#notification-"+id).find(".toggle-star").toggleClass("star-active star-inactive");
    $.post("/notifications/"+id+"/star")
      .fail(function(){
        $('#notification-thread').data('id') == id ? $('#thread').find('.toggle-star').toggleClass("star-active star-inactive") : null;
        $("#notification-"+id).find(".toggle-star").toggleClass("star-active star-inactive");
        notify("Could not toggle star(s)", "danger");
      });
  };

  var changeArchive = function() {
    if ( hasMarkedRows() ) {
      $("button.archive_selected, button.unarchive_selected, button.mute_selected, button.delete_selected").show().css("display", "inline-block");
      if ( !hasMarkedRows(true) ) {
        $(".js-select_all").prop("checked", true).prop("indeterminate", false);
        $("button.select_all").show().css("display", "inline-block");
      } else {
        $(".js-select_all").prop("checked", false).prop("indeterminate", true);
        $("button.select_all").hide();
      }
    } else {
      $(".js-select_all").prop("checked", false).prop("indeterminate", false);
      $("button.archive_selected, button.unarchive_selected, button.mute_selected, button.select_all, button.delete_selected").hide();
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

  var closeThread = function() {
    history.pushState({thread: $(this).attr('href')}, 'Octobox', $(this).attr('href'))
    $("#thread").addClass("d-none");
    $(".flex-main").removeClass("show-thread");
  };

  var toggleOffCanvas = function() {
    $(".flex-content").toggleClass("active");
  };

  function markRead(id) {
    $.post("/notifications/mark_read_selected" + location.search, {"id": id})
    .done(function() {
      updateFavicon();
    })
    .fail(function(){
      notify("Could not mark notification(s) read", "danger");
    });
    $("#notification-"+id).removeClass("active");
  };

  function setViewportHeight() {
    var vh = window.innerHeight * 0.01;
    document.documentElement.style.setProperty('--vh', "".concat(vh, "px"));
  };

  var initialize = function() {
    enableTooltips();
    enablePopOvers();

    setViewportHeight();
    window.addEventListener('resize', setViewportHeight);

    if ($("#help-box").length){
      enableKeyboardShortcuts();
      setFavicon($('.js-unread-count').data('count'));
      initShiftClickCheckboxes();
      recoverPreviousCursorPosition();
      setAutoSyncTimer();
    }

    // Unread counts for pinned searches
    $("span.pinned-search-count").each(function() {
      updatePinnedSearchCounts(this);
    });

    // Sync Handling
    if($(".js-is_syncing").length){ refreshOnSync() }
    if($(".js-start_sync").length){ sync() }
    if($(".js-initial_sync").length){ sync() }

    window.onpopstate = function(event) {
      if(event.state.thread){

        $('#thread').html($('#loading').html())

        $.get(event.state.thread, function(data){
          $('#thread').html(data)
        });
      }
    };
  };

  var deleteNotifications = function(ids){
    var result = confirm("Are you sure you want to delete?");
    if (result) {
      $.post("/notifications/delete_selected" + location.search, {"id[]": ids})
      .done(function() {
        resetCursorAfterRowsRemoved(ids);
        updateFavicon();
      })
      .fail(function(){
        notify("Could not delete notification", "danger");
      });
    }
  }

  var deleteSelected = function(){
    if (getDisplayedRows().length === 0) return;
    var rows = getMarkedOrCurrentRows();
    rows.addClass("blur-action");
    var ids = getIdsFromRows(rows);
    deleteNotifications(ids);
  }

  var deleteThread = function() {
    var id = $('#notification-thread').data('id');
    deleteNotifications(id);
  } ;

  var viewThread = function() {
    history.pushState({thread: $(this).attr('href')}, 'Octobox', $(this).attr('href'))

    $('#thread').html($('#loading').html())

    $.get($(this).attr('href'), function(data){
      if (data["error"] != null) {
        notify(data["error"], "danger")
      } else {
        $('#thread').html(data)
      }
    });
    $("#thread").removeClass("d-none");
    $(".flex-main").addClass("show-thread");
    $(".flex-content").removeClass("active")
    subscribeToComments();
    return false;
  }

  var expandComments = function() {
    history.pushState({thread: $(this).attr('href')}, 'Octobox', $(this).attr('href'))

    $('#more-comments').html($('#loading').html())

    $.get($(this).attr('href'), function(data){
      if (data["error"] != null) {
        notify(data["error"], "danger")
      } else {
        $('#more-comments').html(data)
      }
    });
    return false;
  }

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
    return getDisplayedRows().has("td.js-current");
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

  var nextPage = function() {
    nextPageButton = $(".page-item:last-child .page-link[rel=next]");
    if (nextPageButton.length) window.location.href = nextPageButton.attr('href');
  }

  var prevPage = function() {
    previousPageButton = $(".page-item:first-child .page-link[rel=prev]")
    if (previousPageButton.length) window.location.href = previousPageButton.attr('href');
  }

  var markCurrent = function() {
    currentRow = getCurrentRow().find("input[type=checkbox]");
    $(currentRow).prop("checked", !$(currentRow).prop("checked")).trigger('change');
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

  var focusSearchInput = function(e) {
    e.preventDefault();
    $("#search-box").focus();
  }

  var openCurrentLink = function(e) {
    e.preventDefault(e);
    getCurrentRow().find("td.notification-subject .link")[0].click();
  };

  var notify = function(message, type) {
    $(".header-flash-messages").remove();
    var alert_html = [
      "<div class='flex-header header-flash-messages'>",
      "  <div class='alert alert-" + type + " fade show'>",
      "    <button class='close' data-dismiss='alert'>x</button>",
             message,
      "  </div>",
      "</div>"
    ].join("\n");
    $(".flex-header").after(alert_html);
  };

  var autoSync = function() {
    hasMarkedRows() || sync()
  };

  var escPressed = function(e) {
    if ($("#help-box").is(":visible")) {
      $("#help-box").modal("hide");
    } else if($(".flex-main").hasClass("show-thread")){
      closeThread();
    } else if($("#search-box").is(":focus")) {
      $(".table-notifications").attr("tabindex", -1).focus();
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
    add ? td.addClass(classes) : td.removeClass(classes);
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

  // keyboard shortcuts when shift key is pressed
  var shiftShortcuts = {
    191: openModal,        // ?
  }

  var shortcuts = {
    65:  checkSelectAll,   // a
    68:  markReadSelected, // d
    74:  cursorDown,       // j
    75:  cursorUp,         // k
    78:  nextPage,         // n
    80:  prevPage,         // p
    83:  toggleStar,       // s
    88:  markCurrent,      // x
    89:  toggleArchive,    // y
    69:  toggleArchive,    // e
    77:  muteSelected,     // m
    13:  openCurrentLink,  // Enter
    79:  openCurrentLink,  // o
    191: focusSearchInput,  // /
    190: sync,             // .
    82:  sync,             // r
    27:  escPressed,       // esc
    51:  deleteSelected    // #
  }
  var unread_count = 0;
  var lastCheckedNotification = null;

  return {
    moveCursorToClickedRow: moveCursorToClickedRow,
    checkAll: checkAll,
    muteThread: muteThread,
    muteSelected: muteSelected,
    markReadSelected: markReadSelected,
    archiveSelected: archiveSelected,
    unarchiveSelected: unarchiveSelected,
    toggleSelectAll: toggleSelectAll,
    sync: sync,
    markRowCurrent: markRowCurrent,
    closeThread: closeThread,
    archiveThread: archiveThread,
    unarchiveThread: unarchiveThread,
    toggleStarClick: toggleStarClick,
    changeArchive: changeArchive,
    initialize: initialize,
    removeCurrent: removeCurrent,
    toggleOffCanvas: toggleOffCanvas,
    markRead: markRead,
    deleteSelected: deleteSelected,
    deleteThread: deleteThread,
    viewThread: viewThread,
    expandComments: expandComments
  }
})();
