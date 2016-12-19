//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .

document.addEventListener("turbolinks:load", function() {
  $('.archive').click(function() {
    Turbolinks.visit('/notifications/'+$(this).val()+'/archive'+location.search)
  });
  $('.unarchive').click(function() {
    Turbolinks.visit('/notifications/'+$(this).val()+'/unarchive'+location.search)
  });
  $('.toggle-star').click(function() {
    $(this).toggleClass("fa-star fa-star-o")
    $.get('/notifications/'+$(this).data('id')+'/star')
  });
});
