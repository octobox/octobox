$(document).on("turbolinks:load", function () {
  if ($("meta[name='push_notifications']").length >0) {
    App.sync = App.cable.subscriptions.create("NotificationsChannel", {
      received: function(data) {
        if($(data.id).length) {
          var selected = $(data.id).has("input:checked");

          $(data.id)[0].outerHTML = data.html;
          if (selected.length) {
            $(data.id).find("input[type=checkbox]").prop('checked', true);
          }
        }
      }
    });
  }
});
