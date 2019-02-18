require 'test_helper'

class IndexPageTest < ActionDispatch::IntegrationTest
  test 'index page without login is home page' do
    get root_path
    assert_select "a[href=?]", login_path
    assert_select 'h1', text: 'Octobox'
    assert_select 'h3', text: 'Untangle your GitHub Notifications'
    assert_select 'h3', text: 'Sound like you?'
    assert_match 'figment of your imagination', response.body
    assert_select 'h5', text: "Don't lose track"
    assert_match 'Octobox adds an extra "archived" state', response.body
    assert_select 'h5', text: 'Keep your focus'
    assert_match 'Search and filter notifications', response.body
    assert_select 'h5', text: 'Stay fresh'
    assert_match 'Keep those notifications up to date', response.body
    assert_select 'h3', text: 'Run your own Octobox'
    assert_match 'There are a number of install options', response.body
    assert_select 'h3', text: 'Contribute'
    assert_match 'You can also help triage issues.', response.body
  end

  test 'index page with login is notifications page' do
    stub_notifications_request
    stub_comments_requests
    stub_fetch_subject_enabled(value: false)
    @user = create(:user)
    sign_in_as(@user)
    get root_path
    assert_select "a[href=?]", logout_path
    assert_match 'Inbox', response.body
    assert_match 'Archive', response.body
    assert_match 'Starred', response.body
    assert_match 'Read', response.body
    assert_match 'Unread', response.body
    assert_match 'Last sync', response.body
  end
end
