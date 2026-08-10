# frozen_string_literal: true

require 'test_helper'

class SyncNotificationsWorkerTest < ActiveSupport::TestCase
  setup do
    stub_repository_request
    @user = create(:user)
    @stubbed_user_notification_sync = stub_notifications_request.with(headers: {
      'Authorization' => "token #{@user.access_token}"
    })
  end

  test 'syncs a given users notifications' do
    User.stubs(:find_by).with(id: @user.id).returns(@user)
    @user.expects(:sync_notifications_in_foreground).once

    SyncNotificationsWorker.new.perform(@user.id)
  end

  test 'locks duplicate user notification syncs until execution' do
    assert_equal :until_executed, SyncNotificationsWorker.get_sidekiq_options['lock']
  end

  test 'gracefully handles failed sync and stores exception' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Octokit::BadGateway)

    Sidekiq.testing!(:inline) do
      job_id = SyncNotificationsWorker.perform_async(@user.id)
      assert_equal 'Octokit::BadGateway', Sidekiq::Status::get(job_id, :exception)
    end

    refute_requested(@stubbed_user_notification_sync)
  end

  test 'gracefully handles failed user notification syncs' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Octokit::BadGateway)

    assert_nothing_raised do
      Sidekiq.testing!(:inline) do
        SyncNotificationsWorker.perform_async(@user.id)
      end
    end

    refute_requested(@stubbed_user_notification_sync)
  end

  test 'gracefully handles failed user notification syncs with wrong token' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Octokit::Unauthorized)

    assert_nothing_raised do
      Sidekiq.testing!(:inline) do
        SyncNotificationsWorker.perform_async(@user.id)
      end
    end

    refute_requested(@stubbed_user_notification_sync)
  end

  test 'gracefully handles forbidden user notification syncs' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Octokit::Forbidden)

    assert_nothing_raised do
      Sidekiq.testing!(:inline) do
        SyncNotificationsWorker.perform_async(@user.id)
      end
    end

    refute_requested(@stubbed_user_notification_sync)
  end

  test 'gracefully handles failed user notification syncs when user is offline' do
    User.any_instance.stubs(:sync_notifications_in_foreground).raises(Faraday::ConnectionFailed.new('offline error'))

    assert_nothing_raised do
      Sidekiq.testing!(:inline) do
        SyncNotificationsWorker.perform_async(@user.id)
      end
    end

    refute_requested(@stubbed_user_notification_sync)
  end
end
