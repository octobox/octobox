# frozen_string_literal: true
require 'test_helper'

class SyncAllUserNotificationsWorkerTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test 'syncs all users notifications' do
    SyncAllUserNotificationsWorker.new.perform
    assert_equal 1, SyncNotificationsWorker.jobs.size
  end
end
