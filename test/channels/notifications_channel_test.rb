# frozen_string_literal: true

require "test_helper"

class NotificationsChannelTest < ActionCable::Channel::TestCase

  test "Reject subscriptions without a current user" do

    subscribe

    assert subscription.rejected?
    assert_no_streams
  end

end