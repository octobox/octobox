# frozen_string_literal: true
require 'test_helper'

class SyncAllUserNotificationsWorkerTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
  end

  test 'syncs all users notifications' do
    SyncAllUserNotificationsWorker.new.perform
    assert_sidekiq_job_enqueued(SyncNotificationsWorker, @user.id)
  end
end
