class CommentsChannel < ApplicationCable::Channel
  def subscribed
  	subject = current_user.notifications.find(params[:notification]).subject
    stream_for subject
  end

  def unsubscribed
    stop_all_streams
  end
end
