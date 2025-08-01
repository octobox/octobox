//= require jquery3
//= require rails-ujs
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

document.addEventListener('change', function(e) {
  if(e.target.matches('input.archive, input.unarchive')) {
    Octobox.changeArchive(e);
  }
});

document.addEventListener('change', function(e) {
  if(e.target.matches('.js-select_all')) {
    Octobox.checkAll(e);
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.select_all')) {
    Octobox.toggleSelectAll();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.archive_selected')) {
    Octobox.archiveSelected();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.unarchive_selected')) {
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
  if(event.target.matches('button.mute_selected')) {
    Octobox.muteSelected();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.delete')) {
    Octobox.deleteThread();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.delete_selected')) {
    Octobox.deleteSelected();
  }
});

document.addEventListener('click', function(event) {
  if(event.target.matches('button.mark_read_selected')) {
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
  if(e.target.matches('a.js-sync')) {
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
  if(e.target.matches('.toggle-star')) {
    Octobox.toggleStarClick(e.target);
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
