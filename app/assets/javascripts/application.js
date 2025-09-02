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
//= require bootstrap/popover
//= require_tree .

var db;

window.onload = function() {
  SearchSuggestion.init()
}

document.addEventListener("turbolinks:load", Octobox.initialize);
document.addEventListener("turbolinks:before-cache", Octobox.removeCurrent);

document.addEventListener('submit', function(event) {
  if (event.target.matches('#search')) {
    SearchSuggestion.addSearchString(document.querySelector("#search-box").value);
  }
});

document.addEventListener('click', function(event) {
  if (event.target.matches('.search-remove-btn')) {
    SearchSuggestion.deleteSearchString(event);
  }
});

document.addEventListener('click', function(e) {
  if(e.target.matches('#search-box')) {
    SearchSuggestion.displaySearchSuggestions();
  }
});

document.addEventListener('click', function(e) {
  if(e.target.matches('#search-sugguestion-list')) {
    SearchSuggestion.addToSearchBox(e);
  }
});

document.addEventListener('mouseup', SearchSuggestion.unblur);

// Checkbox handling is now done in initShiftClickCheckboxes

document.addEventListener('change', function(e) {
  if(e.target.matches('.js-select_all')) {
    Octobox.checkAll(e);
    // Call changeArchive after checkAll completes
    setTimeout(() => {
      Octobox.changeArchive(e);
    }, 10);
  }
  // Handle programmatic change events from checkAll function
  else if(e.target.tagName === 'INPUT' && e.target.type === 'checkbox' && (e.target.classList.contains('archive') || e.target.classList.contains('unarchive'))) {
    Octobox.changeArchive(e);
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.select_all') || event.target.closest('button.select_all')) {
    Octobox.toggleSelectAll();
  }
});

document.addEventListener('click', function(event) {
  // Check if clicked element or its parent is archive_selected button
  let archiveButton = null;
  if(event.target.matches('button.archive_selected')) {
    archiveButton = event.target;
  } else if(event.target.closest('button.archive_selected')) {
    archiveButton = event.target.closest('button.archive_selected');
  }
  
  if(archiveButton) {
    Octobox.archiveSelected();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.unarchive_selected') || event.target.closest('button.unarchive_selected')) {
    Octobox.unarchiveSelected();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.archive')) {
    Octobox.archiveThread();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.unarchive')) {
    Octobox.unarchiveThread();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.mute')) {
    Octobox.muteThread();
  }
});

document.addEventListener('click', function(event) {
  // Check if clicked element or its parent is mute_selected button
  let muteButton = null;
  if(event.target.matches('button.mute_selected')) {
    muteButton = event.target;
  } else if(event.target.closest('button.mute_selected')) {
    muteButton = event.target.closest('button.mute_selected');
  }
  
  if(muteButton) {
    Octobox.muteSelected();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.delete')) {
    Octobox.deleteThread();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.delete_selected') || event.target.closest('button.delete_selected')) {
    Octobox.deleteSelected();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.mark_read_selected') || event.target.closest('button.mark_read_selected')) {
    Octobox.markReadSelected();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.closethread')) {
    Octobox.closeThread();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('tr.notification')) {
    Octobox.moveCursorToClickedRow();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('[data-toggle="offcanvas"]')) {
    Octobox.toggleOffCanvas();
  }
});

document.addEventListener('click', function(e) {
  // Check if clicked element or its parent is a sync link
  let syncElement = null;
  if(e.target.matches('a.js-sync')) {
    syncElement = e.target;
  } else if(e.target.closest('a.js-sync')) {
    syncElement = e.target.closest('a.js-sync');
  }
  
  if(syncElement) {
    e.preventDefault();
    Octobox.sync();
  }
});

document.addEventListener('click', function(e) {
  if(e.target.closest('tr.notification')) {
    Octobox.markRowCurrent(e.target.closest('tr.notification'));
  }
});

document.addEventListener('click', function(e) {
  // Check if clicked element or its parent has toggle-star class
  let starElement = null;
  if(e.target.matches('.toggle-star')) {
    starElement = e.target;
  } else if(e.target.closest('.toggle-star')) {
    starElement = e.target.closest('.toggle-star');
  }
  
  if(starElement) {
    Octobox.toggleStarClick(starElement);
  }
});

document.addEventListener('click', function(e) {
  if(e.target.matches('.thread-link')) {
    Octobox.viewThread(e);
  }
});

document.addEventListener('click', function(e) {
  if(e.target.matches('.expand-comments')) {
    Octobox.expandComments(e);
  }
});
