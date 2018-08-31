# frozen_string_literal: true

require 'test_helper'

class CustomWorkerTest < ActiveSupport::TestCase
  test 'perform_async is only called from custom worker' do
    ruby_files = Dir.glob(Rails.root.join('**', '*.rb'))
    test_files = Dir.glob(Rails.root.join('test', '**', '*.rb'))
    files_to_test = ruby_files - test_files
    bad_files = files_to_test.select { |file| File.read(file) =~ /\.perform_async\(/ }
    assert_empty bad_files, <<~EOF
    Some files used `perform_async` instead of our custom `perform_async_if_configured`

    Octobox does not assume that sidekiq is setup, so we use a custom `perform_async_if_configured`
    that only performs the job in the background if sidekiq is configured. Otherwise, it performs it inline.

    Please use `perform_async_if_configured` instead of `perform_async` in these files:

    - #{bad_files.join("\n -")}
    EOF
  end

  test 'perform_async_if_configured calls perform_async' do
    Octobox.config.background_jobs_enabled = true
    SyncAllUserNotificationsWorker.expects(:perform).never
    SyncAllUserNotificationsWorker.perform_async_if_configured(['arg'])
    assert_equal 1, SyncAllUserNotificationsWorker.jobs.size

    args = SyncAllUserNotificationsWorker.jobs.first['args']
    assert_equal 1, args.size
    assert_equal ['arg'], args.first
  end

  test 'perform_async_if_configured calls perform' do
    Octobox.config.background_jobs_enabled = false
    SyncAllUserNotificationsWorker.expects(:perform).once.with(['arg'])
    SyncAllUserNotificationsWorker.expects(:perform_async).never
    SyncAllUserNotificationsWorker.perform_async_if_configured(['arg'])
  end
end
