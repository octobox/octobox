class SyncChannel < ApplicationCable::Channel
  def subscribed
    stream_from "sync:#{current_user.id}"
  end

  def unsubscribed
    stop_all_streams
  end
end
