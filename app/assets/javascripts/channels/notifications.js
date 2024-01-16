document.addEventListener("turbolinks:load", function () {
  if (document.querySelectorAll("meta[name='push_notifications']").length > 0) {
    App.notifications = App.cable.subscriptions.create("NotificationsChannel", {
      received: function(data) {
        var el = '#notification-'+data.id;
        if(document.querySelectorAll(el).length) {
          var selected = document.querySelector(el).querySelector("input:checked");
          document.querySelector(el).outerHTML = data.notification;
          if (selected) {
            document.querySelector(el).querySelector("input[type=checkbox]").checked = true;
          }
        }
        if(document.querySelector('#notification-thread').getAttribute('data-id') == data.id){
          document.querySelector('#thread-subject').innerHTML = data.subject;
        }

        Octobox.updateAllPinnedSearchCounts();
      }
    });
  }
});