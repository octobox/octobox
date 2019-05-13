class CommentsChannel < ApplicationCable::Channel

  def subscribed
    if current_user.nil?
        reject
    else
      subject = current_user.notifications.find(params[:notification]).subject
      stream_for subject
    end
  end

  def unsubscribed
    stop_all_streams
  end
end
