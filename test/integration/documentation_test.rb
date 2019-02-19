require 'test_helper'

class DocumentationTest < ActionDispatch::IntegrationTest
  def test_documentation_content
    get documentation_path
    assert_select 'h1', text: 'Documentation'
    assert_match 'spend less time managing', response.body
    assert_match 'more time getting things done', response.body
    assert_select 'h2', text: 'Accessing Octobox'
    assert_select 'h2', text: 'Using Octobox'
    assert_match 'Octobox helps you triage notifications from GitHub.', response.body
    assert_select 'h3', text: 'Archiving'
    assert_select 'h3', text: 'Starring'
    assert_select 'h3', text: 'Muting'
    assert_select 'h3', text: 'Syncing'
    assert_select 'h2', text: 'Shortcuts'
    assert_match 'full set of keyboard shortcuts', response.body
    assert_match 'Move down the list', response.body
    assert_match 'Move up the list', response.body
    assert_match 'Star current notification', response.body
    assert_match 'Mark current notification', response.body
    assert_select 'h2', text: 'Navigating Octobox'
    assert_match 'The state of the underlying issue or PR', response.body
    assert_select 'h2', text: 'Searching Octobox'
    assert_match "Octobox's search bar supports the following filter prefixes", response.body
    assert_select 'h5', text: 'Supported prefixes'
    assert_match 'status:success', response.body
    assert_select 'h2', text: 'API Documentation'
    assert_match 'key which you can generate and regenerate', response.body
    assert_select 'h2', text: 'Support'
    assert_match 'Octobox.io is a small community of people supporting the service.', response.body
    assert_match 'We do not offer formal support processes.', response.body
  end

  test 'documentation page has the expected content' do
    test_documentation_content
  end

  test 'support page leads to documentation page' do
    test_documentation_content
  end

  test 'index page with login has link to documentation page' do
    stub_notifications_request
    stub_comments_requests
    stub_fetch_subject_enabled(value: false)
    @user = create(:user)
    sign_in_as(@user)
    get root_path
    assert_select "a[href=?]", documentation_path, text: 'User Documentation'
  end

  test 'index page without login has link to documentation page' do
    get root_path
    assert_select "a[href=?]", documentation_path, text: 'More Info'
    assert_select "a[href=?]", documentation_path, text: 'documentation'
  end
end
