class NotificationsChannel < ApplicationCable::Channel
  def subscribed
  	reject if current_user.id.nil?
  	stream_from "notifications:#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end
end
