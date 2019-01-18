if ($("meta[name='push_notifications']").length >0) {

  $(document).on('click', '.thread-link', function(){
    if(App.comments){
      App.comments.unsubscribe();
    }
    App.comments = App.cable.subscriptions.create({
      channel: "CommentsChannel",
      notification: $(this).attr('href').split('/').pop()},{
      received: function(data){
        if ($('#notification-thread').attr('data-id') == data.subject_id){
          $('.discussion-thread').append(data.comment_html);
        }
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
          if ($('#notification-thread').attr('data-id') == data.subject_id){
            $('.discussion-thread').append(data.comment_html);
          }
        }
      });
    }
  });
}
