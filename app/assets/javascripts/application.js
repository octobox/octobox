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

document.addEventListener("turbolinks:load", Octobox.initialize);
document.addEventListener("turbolinks:before-cache", Octobox.removeCurrent);

$(document).on('change', 'input.archive, input.unarchive', Octobox.changeArchive);
$(document).on('change', '.js-select_all', Octobox.checkAll);

$(document).on('click', 'button.select_all', Octobox.toggleSelectAll);
$(document).on('click', 'button.archive_selected, button.unarchive_selected', Octobox.toggleArchive);
$(document).on('click', 'button.mute_selected', Octobox.mute);
$(document).on('click', 'button.mark_read_selected', Octobox.markReadSelected);
$(document).on('click', 'tr.notification', Octobox.moveCursorToClickedRow);
$(document).on('click', '[data-toggle="offcanvas"]', Octobox.toggleOffCanvas);

$(document).on('click', 'a.js-sync', function(e) {
  e.preventDefault(e);
  Octobox.sync()
});

$(document).on('click', 'tr.notification', function() {
  Octobox.markRowCurrent($(this))
})

$(document).on('click', '.toggle-star', function() {
  Octobox.toggleStarClick($(this))
})
