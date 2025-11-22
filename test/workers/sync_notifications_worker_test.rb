# frozen_string_literal: true

require 'test_helper'

class SyncNotificationsWorkerTest < ActiveSupport::TestCase
  setup do
    stub_repository_request
    @user = create(:user)
    @stubbed_user_notification_sync = stub_notifications_request(extra_headers: {
      'Authorization' => "token #{@user.access_token}"
    })
  end

  test 'syncs a given users notifications' do
    skip("only passes if OCTOBOX_BACKGROUND_JOBS_ENABLED=true")
    Sidekiq::Testing.inline! do
      SyncNotificationsWorker.perform_async(@user.id)
    end

    assert_requested(@stubbed_user_notification_sync, times: 2)
  end

  test 'enqueues one job per user at a time' do
    skip("only passes if OCTOBOX_BACKGROUND_JOBS_ENABLED=true")
    SyncNotificationsWorker.perform_async(@user.id)
    assert_equal 1, SyncNotificationsWorker.jobs.size

    # The same user tries to enqueue another job
    # to sync their notifications when we haven't
    # even tried the first time.
    SyncNotificationsWorker.perform_async(@user.id)
    assert_equal 1, SyncNotificationsWorker.jobs.size

    another_user = create(:user)
    SyncNotificationsWorker.perform_async(another_user.id)
    assert_equal 2, SyncNotificationsWorker.jobs.size
  end

  test 'gracefully handles failed sync and stores exception' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Octokit::BadGateway)

    Sidekiq::Testing.inline! do
      job_id = SyncNotificationsWorker.perform_async(@user.id)
      assert_equal 'Octokit::BadGateway', Sidekiq::Status::get(job_id, :exception)
    end

    refute_requested(@stubbed_user_notification_sync)
  end

  test 'gracefully handles failed user notification syncs' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Octokit::BadGateway)

    assert_nothing_raised do
      Sidekiq::Testing.inline! do
        SyncNotificationsWorker.perform_async(@user.id)
      end
    end

    refute_requested(@stubbed_user_notification_sync)
  end

  test 'gracefully handles failed user notification syncs with wrong token' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Octokit::Unauthorized)

    assert_nothing_raised do
      Sidekiq::Testing.inline! do
        SyncNotificationsWorker.perform_async(@user.id)
      end
    end

    refute_requested(@stubbed_user_notification_sync)
  end

  test 'gracefully handles forbidden user notification syncs' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Octokit::Forbidden)

    assert_nothing_raised do
      Sidekiq::Testing.inline! do
        SyncNotificationsWorker.perform_async(@user.id)
      end
    end

    refute_requested(@stubbed_user_notification_sync)
  end

  test 'gracefully handles failed user notification syncs when user is offline' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Faraday::ConnectionFailed.new('offline error'))

    assert_nothing_raised do
      Sidekiq::Testing.inline! do
        SyncNotificationsWorker.perform_async(@user.id)
      end
    end

    refute_requested(@stubbed_user_notification_sync)
  end
end
