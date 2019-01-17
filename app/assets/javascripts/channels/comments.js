if ($("meta[name='push_notifications']").length >0) {
  $(document).on('click', '.thread-link', function(){
    App.comments = App.cable.subscriptions.create("CommentsChannel", {
      subject: $(this).attr('href').split('/').pop(),
      received: function(data){
        if($(data.id).length) {
          if ($('notification-thread').attr('data-id') == data.subject){
            $('.discussion-thread').append(data.comment_html);
          }
        }
      }
    });
    console.log($(this).attr('href'));
  });
}