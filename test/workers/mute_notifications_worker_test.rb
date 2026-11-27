# frozen_string_literal: true
require 'test_helper'

class MuteNotificationsWorkerTest < ActiveSupport::TestCase
  setup do
    @thread = 'https://api.github.com/notifications/threads/123'
  end

  test 'marks each thread as read and ignores it on GitHub' do
    user = create(:user)
    threads = [@thread, 'https://api.github.com/notifications/threads/456']
    threads.each do |thread|
      stub_request(:patch, thread).to_return(status: 205)
      stub_request(:put, "#{thread}/subscription").to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    end

    MuteNotificationsWorker.new.perform(user.id, [123, 456])

    threads.each do |thread|
      assert_requested :patch, thread
      assert_requested :put, "#{thread}/subscription", body: { ignored: true }.to_json
    end
  end

  test 'ignores threads the user can no longer access' do
    user = create(:user)
    stub_request(:patch, @thread).to_return(status: 404)
    stub_request(:put, "#{@thread}/subscription").to_return(status: 404)

    assert_nothing_raised { MuteNotificationsWorker.new.perform(user.id, [123]) }
  end

  test 'does nothing for a user that no longer exists' do
    MuteNotificationsWorker.new.perform(0, [123])

    assert_not_requested :patch, @thread
  end
end
