class CommentsChannel < ApplicationCable::Channel
  def subscribed
  	subject = Notification.find(params[:id]).subject
    stream_for subject
  end

  def unsubscribed
    stop_all_streams
  end
end
