App.sync = App.cable.subscriptions.create("SyncChannel", {
  received: function(data) {
    // Called when there's incoming data on the websocket for this channel
    console.log(data)
  }
});
