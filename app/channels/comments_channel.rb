class CommentsChannel < ApplicationCable::Channel
  def subscribed
  	subject = Notification.find(params[:id]).subject
    stream_to 'comments:#{subject.id}'
  end

  def unsubscribed
    stop_all_streams
  end
end
