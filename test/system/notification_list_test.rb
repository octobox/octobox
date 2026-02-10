# frozen_string_literal: true

require 'application_system_test_case'

class NotificationListTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, disable_confirmations: true)
    @notification = create(:notification, user: @user, subject_title: 'Fix the widget')
    @unread_notification = create(:notification, user: @user, unread: true, subject_title: 'Update docs')
    @read_notification = create(:notification, user: @user, unread: false, subject_title: 'Old issue')
    sign_in_as(@user)
  end

  test 'notification table renders with notifications' do
    assert_selector 'table.js-table-notifications'
    assert_text 'Fix the widget'
    assert_text 'Update docs'
    assert_text 'Old issue'
  end

  test 'unread notifications have active class' do
    row = find("#notification-#{@unread_notification.id}")
    assert_includes row[:class], 'active'
  end

  test 'read notifications do not have active class' do
    row = find("#notification-#{@read_notification.id}")
    refute_includes row[:class].split(' '), 'active'
  end

  test 'sidebar inbox link is active by default' do
    within '.flex-sidebar' do
      assert_selector 'a.nav-link.active', text: 'Inbox'
    end
  end

  test 'sidebar archive link navigates to archive view' do
    within '.flex-sidebar' do
      click_link 'Archive'
    end
    assert_current_path(/archive=true/)
    within '.flex-sidebar' do
      assert_selector 'a.nav-link.active', text: 'Archive'
    end
  end

  test 'sidebar starred link navigates to starred view' do
    starred = create(:notification, user: @user, starred: true, subject_title: 'Starred item')
    within '.flex-sidebar' do
      click_link 'Starred'
    end
    assert_current_path(/starred=true/)
    within '.flex-sidebar' do
      assert_selector 'a.nav-link.active', text: 'Starred'
    end
    assert_text 'Starred item'
  end
end
