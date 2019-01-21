class NotificationsChannel < ApplicationCable::Channel
  def subscribed
  	if current_user.nil? 
  			reject
  	else
  		stream_from "notifications:#{current_user.id}"
  	end
  end

  def unsubscribed
    stop_all_streams
  end
end
