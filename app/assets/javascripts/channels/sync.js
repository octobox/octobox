App.sync = App.cable.subscriptions.create("SyncChannel", {
  received: function(data) {
    // Refresh the page after a sync has completed
    Turbolinks.visit("/"+location.search);
  }
});
