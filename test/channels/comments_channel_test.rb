# frozen_string_literal: true

require "test_helper"

class CommentsChannelTest < ActionCable::Channel::TestCase


  test "Reject subscriptions without a current user" do
    stub_connection current_user: nil
    subscribe

    assert subscription.rejected?
    assert_no_streams
  end

  test "receives comment webhooks when created" do

    user = create(:user)
    notification = create(:notification, user: user)
    subject = create(:subject, notifications: [notification])

    stub_connection(current_user: user)
    subscribe notification: notification.id

    assert_has_stream "comments:#{subject.id}"

    assert_broadcasts(subject, 1) do
      create(:comment, subject: subject)
    end

  end

  test "receives comment webhooks when updated" do

    user = create(:user)
    notification = create(:notification, user: user)
    subject = create(:subject, notifications: [notification])
    comment = create(:comment, subject: subject)

    stub_connection(current_user: user)
    subscribe notification: notification.id

    assert_has_stream "comments:#{subject.id}"

    assert_broadcasts(subject, 1) do
      comment.update_attributes(body: "A new body")
    end

  end

end