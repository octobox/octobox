require 'test_helper'

class TasksTest < ActiveSupport::TestCase
  setup do
    stub_notifications_request
    stub_fetch_subject_enabled(value: false)
  end

  test 'fetches notifications' do
    travel_to "2016-12-19T19:00:00Z" do
      user = create(:user)

      Sidekiq::Testing.inline! do
        Rails.application.load_tasks
        Rake::Task['tasks:sync_notifications'].invoke
      end

      assert user.notifications.any?
    end
  end
end
