# frozen_string_literal: true

require 'application_system_test_case'

class NotificationActionsTest < ApplicationSystemTestCase
  setup do
    @user = create(:user, disable_confirmations: true)
    @notification1 = create(:notification, user: @user, subject_title: 'Action test one')
    @notification2 = create(:notification, user: @user, subject_title: 'Action test two')
    @notification3 = create(:notification, user: @user, subject_title: 'Action test three')
    sign_in_as(@user)
  end

  test 'clicking checkbox shows bulk action buttons' do
    assert_no_selector 'button.archive_selected', visible: true

    toggle_notification_checkbox(@notification1.id)
    sleep 0.1

    assert_selector 'button.archive_selected', visible: true
  end

  test 'select all checkbox checks all rows' do
    toggle_select_all
    sleep 0.1

    all('tr.notification', minimum: 1).each do |row|
      checkbox = row.find('input[type="checkbox"]', visible: :all)
      assert checkbox.checked?
    end
  end

  test 'star click toggles star state' do
    notification = @notification1
    refute notification.starred

    row = find("#notification-#{notification.id}")
    star = row.find('.toggle-star')
    assert_includes star[:class], 'star-inactive'

    star.click
    sleep 0.5

    star = row.find('.toggle-star')
    assert_includes star[:class], 'star-active'

    notification.reload
    assert notification.starred
  end

  test 'archive action works on selected notifications' do
    toggle_notification_checkbox(@notification1.id)
    sleep 0.1

    click_button class: 'archive_selected'

    assert_no_text 'Action test one', wait: 5
    assert_text 'Action test two'

    @notification1.reload
    assert @notification1.archived
  end

  test 'unchecking all checkboxes hides bulk action buttons' do
    toggle_notification_checkbox(@notification1.id)
    sleep 0.1
    assert_selector 'button.archive_selected', visible: true

    toggle_notification_checkbox(@notification1.id)
    sleep 0.1
    assert_no_selector 'button.archive_selected', visible: true
  end
end
