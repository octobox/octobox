var addCommentToThread = function(subject_id, comment_id, comment_html){
  if ($('#notification-thread').attr('data-id') == subject_id && !$("#comment-"+comment_id).length){
    $('.discussion-thread').append(comment_html);
  }
}

if ($("meta[name='push_notifications']").length >0) {

  $(document).on('click', '.thread-link', function(){
    if(App.comments){
      App.comments.unsubscribe();
    }
    App.comments = App.cable.subscriptions.create({
      channel: "CommentsChannel",
      notification: $(this).attr('href').split('/').pop()},{
      received: function(data){
        addCommentToThread(data.subject_id, data.comment_id, data.comment_html)
      }
    });
  });
  
  $(document).on("turbolinks:load", function(){
    if($('#thread').is(':visible')){
      if(App.comments){
        App.comments.unsubscribe();
      }
      App.comments = App.cable.subscriptions.create({
        channel: "CommentsChannel",
        notification: $(location).attr('href').split('/').pop()},{
        received: function(data){
          addCommentToThread(data.subject_id, data.comment_id, data.comment_html)
        }
      });
    }
  });
}
