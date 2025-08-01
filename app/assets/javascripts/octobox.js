var Octobox = (function() {
  
  // DOM Cache for performance
  var DOM = {
    get selectAll() { return document.querySelector(".js-select_all"); },
    get tableNotifications() { return document.querySelector(".js-table-notifications"); },
    get searchBox() { return document.getElementById("search-box"); },
    get notificationThread() { return document.querySelector('#notification-thread'); },
    get thread() { return document.getElementById('thread'); },
    get helpBox() { return document.getElementById("help-box"); },
    get syncIcon() { return document.querySelector(".js-sync .octicon"); }
  };

  var maybeConfirm = function(message){
    if(document.body.classList.contains('disable_confirmations')) {
      return true;
    } else {
      return confirm(message);
    }
  }

  var checkSelectAll = function() {
    if(DOM.selectAll) {
      DOM.selectAll.click();
    }
  };

  var updatePinnedSearchCounts = function(pinned_search) {
    fetch(pinned_search.dataset.url)
      .then(response => response.json())
      .then(data => {
        pinned_search.innerHTML = data.count;
      })
      .catch(() => {
        pinned_search.remove(); // Remove the total value if there's an error
      });
  }

  var updateAllPinnedSearchCounts = function(){
    document.querySelectorAll("span.pinned-search-count").forEach(function(element) {
      updatePinnedSearchCounts(element);
    });
  }

  var moveCursorToClickedRow = function(event) {
    // Don't event.preventDefault(), since we want the
    // normal clicking behavior for links, starring, etc
    var oldCurrent = getCurrentRow();
    var target = event.target;

    setRowCurrent(oldCurrent, false);
    setRowCurrent(target, true);
  };

  var updateFavicon = function () {
    fetch("/notifications/unread_count")
      .then(response => response.json())
      .then(data => setFavicon(data.count));
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
        old_link.parentNode.removeChild(old_link);
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
      // needs bootstrap 5 upgrade to be able to remove jquery
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
      // disable shortcuts for the search and comment
      if ($("#help-box").length && !["search-box","comment_body"].includes(e.target.id)  && !e.ctrlKey && !e.metaKey) {
        var shortcutFunction = (!e.shiftKey ? shortcuts : shiftShortcuts)[e.which] ;
        if (shortcutFunction) { shortcutFunction(e) }
        return;
      }

      // escape search and comment
      if(["search-box", "comment_body"].includes(e.target.id) && e.which === 27) shortcuts[27](e);

      // post comment form on CMD-enter
      if(["comment_body"].includes(e.target.id) && (e.metaKey || e.ctrlKey) && e.which == 13) document.getElementById('reply').submit();
    });
  };

  var checkAll = function() {
    var checked = DOM.selectAll.checked;
    getDisplayedRows().forEach(row => {
      var input = row.querySelector("input");
      if(input) {
        input.checked = checked;
        var event = new Event('change');
        input.dispatchEvent(event);
      }
    });
  };

  var muteThread = function() {
    var id = DOM.notificationThread.dataset.id;
    mute(id);
  } ;

  var muteSelected = function() {
    if (getDisplayedRows().length === 0) return;
    if ( document.querySelectorAll(".js-table-notifications tr").length === 0 ) return;
    var ids = getIdsFromRows(getMarkedOrCurrentRows());
    mute(ids);
  };

  var mute = function(ids){
    var result = maybeConfirm("Are you sure you want to mute?");
    if (result) {
      const formData = new FormData();
      if (Array.isArray(ids)) {
        ids.forEach(id => formData.append('id[]', id));
      } else {
        formData.append('id[]', ids);
      }
      
      fetch("/notifications/mute_selected" + location.search, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      .then(response => {
        if (response.ok) {
          resetCursorAfterRowsRemoved(ids);
          updateFavicon();
        } else {
          throw new Error('Request failed');
        }
      })
      .catch(() => {
        notify("Could not mute notification(s)", "danger");
      });
    }
  };

  var markReadSelected = function() {
    if (getDisplayedRows().length === 0) return;
    var rows = getMarkedOrCurrentRows();
    
    // Add blur-action class to rows
    if (Array.isArray(rows)) {
      rows.forEach(row => row.classList.add("blur-action"));
    } else {
      rows.classList.add("blur-action");
    }
    
    const formData = new FormData();
    const ids = getIdsFromRows(rows);
    ids.forEach(id => formData.append('id[]', id));
    
    fetch("/notifications/mark_read_selected" + location.search, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => {
      if (response.ok) {
        // Remove blur-action and active classes from rows
        if (Array.isArray(rows)) {
          rows.forEach(row => {
            row.classList.remove("blur-action", "active");
          });
        } else {
          rows.classList.remove("blur-action", "active");
        }
        updateFavicon();
      } else {
        throw new Error('Request failed');
      }
    })
    .catch(() => {
      notify("Could not mark notification(s) read", "danger");
    });
  };

  var toggleArchive = function() {
    if (document.querySelector(".archive_toggle").classList.contains("archive_selected")) {
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
    var id = DOM.notificationThread.dataset.id;
    archive([id], true);
  }

  var unarchiveThread = function(){
    var id = DOM.notificationThread.dataset.id;
    archive([id], false);
  }

  var archive = function(ids, value){
    const formData = new FormData();
    if (Array.isArray(ids)) {
      ids.forEach(id => formData.append('id[]', id));
    } else {
      formData.append('id[]', ids);
    }
    formData.append('value', value);
    
    fetch("/notifications/archive_selected" + location.search, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => {
      if (response.ok) {
        resetCursorAfterRowsRemoved(ids);
        updateFavicon();
      } else {
        throw new Error('Request failed');
      }
    })
    .catch(() => {
      notify("Could not archive notification(s)", "danger");
    });
  }

  var toggleSelectAll = function() {
    document.querySelectorAll("button.select_all > span").forEach(function(span) {
      span.classList.toggle("bold");
    });
    document.querySelector("button.select_all").classList.toggle("all_selected");
  };

  var refreshOnSync = function() {
    const syncIcon = document.querySelector(".js-sync .octicon");
    if(!syncIcon.classList.contains("spinning")){
      syncIcon.classList.add("spinning");
    }

    fetch("/notifications/syncing.json", {
      method: 'GET',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data["error"] != null) {
        document.querySelector(".sync .octicon").classList.remove("spinning");
        notify(data["error"], "danger");
      } else {
        Turbolinks.visit("/"+location.search);
      }
    })
    .catch(() => {
      setTimeout(refreshOnSync, 2000);
    });
  };

  var sync = function() {
    const asyncSyncLink = document.querySelector("a.js-sync.js-async");
    
    if(asyncSyncLink) {
      // AJAX sync
      fetch("/notifications/sync.json")
        .then(response => response.json())
        .then(data => refreshOnSync(data))
        .catch(error => {
          console.error('Sync failed:', error);
          notify("Sync failed", "danger");
        });
    } else {
      // Full page sync - add spinning icon then navigate
      const syncLink = document.querySelector("a.js-sync");
      const syncIcon = document.querySelector(".js-sync .octicon");
      
      if(syncIcon && !syncIcon.classList.contains("spinning")){
        syncIcon.classList.add("spinning");
      }
      
      if(syncLink) {
        // Small delay to ensure spinning class is applied before navigation
        setTimeout(() => {
          window.location.href = syncLink.getAttribute("href");
        }, 10);
      }
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
    document.querySelector(".current.js-current").classList.remove("current", "js-current");
    row.querySelector("td").classList.add("current", "js-current");
  };

  var initShiftClickCheckboxes = function() {
    // Remove any existing listeners to avoid duplicates
    document.querySelectorAll(".notification-checkbox .custom-checkbox").forEach(el => {
      el.replaceWith(el.cloneNode(true));
    });
    
    // handle shift+click multiple check
    var notificationCheckboxes = Array.from(document.querySelectorAll(".notification-checkbox .custom-checkbox input"));
    
    var checkboxContainers = document.querySelectorAll(".notification-checkbox .custom-checkbox");
    
    checkboxContainers.forEach(checkboxContainer => {
      checkboxContainer.addEventListener('click', function(e) {
        e.preventDefault();
        window.getSelection().removeAllRanges(); // remove all text selected

        var checkbox = this.querySelector("input");
        if (!checkbox) return;

        if(!lastCheckedNotification) {
          // No notifications selected
          lastCheckedNotification = checkbox;
          checkbox.checked = !checkbox.checked;
          checkbox.dispatchEvent(new Event('change'));
          Octobox.changeArchive();
          return;
        }

        if(e.shiftKey) {
          var start = notificationCheckboxes.indexOf(checkbox);
          var end = notificationCheckboxes.indexOf(lastCheckedNotification);
          var minIndex = Math.min(start, end);
          var maxIndex = Math.max(start, end);
          
          for (var i = minIndex; i <= maxIndex; i++) {
            notificationCheckboxes[i].checked = lastCheckedNotification.checked;
            notificationCheckboxes[i].dispatchEvent(new Event('change'));
          }
          lastCheckedNotification = checkbox;
          Octobox.changeArchive();
          return;
        }

        lastCheckedNotification = checkbox;
        checkbox.checked = !checkbox.checked;
        checkbox.dispatchEvent(new Event('change'));
        Octobox.changeArchive();
      });
    });
  };

  var toggleStarClick = function(row) {
    star(row.dataset.id)
  };

  var star = function(id){
    var fill_star_path = '<path fill-rule="evenodd" d="M8 .25a.75.75 0 01.673.418l1.882 3.815 4.21.612a.75.75 0 01.416 1.279l-3.046 2.97.719 4.192a.75.75 0 01-1.088.791L8 12.347l-3.766 1.98a.75.75 0 01-1.088-.79l.72-4.194L.818 6.374a.75.75 0 01.416-1.28l4.21-.611L7.327.668A.75.75 0 018 .25z"></path>'
    var empty_star_path = '<path fill-rule="evenodd" d="M8 .25a.75.75 0 01.673.418l1.882 3.815 4.21.612a.75.75 0 01.416 1.279l-3.046 2.97.719 4.192a.75.75 0 01-1.088.791L8 12.347l-3.766 1.98a.75.75 0 01-1.088-.79l.72-4.194L.818 6.374a.75.75 0 01.416-1.28l4.21-.611L7.327.668A.75.75 0 018 .25zm0 2.445L6.615 5.5a.75.75 0 01-.564.41l-3.097.45 2.24 2.184a.75.75 0 01.216.664l-.528 3.084 2.769-1.456a.75.75 0 01.698 0l2.77 1.456-.53-3.084a.75.75 0 01.216-.664l2.24-2.183-3.096-.45a.75.75 0 01-.564-.41L8 2.694v.001z"></path>'
    
    const notificationRow = document.getElementById("notification-" + id);
    let svg = null;
    let threadStar = null;
    let wasActive = false;
    
    if (notificationRow) {
      svg = notificationRow.querySelector(".toggle-star");
      if (svg) {
        wasActive = svg.classList.contains('star-active');
      }
    }
    
    // Update thread star if we're viewing this notification's thread
    if (DOM.notificationThread && DOM.notificationThread.dataset.id == id && DOM.thread) {
      threadStar = DOM.thread.querySelector('.toggle-star');
    }
    
    // Apply optimistic updates
    function toggleStar(element, toActive) {
      if (!element) return;
      
      if (toActive) {
        element.classList.remove('star-inactive');
        element.classList.add('star-active');
        element.classList.remove('octicon-star');
        element.classList.add('octicon-star-fill');
        element.innerHTML = fill_star_path;
      } else {
        element.classList.remove('star-active');
        element.classList.add('star-inactive');
        element.classList.remove('octicon-star-fill');
        element.classList.add('octicon-star');
        element.innerHTML = empty_star_path;
      }
    }
    
    // Toggle to new state
    const newActiveState = !wasActive;
    toggleStar(svg, newActiveState);
    toggleStar(threadStar, newActiveState);

    fetch("/notifications/" + id + "/star", {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
      }
    })
    .catch(() => {
      // Revert to original state on failure
      toggleStar(svg, wasActive);
      toggleStar(threadStar, wasActive);
      notify("Could not toggle star", "danger");
    });
  };

  var changeArchive = function() {
    if ( hasMarkedRows() ) {
      // Show archive buttons
      document.querySelectorAll("button.archive_selected, button.unarchive_selected, button.mute_selected, button.delete_selected").forEach(btn => {
        btn.style.display = "inline-block";
        btn.style.visibility = "visible";
        btn.removeAttribute("disabled");
        btn.classList.remove("hidden-button");
      });
      
      if ( !hasMarkedRows(true) ) {
        // All rows selected
        if (DOM.selectAll) {
          DOM.selectAll.checked = true;
          DOM.selectAll.indeterminate = false;
        }
        const selectAllBtn = document.querySelector("button.select_all");
        if (selectAllBtn) {
          selectAllBtn.style.display = "inline-block";
          selectAllBtn.style.visibility = "visible";
          selectAllBtn.removeAttribute("disabled");
        }
      } else {
        // Some rows selected
        if (DOM.selectAll) {
          DOM.selectAll.checked = false;
          DOM.selectAll.indeterminate = true;
        }
        const selectAllBtn = document.querySelector("button.select_all");
        if (selectAllBtn) {
          selectAllBtn.style.display = "none";
          selectAllBtn.style.visibility = "hidden";
          selectAllBtn.setAttribute("disabled", "disabled");
        }
      }
    } else {
      // No rows selected - hide all buttons
      if (DOM.selectAll) {
        DOM.selectAll.checked = false;
        DOM.selectAll.indeterminate = false;
      }
      document.querySelectorAll("button.archive_selected, button.unarchive_selected, button.mute_selected, button.select_all, button.delete_selected").forEach(btn => {
        btn.style.display = "none";
        btn.style.visibility = "hidden";
        btn.setAttribute("disabled", "disabled");
        btn.classList.add("hidden-button");
      });
    }
    
    var marked_unread_length = getMarkedRows().filter(row => row.classList.contains("active")).length;
    const markReadBtn = document.querySelector("button.mark_read_selected");
    if (markReadBtn) {
      if ( marked_unread_length > 0 ) {
        markReadBtn.style.display = "inline-block";
        markReadBtn.style.visibility = "visible";
        markReadBtn.removeAttribute("disabled");
      } else {
        markReadBtn.style.display = "none";
        markReadBtn.style.visibility = "hidden";
        markReadBtn.setAttribute("disabled", "disabled");
      }
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
    
    // Initialize checkbox functionality - always needed
    initShiftClickCheckboxes();

    if (document.getElementById("help-box")){
      enableKeyboardShortcuts();
      setFavicon($('.js-unread-count').data('count'));
      recoverPreviousCursorPosition();
      setAutoSyncTimer();
    }

    // Unread counts for pinned searches
    updateAllPinnedSearchCounts();

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
    var result = maybeConfirm("Are you sure you want to delete?");
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
    return document.querySelectorAll(".js-table-notifications tr.notification");
  };

  var getMarkedRows = function(unmarked) {
    // gets all marked rows (or unmarked rows if unmarked is true)
    const rows = Array.from(getDisplayedRows());
    return unmarked 
      ? rows.filter(row => !row.querySelector("input:checked"))
      : rows.filter(row => row.querySelector("input:checked"));
  };

  var getIdsFromRows = function(rows) {
    return document.querySelector("button.select_all").classList.contains("all_selected") ?
      "all" : Array.from(rows).map(function(row) {return row.querySelector("input").value})
  };

  var hasMarkedRows = function(unmarked) {
    // returns true if there are any marked rows (or unmarked rows if unmarked is true)
    return getMarkedRows(unmarked).length > 0
  };

  var getCurrentRow = function() {
    return Array.from(getDisplayedRows()).find(row => row.querySelector("td.js-current") !== null);
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
    const currentRow = getCurrentRow();
    if (currentRow) {
      const checkbox = currentRow.querySelector("input[type=checkbox]");
      if (checkbox) {
        checkbox.checked = !checkbox.checked;
        checkbox.dispatchEvent(new Event('change'));
        Octobox.changeArchive();
      }
    }
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
    const currentRow = getCurrentRow();
    if (currentRow) {
      const toggleStarElement = currentRow.querySelector(".toggle-star");
      if (toggleStarElement) {
        toggleStarClick(toggleStarElement);
      }
    }
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
    const currentRow = getCurrentRow();
    if (currentRow) {
      const link = currentRow.querySelector("td.notification-subject .link");
      if (link) {
        link.click();
      }
    }
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
    var classes = ["current", "js-current"];
    var td = row.querySelector("td.notification-checkbox");
    if (add) {
      classes.forEach(cls => td.classList.add(cls));
    } else {
      classes.forEach(cls => td.classList.remove(cls));
    }
  };

  var moveCursor = function(upOrDown) {
    var oldCurrent = getCurrentRow();
    var target = upOrDown === "up" ? oldCurrent.previousElementSibling : oldCurrent.nextElementSibling;
    if(target && target.tagName) {
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
    expandComments: expandComments,
    updateAllPinnedSearchCounts: updateAllPinnedSearchCounts
  }
})();
