var subscribeToComments = function(){

  if (App.comments){
    App.comments.unsubscribe();
  }
  App.comments = App.cable.subscriptions.create({
    channel: "CommentsChannel",
    notification: window.location.href.split('/').pop()},{
    received: function(data){
      var thread = document.querySelector('#notification-thread');
      if (thread && thread.getAttribute('data-subject-id') == data.subject_id && !document.querySelectorAll("#comment-" + data.comment_id).length){
        document.querySelector('.discussion-thread').insertAdjacentHTML('beforeend', data.comment_html);
      } else if (document.querySelectorAll("#comment-" + data.comment_id).length){
        document.querySelector("#comment-" + data.comment_id).outerHTML = data.comment_html;
      }
    }
  });
}

if (document.querySelectorAll("meta[name='push_notifications']").length >0) {
  document.addEventListener("turbolinks:load", function() {
    var threadElement = document.getElementById('thread');
    if(threadElement && threadElement.matches(':visible')){
      subscribeToComments();
    }
  });
}
