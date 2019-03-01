require 'test_helper'

class PrivacyPageTest < ActionDispatch::IntegrationTest
  def setup
    stub_notifications_request
    stub_comments_requests
    stub_fetch_subject_enabled(value: false)
    @user = create(:user)
  end

  def teardown
    User.destroy_all
  end

  def check_redirected
    get privacy_path
    assert_match 'You are being', response.body
    assert_select "a[href=?]", 'http://www.example.com/422', text: 'redirected'
  end

  def check_privacy_page_contents
    get privacy_path
    assert_select 'h1', text: 'Privacy Policy'
    assert_select 'h2', text: 'We Care About Your Privacy'
    assert_select 'h3', text: 'Data We Collect'
    assert_select 'h3', text: 'Transmitting Your Data'
    assert_select 'h3', text: 'Processing And Storing Your Data'
    assert_select 'h3', text: 'Sharing Your Data'
    assert_select 'h2', text: 'Services We Use'
    assert_select 'h3', text: 'Cookies'
    assert_select 'h3', text: 'Logging'
    assert_select 'h4', text: "Bugsnag's DPA"
    assert_select 'h2', text: 'Your Rights'
  end

  test 'privacy page is not shown when OCTOBOX_IO is not set' do
    check_redirected
    sign_in_as(@user)
    check_redirected
  end

  test 'privacy page is shown when OCTOBOX_IO is set' do
    set_env('OCTOBOX_IO', 'true') do
      check_privacy_page_contents
      sign_in_as(@user)
      check_privacy_page_contents
    end
  end

  test 'index page provides link to privacy page when OCTOBOX_IO is set' do
    set_env('OCTOBOX_IO', 'true') do
      get root_path
      assert_select "a[href=?]", privacy_path, text: 'Privacy Policy'
      sign_in_as(@user)
      get root_path
      assert_select "a[href=?]", privacy_path, text: 'Privacy Policy'
    end
  end
end
