require 'test_helper'

class TasksTest < ActiveSupport::TestCase
  setup { stub_notifications_request }

  test 'fetches notifications' do
    travel_to "2016-12-19T19:00:00Z" do
      user = users(:andrew)

      Rake::Task['tasks:sync_notifications'].invoke

      assert user.notifications.any?
    end
  end
end
