//= require jquery3
//= require jquery_ujs
//= require turbolinks
//= require local-time
//= require popper
//= require bootstrap
//= require_tree .

var db;

window.onload = function() {
  SearchSuggestion.init()
}

document.addEventListener("turbolinks:load", Octobox.initialize);
document.addEventListener("turbolinks:before-cache", Octobox.removeCurrent);

$(document).on("submit", "#search", function(event) {
  SearchSuggestion.addSearchString($("#search-box").val());
});

$(document).on("click", ".search-remove-btn", SearchSuggestion.deleteSearchString);
$(document).on("click", "#search-box", SearchSuggestion.displaySearchSuggestions);
$(document).on("click", "#search-sugguestion-list", SearchSuggestion.addToSearchBox);

$(document).on("mouseup", SearchSuggestion.unblur);

$(document).on('change', 'input.archive, input.unarchive', Octobox.changeArchive);
$(document).on('change', '.js-select_all', Octobox.checkAll);

$(document).on('click', 'button.select_all', Octobox.toggleSelectAll);
$(document).on('click', 'button.archive_selected', Octobox.archiveSelected);
$(document).on('click', 'button.unarchive_selected', Octobox.unarchiveSelected);
$(document).on('click', 'button.archive', Octobox.archiveThread);
$(document).on('click', 'button.unarchive', Octobox.unarchiveThread);
$(document).on('click', 'button.mute', Octobox.muteThread);
$(document).on('click', 'button.mute_selected', Octobox.muteSelected);
$(document).on('click', 'button.delete', Octobox.deleteThread);
$(document).on('click', 'button.delete_selected', Octobox.deleteSelected);
$(document).on('click', 'button.mark_read_selected', Octobox.markReadSelected);
$(document).on('click', 'button.closethread', Octobox.closeThread);

$(document).on('click', 'tr.notification', Octobox.moveCursorToClickedRow);
$(document).on('click', '[data-toggle="offcanvas"]', Octobox.toggleOffCanvas);

$(document).on('click', 'a.js-sync', function(e) {
  e.preventDefault(e);
  Octobox.sync()
});

$(document).on('click', 'tr.notification', function() {
  Octobox.markRowCurrent($(this))
});

$(document).on('click', '.toggle-star', function() {
  Octobox.toggleStarClick($(this))
});

$(document).on('click', '.thread-link', Octobox.viewThread);

$(document).on('click', '.expand-comments', Octobox.expandComments);
