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
});
