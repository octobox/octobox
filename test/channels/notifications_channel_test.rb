# frozen_string_literal: true

require "test_helper"

class NotificationsChannelTest < ActionCable::Channel::TestCase


  test "Reject subscriptions without a current user" do
    stub_connection current_user: nil
    subscribe

    assert subscription.rejected?
    assert_no_streams
  end

  test "receives notification webhooks when updated" do
    user = create(:user)
    notification = create(:notification, user: user)

    stub_connection current_user: user
    subscribe
    assert_has_stream "notifications:#{user.id}"

    assert_broadcasts("notifications:#{user.id}", 1) do
      notification.update(archived: true)
    end
  end

end