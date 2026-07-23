# frozen_string_literal: true

require 'test_helper'

class CustomWorkerTest < ActiveSupport::TestCase
  test 'perform_async is only called from custom worker' do
    ruby_files = Dir.glob(Rails.root.join('**', '*.rb'))
    test_files = Dir.glob(Rails.root.join('test', '**', '*.rb'))
    vendor_files = Dir.glob(Rails.root.join('vendor', '**', '*.rb'))
    files_to_test = ruby_files - test_files - vendor_files

    bad_files = files_to_test.select do |file|
      File.read(file).force_encoding('UTF-8') =~ /\.perform_async\(/
    end

    assert_empty bad_files, <<~EOF
    Some files used `perform_async` instead of our custom `perform_async_if_configured`

    Octobox does not assume that sidekiq is setup, so we use a custom `perform_async_if_configured`
    that only performs the job in the background if sidekiq is configured. Otherwise, it performs it inline.

    Please use `perform_async_if_configured` instead of `perform_async` in these files:

    - #{bad_files.join("\n -")}
    EOF
  end

  test 'perform_async_if_configured calls perform_async' do
    with_background_jobs_enabled(enabled: true) do
      SyncAllUserNotificationsWorker.any_instance.expects(:perform).never
      SyncAllUserNotificationsWorker.perform_async_if_configured(['arg'])
      assert_equal 1, SyncAllUserNotificationsWorker.jobs.size

      args = SyncAllUserNotificationsWorker.jobs.first['args']
      assert_equal 1, args.size
      assert_equal ['arg'], args.first
    end
  end

  test 'perform_async_if_configured calls perform with no args' do
    with_background_jobs_enabled(enabled: false) do
      SyncAllUserNotificationsWorker.any_instance.expects(:perform).once
      SyncAllUserNotificationsWorker.expects(:perform_async).never
      SyncAllUserNotificationsWorker.perform_async_if_configured(['arg'])
    end
  end

  test 'perform_async_if_configured calls perform with args' do
    with_background_jobs_enabled(enabled: false) do
      SyncLabelWorker.any_instance.expects(:perform).once.with(['arg'])
      SyncLabelWorker.expects(:perform_async).never
      SyncLabelWorker.perform_async_if_configured(['arg'])
    end
  end

  test 'perform_in_if_configured calls perform_in' do
    with_background_jobs_enabled(enabled: true) do
      ArchiveWorker.any_instance.expects(:perform).never
      ArchiveWorker.perform_in_if_configured(5.minutes, 1, [2], 3)
      assert_equal 1, ArchiveWorker.jobs.size

      job = ArchiveWorker.jobs.first
      assert_in_delta 5.minutes.from_now.to_f, job['at'], 2
      assert_equal [1, [2], 3], job['args']
    end
  end

  test 'perform_in_if_configured calls perform when background jobs are disabled' do
    with_background_jobs_enabled(enabled: false) do
      ArchiveWorker.any_instance.expects(:perform).once.with(1, [2], 3)
      ArchiveWorker.expects(:perform_in).never
      ArchiveWorker.perform_in_if_configured(5.minutes, 1, [2], 3)
    end
  end
end
