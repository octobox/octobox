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

  var getCsrfToken = function() {
    var meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute('content') : '';
  };

  var postRequest = function(url, formData) {
    return fetch(url, {
      method: 'POST',
      body: formData,
      headers: { 'X-CSRF-Token': getCsrfToken(), 'X-Requested-With': 'XMLHttpRequest' }
    });
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
        pinned_search.remove();
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
      document.querySelectorAll('[data-bs-toggle="tooltip"]').forEach(function(el) {
        new bootstrap.Tooltip(el);
      });
    }
  };

  var enablePopOvers = function() {
    var showTimer;

    document.querySelectorAll('[data-bs-toggle="popover"]').forEach(function(el) {
      var popover = new bootstrap.Popover(el, { trigger: "manual", html: true });

      el.addEventListener("mouseenter", function() {
        if (showTimer) {
          clearTimeout(showTimer);
        }

        var _this = this;
        showTimer = setTimeout(function() {
          showTimer = undefined;
          popover.show();
          var popoverEl = document.querySelector(".popover");
          if (popoverEl) {
            popoverEl.addEventListener("mouseleave", function() {
              popover.hide();
            });
          }
        }, 500);
      });

      el.addEventListener("mouseleave", function() {
        if (showTimer) {
          clearTimeout(showTimer);
          return;
        }

        setTimeout(function() {
          if (!document.querySelector(".popover:hover")) {
            popover.hide();
          }
        }, 300);
      });
    });
  }

  var enableKeyboardShortcuts = function() {
    // Add shortcut events only once
    if (window.row_index !== undefined) return;

    window.row_index = 1;
    window.current_id = undefined;

    document.addEventListener('keydown', function(e) {
      // disable shortcuts for the search and comment
      var helpBox = document.getElementById("help-box");
      if (helpBox && !["search-box","comment_body"].includes(e.target.id) && !e.ctrlKey && !e.metaKey) {
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
      var formData = new FormData();
      if (Array.isArray(ids)) {
        ids.forEach(id => formData.append('id[]', id));
      } else {
        formData.append('id[]', ids);
      }

      postRequest("/notifications/mute_selected" + location.search, formData)
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
    if (rows.length === 0) return;

    rows.forEach(row => row.classList.add("blur-action"));

    var formData = new FormData();
    var ids = getIdsFromRows(rows);
    if (Array.isArray(ids)) {
      ids.forEach(id => formData.append('id[]', id));
    } else {
      formData.append('id[]', ids);
    }

    postRequest("/notifications/mark_read_selected" + location.search, formData)
    .then(response => {
      if (response.ok) {
        rows.forEach(row => row.classList.remove("blur-action", "active"));
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
    var formData = new FormData();
    if (Array.isArray(ids)) {
      ids.forEach(id => formData.append('id[]', id));
    } else {
      formData.append('id[]', ids);
    }
    formData.append('value', value);

    postRequest("/notifications/archive_selected" + location.search, formData)
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
    var syncIcon = document.querySelector(".js-sync .octicon");
    if(syncIcon && !syncIcon.classList.contains("spinning")){
      syncIcon.classList.add("spinning");
    }

    fetch("/notifications/syncing.json")
    .then(response => response.json())
    .then(data => {
      if (data["error"] != null) {
        var icon = document.querySelector(".sync .octicon");
        if (icon) icon.classList.remove("spinning");
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
    var asyncSyncLink = document.querySelector("a.js-sync.js-async");

    if(asyncSyncLink) {
      fetch("/notifications/sync.json")
        .then(response => response.json())
        .then(data => refreshOnSync(data))
        .catch(error => {
          console.error('Sync failed:', error);
          notify("Sync failed", "danger");
        });
    } else {
      var syncLink = document.querySelector("a.js-sync");
      var syncIcon = document.querySelector(".js-sync .octicon");

      if(syncIcon && !syncIcon.classList.contains("spinning")){
        syncIcon.classList.add("spinning");
      }

      if(syncLink) {
        setTimeout(() => {
          window.location.href = syncLink.getAttribute("href");
        }, 10);
      }
    }
  };

  var setAutoSyncTimer = function() {
    var table = document.querySelector(".js-table-notifications");
    if (!table) return;
    var refresh_interval = parseInt(table.dataset.refreshInterval, 10);
    if (isNaN(refresh_interval)) return;
    refresh_interval > 0 && setInterval(autoSync, refresh_interval)
  };

  var recoverPreviousCursorPosition = function() {
    var rows = document.querySelectorAll(".js-table-notifications tr");
    if ( current_id === undefined ) {
      row_index = Math.min(row_index, rows.length);
      row_index = Math.max(row_index, 1);
    } else {
      var el = document.getElementById("notification-" + current_id);
      if (el) {
        row_index = Array.from(el.parentNode.children).indexOf(el) + 1;
      }
      current_id = undefined;
    }
    var targetRow = document.querySelector(".js-table-notifications tbody tr:nth-child(" + row_index + ")");
    if (targetRow) {
      var td = targetRow.querySelector("td");
      if (td) td.classList.add("current", "js-current");
    }
  }

  var markRowCurrent = function(row) {
    // Clicking a row marks it current
    var existing = document.querySelector(".current.js-current");
    if (existing) existing.classList.remove("current", "js-current");
    var td = row.querySelector("td");
    if (td) td.classList.add("current", "js-current");
  };

  var initShiftClickCheckboxes = function() {
    // Remove any existing listeners to avoid duplicates
    document.querySelectorAll(".notification-checkbox .form-check").forEach(el => {
      el.replaceWith(el.cloneNode(true));
    });

    // handle shift+click multiple check
    var notificationCheckboxes = Array.from(document.querySelectorAll(".notification-checkbox .form-check input"));

    var checkboxContainers = document.querySelectorAll(".notification-checkbox .form-check");

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

    var notificationRow = document.getElementById("notification-" + id);
    var svg = null;
    var threadStar = null;
    var wasActive = false;

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
    var newActiveState = !wasActive;
    toggleStar(svg, newActiveState);
    toggleStar(threadStar, newActiveState);

    fetch("/notifications/" + id + "/star", {
      method: 'POST',
      headers: {
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': getCsrfToken()
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
        var selectAllBtn = document.querySelector("button.select_all");
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
        var selectAllBtn = document.querySelector("button.select_all");
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
    var markReadBtn = document.querySelector("button.mark_read_selected");
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
    var current = document.querySelector("td.js-current");
    if (current) current.classList.remove("current", "js-current");
  };

  var closeThread = function(link) {
    var href = link ? link.getAttribute('href') : '/';
    history.pushState({thread: href}, 'Octobox', href);
    var thread = document.getElementById("thread");
    if (thread) thread.classList.add("d-none");
    var flexMain = document.querySelector(".flex-main");
    if (flexMain) flexMain.classList.remove("show-thread");
  };

  var toggleOffCanvas = function() {
    var flexContent = document.querySelector(".flex-content");
    if (flexContent) flexContent.classList.toggle("active");
  };

  function markRead(id) {
    var formData = new FormData();
    formData.append('id[]', id);
    postRequest("/notifications/mark_read_selected" + location.search, formData)
    .then(response => {
      if (response.ok) updateFavicon();
    })
    .catch(() => {
      notify("Could not mark notification(s) read", "danger");
    });
    var row = document.getElementById("notification-" + id);
    if (row) row.classList.remove("active");
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
      var unreadCount = document.querySelector('.js-unread-count');
      setFavicon(unreadCount ? parseInt(unreadCount.dataset.count, 10) || 0 : 0);
      recoverPreviousCursorPosition();
      setAutoSyncTimer();
    }

    // Unread counts for pinned searches
    updateAllPinnedSearchCounts();

    // Sync Handling
    if(document.querySelector(".js-is_syncing")){ refreshOnSync() }
    if(document.querySelector(".js-start_sync")){ sync() }
    if(document.querySelector(".js-initial_sync")){ sync() }

    window.onpopstate = function(event) {
      if(event.state && event.state.thread){
        var thread = document.getElementById('thread');
        var loading = document.getElementById('loading');
        if (thread && loading) thread.innerHTML = loading.innerHTML;

        fetch(event.state.thread, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
          .then(response => response.text())
          .then(data => {
            var thread = document.getElementById('thread');
            if (thread) thread.innerHTML = data;
          });
      }
    };
  };

  var deleteNotifications = function(ids){
    var result = maybeConfirm("Are you sure you want to delete?");
    if (result) {
      var formData = new FormData();
      if (Array.isArray(ids)) {
        ids.forEach(id => formData.append('id[]', id));
      } else {
        formData.append('id[]', ids);
      }

      postRequest("/notifications/delete_selected" + location.search, formData)
      .then(response => {
        if (response.ok) {
          resetCursorAfterRowsRemoved(ids);
          updateFavicon();
        } else {
          throw new Error('Request failed');
        }
      })
      .catch(() => {
        notify("Could not delete notification", "danger");
      });
    }
  }

  var deleteSelected = function(){
    if (getDisplayedRows().length === 0) return;
    var rows = getMarkedOrCurrentRows();
    rows.forEach(row => row.classList.add("blur-action"));
    var ids = getIdsFromRows(rows);
    deleteNotifications(ids);
  }

  var deleteThread = function() {
    var thread = document.querySelector('#notification-thread');
    if (thread) {
      var id = thread.dataset.id;
      deleteNotifications(id);
    }
  } ;

  var viewThread = function(e) {
    e.preventDefault();
    var link = e.target.closest('.thread-link');
    if (!link) return;
    var href = link.getAttribute('href');

    history.pushState({thread: href}, 'Octobox', href);

    var thread = document.getElementById('thread');
    var loading = document.getElementById('loading');
    if (thread && loading) thread.innerHTML = loading.innerHTML;

    fetch(href, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
      .then(response => {
        var contentType = response.headers.get('content-type') || '';
        return contentType.includes('json') ? response.json() : response.text();
      })
      .then(data => {
        if (typeof data === 'object' && data.error) {
          notify(data.error, "danger");
        } else {
          var thread = document.getElementById('thread');
          if (thread) thread.innerHTML = data;
        }
      });

    var threadEl = document.getElementById("thread");
    if (threadEl) threadEl.classList.remove("d-none");
    var flexMain = document.querySelector(".flex-main");
    if (flexMain) flexMain.classList.add("show-thread");
    var flexContent = document.querySelector(".flex-content");
    if (flexContent) flexContent.classList.remove("active");
    subscribeToComments();
    return false;
  }

  var expandComments = function(e) {
    e.preventDefault();
    var link = e.target.closest('.expand-comments');
    if (!link) return;
    var href = link.getAttribute('href');

    history.pushState({thread: href}, 'Octobox', href);

    var moreComments = document.getElementById('more-comments');
    var loading = document.getElementById('loading');
    if (moreComments && loading) moreComments.innerHTML = loading.innerHTML;

    fetch(href, { headers: { 'X-Requested-With': 'XMLHttpRequest' } })
      .then(response => {
        var contentType = response.headers.get('content-type') || '';
        return contentType.includes('json') ? response.json() : response.text();
      })
      .then(data => {
        if (typeof data === 'object' && data.error) {
          notify(data.error, "danger");
        } else {
          var moreComments = document.getElementById('more-comments');
          if (moreComments) moreComments.innerHTML = data;
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
    var rows = Array.from(getDisplayedRows());
    return unmarked
      ? rows.filter(row => !row.querySelector("input:checked"))
      : rows.filter(row => row.querySelector("input:checked"));
  };

  var getIdsFromRows = function(rows) {
    var selectAllBtn = document.querySelector("button.select_all");
    if (selectAllBtn && selectAllBtn.classList.contains("all_selected")) return "all";
    return Array.from(rows).map(function(row) { return row.querySelector("input").value; });
  };

  var hasMarkedRows = function(unmarked) {
    // returns true if there are any marked rows (or unmarked rows if unmarked is true)
    return getMarkedRows(unmarked).length > 0
  };

  var getCurrentRow = function() {
    return Array.from(getDisplayedRows()).find(row => row.querySelector("td.js-current") !== null);
  };

  var getMarkedOrCurrentRows = function() {
    if (hasMarkedRows()) return getMarkedRows();
    var current = getCurrentRow();
    return current ? [current] : [];
  };

  var cursorDown = function() {
    moveCursor("down")
  };

  var cursorUp = function() {
    moveCursor("up")
  };

  var nextPage = function() {
    var nextBtn = document.querySelector(".page-item:last-child .page-link[rel=next]");
    if (nextBtn) window.location.href = nextBtn.getAttribute('href');
  }

  var prevPage = function() {
    var prevBtn = document.querySelector(".page-item:first-child .page-link[rel=prev]");
    if (prevBtn) window.location.href = prevBtn.getAttribute('href');
  }

  var markCurrent = function() {
    var currentRow = getCurrentRow();
    if (currentRow) {
      var checkbox = currentRow.querySelector("input[type=checkbox]");
      if (checkbox) {
        checkbox.checked = !checkbox.checked;
        checkbox.dispatchEvent(new Event('change'));
        Octobox.changeArchive();
      }
    }
  };

  var resetCursorAfterRowsRemoved = function(ids) {
    var current = getCurrentRow();
    if (!current) {
      Turbolinks.visit("/" + location.search);
      return;
    }
    var idsArray = Array.isArray(ids) ? ids : [ids];

    while (idsArray.indexOf(getIdsFromRows([current])[0]) > -1 && current.nextElementSibling) {
      current = current.nextElementSibling;
    }
    while (idsArray.indexOf(getIdsFromRows([current])[0]) > -1 && current.previousElementSibling) {
      current = current.previousElementSibling;
    }

    window.current_id = getIdsFromRows([current])[0];
    Turbolinks.visit("/" + location.search);
  };

  var toggleStar = function() {
    var currentRow = getCurrentRow();
    if (currentRow) {
      var toggleStarElement = currentRow.querySelector(".toggle-star");
      if (toggleStarElement) {
        toggleStarClick(toggleStarElement);
      }
    }
  };

  var openModal = function() {
    var helpBox = document.getElementById("help-box");
    if (helpBox) {
      var modal = bootstrap.Modal.getOrCreateInstance(helpBox, { keyboard: false });
      modal.show();
    }
  };

  var focusSearchInput = function(e) {
    e.preventDefault();
    var searchBox = document.getElementById("search-box");
    if (searchBox) searchBox.focus();
  }

  var openCurrentLink = function(e) {
    e.preventDefault(e);
    var currentRow = getCurrentRow();
    if (currentRow) {
      var link = currentRow.querySelector("td.notification-subject .link");
      if (link) {
        link.click();
      }
    }
  };

  var notify = function(message, type) {
    document.querySelectorAll(".header-flash-messages").forEach(el => el.remove());
    var alert_html = [
      "<div class='flex-header header-flash-messages'>",
      "  <div class='alert alert-" + type + " fade show'>",
      "    <button class='btn-close' data-bs-dismiss='alert'></button>",
             message,
      "  </div>",
      "</div>"
    ].join("\n");
    var flexHeader = document.querySelector(".flex-header");
    if (flexHeader) flexHeader.insertAdjacentHTML('afterend', alert_html);
  };

  var autoSync = function() {
    hasMarkedRows() || sync()
  };

  var escPressed = function(e) {
    var helpBox = document.getElementById("help-box");
    if (helpBox && helpBox.classList.contains("show")) {
      var modal = bootstrap.Modal.getInstance(helpBox);
      if (modal) modal.hide();
    } else if(document.querySelector(".flex-main") && document.querySelector(".flex-main").classList.contains("show-thread")){
      closeThread();
    } else if(document.activeElement === document.getElementById("search-box")) {
      var table = document.querySelector(".table-notifications");
      if (table) { table.setAttribute("tabindex", "-1"); table.focus(); }
    } else {
      clearFilters();
    }
  };

  var clearFilters = function() {
    Turbolinks.visit("/");
  };

  var scrollToCursor = function() {
    var current = document.querySelector("td.js-current");
    if (!current) return;
    var table = document.querySelector(".js-table-notifications");
    if (!table) return;
    var menu = document.querySelector(".js-octobox-menu");
    if (!menu) return;

    var table_offset = table.offsetTop;
    var cursor_offset = current.getBoundingClientRect().top + window.pageYOffset;
    var cursor_relative_offset = current.offsetTop;
    var cursor_height = current.offsetHeight;
    var menu_height = menu.offsetHeight;
    var scroll_top = window.pageYOffset;
    var window_height = window.innerHeight;

    if ( cursor_offset < menu_height + scroll_top ) {
      window.scrollTo(0, table_offset + cursor_relative_offset - cursor_height);
    }
    if ( cursor_offset > scroll_top + window_height - cursor_height ) {
      window.scrollTo(0, cursor_offset - window_height + 2*cursor_height);
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
