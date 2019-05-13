var subscribeToComments = function(){

  if (App.comments){
    App.comments.unsubscribe();
  }
  App.comments = App.cable.subscriptions.create({
    channel: "CommentsChannel",
    notification: $(location).attr('href').split('/').pop()},{
    received: function(data){
      if ($('#notification-thread').attr('data-subject-id') == data.subject_id && !$("#comment-"+data.comment_id).length){
        $('.discussion-thread').append(data.comment_html);
      } else if ($("#comment-"+data.comment_id).length){
        $("#comment-"+data.comment_id)[0].outerHTML = data.comment_html;
      }
    }
  });
}

if ($("meta[name='push_notifications']").length >0) {
  
  $(document).on("turbolinks:load", function(){
    if($('#thread').is(':visible')){
      subscribeToComments();
    }
  });
}
