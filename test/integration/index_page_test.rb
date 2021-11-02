require 'test_helper'

class IndexPageTest < ActionDispatch::IntegrationTest
  def has_open_collective
    assert_select 'h5', text: 'Support the community'
    assert_select 'h6', text: 'Pay by donation on Open Collective.'
    assert_match 'Unlimited private repositories', response.body
    assert_match 'Unlimited public repositories', response.body
    assert_match 'Unlimited collaborators', response.body
    assert_match 'Next: make your donation on Open Collective', response.body
  end

  def has_github
    assert_select 'h5', text: 'Support the company'
    assert_select 'h6', text: 'Buy from the GitHub marketplace.'
    assert_match 'Next: confirm your purchase on GitHub', response.body
  end

  test 'index page without login is home page' do
    get root_path
    assert_select "a[href=?]", '/auth/github', text: 'Sign in'
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
    assert_select "a[href=?]", logout_path, text: 'Logout'
    assert_match 'Inbox', response.body
    assert_match 'Archive', response.body
    assert_match 'Starred', response.body
    assert_match 'Read', response.body
    assert_match 'Unread', response.body
    assert_match 'Last sync', response.body
  end

  test 'home page shows GitHub section if GITHUB_APP_ID is set' do
    set_env('GITHUB_APP_ID', '12345') do
      get root_path
      assert_select 'h3', text: 'Liven up notifications with the GitHub app'
      assert_match 'Octobox will pull basic public and private notification', response.body
      assert_match 'Install the GitHub app', response.body
    end
  end

  test 'home page shows Octobox section if OCTOBOX_IO is set to true' do
    set_env('OCTOBOX_IO', 'true') do
      get root_path
      assert_match 'notifications managed, and counting', response.body
      assert_select 'h3', text: 'Pricing'
      assert_match 'free for open source', response.body
      assert_match 'basic notifications for private projects', response.body

      has_open_collective
      has_github

      assert_select 'h3', text: 'Used by developers from'
    end
  end

  test 'home page has link to the pricing page' do
    set_env('OCTOBOX_IO', 'true') do
      get root_path
      assert_select "a[href=?]", '/pricing#why', text: 'Read more about our pricing strategy'
    end
  end

  test 'The pricing page has the expected content' do
    set_env('OCTOBOX_IO', 'true') do
      get pricing_path
      assert_select 'h1', text: 'Octobox'
      assert_select 'h3', text: 'One product, two ways to pay'
      assert_match 'free for open source', response.body
      assert_match 'access to private projects', response.body

      has_open_collective
      has_github

      assert_select 'h2', text: 'What... Why?'
      assert_select 'h5', text: 'An experiment in open source sustainability'
      assert_match 'Octobox is primarily maintained by Andrew Nesbitt and Benjamin Nickolls.', response.body

      assert_select 'h5', text: 'Do you prefer supporting a commercial provider, or the community itself?'
      assert_match 'Octobox.io operated by Octobox Ltd.', response.body

      assert_select 'h5', text: 'Why does this matter?'
      assert_match 'provide a blueprint for others to follow', response.body
    end
  end
end
