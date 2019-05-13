require 'test_helper'

class ConfiguratorTest < ActiveSupport::TestCase

  [
    {env_value: nil, expected: 'https://github.com/octobox/octobox'},
    {env_value: '', expected: 'https://github.com/octobox/octobox'},
    {env_value: ' ', expected: 'https://github.com/octobox/octobox'},
    {env_value: 'https://github.com/foo/bar', expected: 'https://github.com/foo/bar'}
  ].each do |t|
    env_value_string = t[:env_value].nil? ? 'nil' : "'#{t[:env_value]}'"
    test "When ENV['SOURCE_REPO'] is #{env_value_string}, config.source_repo is '#{t[:expected]}'" do
      stub_env_var('SOURCE_REPO', t[:env_value])
      assert_equal t[:expected], Octobox.config.source_repo
    end
  end

  test "config.scopes defaults to 'notifications'" do
    assert_equal 'notifications', Octobox.config.scopes
  end

  test "when ENV['RESTRICTED_ACCESS_ENABLED'] is true, config.scopes includes read:org" do
    stub_env_var('RESTRICTED_ACCESS_ENABLED', 'true')
    assert_includes Octobox.config.scopes, 'read:org'
  end

  test "when ENV['FETCH_SUBJECT'] is true, config.scopes includes repo" do
    stub_env_var('FETCH_SUBJECT', 'true')
    assert_includes Octobox.config.scopes, 'repo'
  end

  test "when ENV['FETCH_SUBJECT'] is true and ENV['GITHUB_APP_ID'] is present, config.scopes does not include repo" do
    stub_env_var('FETCH_SUBJECT', 'true')
    stub_env_var('GITHUB_APP_ID', '12345')
    refute_includes 'repo', Octobox.config.scopes
  end

  test "when ENV['FETCH_SUBJECT'] is false, config.fetch_subject is false" do
    stub_env_var('FETCH_SUBJECT', 'false')
    assert_equal false, Octobox.config.fetch_subject
  end

  test "when ENV['FETCH_SUBJECT'] is nil, config.fetch_subject is false" do
    stub_env_var('FETCH_SUBJECT', '')
    assert_equal false, Octobox.config.fetch_subject
  end

  test "when ENV['FETCH_SUBJECT'] is true, config.fetch_subject is true" do
    stub_env_var('FETCH_SUBJECT', 'true')
    assert_equal true, Octobox.config.fetch_subject
  end

  test "when ENV['FETCH_SUBJECT'] is 1, config.fetch_subject is true" do
    stub_env_var('FETCH_SUBJECT', '1')
    assert_equal true, Octobox.config.fetch_subject
  end

  test "when ENV['FETCH_SUBJECT'] is 0, config.fetch_subject is false" do
    stub_env_var('FETCH_SUBJECT', '0')
    assert_equal false, Octobox.config.fetch_subject
  end

  test "when ENV['PERSONAL_ACCESS_TOKENS_ENABLED'] is false, config.personal_access_tokens_enabled is false" do
    stub_env_var('PERSONAL_ACCESS_TOKENS_ENABLED', 'false')
    assert_equal false, Octobox.config.personal_access_tokens_enabled
  end

  test "when ENV['PERSONAL_ACCESS_TOKENS_ENABLED'] is nil, config.personal_access_tokens_enabled is false" do
    stub_env_var('PERSONAL_ACCESS_TOKENS_ENABLED', '')
    assert_equal false, Octobox.config.personal_access_tokens_enabled
  end

  test "when ENV['PERSONAL_ACCESS_TOKENS_ENABLED'] is true, config.personal_access_tokens_enabled is true" do
    stub_env_var('PERSONAL_ACCESS_TOKENS_ENABLED', 'true')
    assert_equal true, Octobox.config.personal_access_tokens_enabled
  end

  test "when ENV['OCTOBOX_SIDEKIQ_SCHEDULE_ENABLED'] is false, config.sidekiq_schedule_enabled? is false" do
    stub_env_var('OCTOBOX_SIDEKIQ_SCHEDULE_ENABLED', 'false')
    assert_equal false, Octobox.config.sidekiq_schedule_enabled?
  end

  test "when ENV['OCTOBOX_SIDEKIQ_SCHEDULE_ENABLED'] is nil, config.sidekiq_schedule_enabled? is false" do
    stub_env_var('OCTOBOX_SIDEKIQ_SCHEDULE_ENABLED', '')
    assert_equal false, Octobox.config.sidekiq_schedule_enabled?
  end

  test "when ENV['OCTOBOX_SIDEKIQ_SCHEDULE_ENABLED'] is true, config.sidekiq_schedule_enabled? is true" do
    stub_env_var('OCTOBOX_SIDEKIQ_SCHEDULE_ENABLED', 'true')
    assert_equal true, Octobox.config.sidekiq_schedule_enabled?
  end

  test "when ENV['RESTRICTED_ACCESS_ENABLED'] is false, config.restricted_access_enabled is false" do
    stub_env_var('RESTRICTED_ACCESS_ENABLED', 'false')
    assert_equal false, Octobox.config.restricted_access_enabled
  end

  test "when ENV['RESTRICTED_ACCESS_ENABLED'] is nil, config.restricted_access_enabled is false" do
    stub_env_var('RESTRICTED_ACCESS_ENABLED', '')
    assert_equal false, Octobox.config.restricted_access_enabled
  end

  test "when ENV['RESTRICTED_ACCESS_ENABLED'] is true, config.restricted_access_enabled is true" do
    stub_env_var('RESTRICTED_ACCESS_ENABLED', 'true')
    assert_equal true, Octobox.config.restricted_access_enabled
  end

  test "when ENV['OPEN_IN_SAME_TAB'] is false, config.open_in_same_tab is false" do
    stub_env_var('OPEN_IN_SAME_TAB', 'false')
    assert_equal false, Octobox.config.open_in_same_tab
  end

  test "when ENV['OPEN_IN_SAME_TAB'] is nil, config.open_in_same_tab is false" do
    stub_env_var('OPEN_IN_SAME_TAB', '')
    assert_equal false, Octobox.config.open_in_same_tab
  end

  test "when ENV['OPEN_IN_SAME_TAB'] is true, config.open_in_same_tab is true" do
    stub_env_var('OPEN_IN_SAME_TAB', 'true')
    assert_equal true, Octobox.config.open_in_same_tab
  end

  test "when ENV['OPEN_IN_SAME_TAB'] is 1, config.open_in_same_tab is true" do
    stub_env_var('OPEN_IN_SAME_TAB', '1')
    assert_equal true, Octobox.config.open_in_same_tab
  end

  test "when ENV['OPEN_IN_SAME_TAB'] is 0, config.open_in_same_tab is false" do
    stub_env_var('OPEN_IN_SAME_TAB', '0')
    assert_equal false, Octobox.config.open_in_same_tab
  end

  test "when ENV['OCTOBOX_IO'] is false, config.octobox_io is false" do
    stub_env_var('OCTOBOX_IO', 'false')
    assert_equal false, Octobox.config.octobox_io
  end

  test "when ENV['OCTOBOX_IO'] is nil, config.octobox_io is false" do
    stub_env_var('OCTOBOX_IO', '')
    assert_equal false, Octobox.config.octobox_io
  end

  test "when ENV['OCTOBOX_IO'] is true, config.octobox_io is true" do
    stub_env_var('OCTOBOX_IO', 'true')
    assert_equal true, Octobox.config.octobox_io
  end

  test 'max_notifications_to_sync default value' do
    stub_env_var('MAX_NOTIFICATIONS_TO_SYNC', nil)
    assert_equal 500, Octobox.config.max_notifications_to_sync
  end

  test 'max_notifications_to_sync configured by ENV var' do
    stub_env_var('MAX_NOTIFICATIONS_TO_SYNC', 20)
    assert_equal 20, Octobox.config.max_notifications_to_sync
  end

  test 'max_concurrency default value' do
    stub_env_var('MAX_CONCURRENCY', nil)
    assert_equal 10, Octobox.config.max_concurrency
  end

  test 'max_concurrency configured by ENV var' do
    stub_env_var('MAX_CONCURRENCY', 20)
    assert_equal 20, Octobox.config.max_concurrency
  end

  test 'minimum_refresh_interval default value' do
    stub_env_var('MINIMUM_REFRESH_INTERVAL', nil)
    assert_nil Octobox.config.minimum_refresh_interval
  end

  test 'minimum_refresh_interval configured by ENV var' do
    stub_env_var('MINIMUM_REFRESH_INTERVAL', 20)
    assert_equal 20, Octobox.config.minimum_refresh_interval
  end

  test 'github_organization_id default value' do
    stub_env_var('GITHUB_ORGANIZATION_ID', nil)
    assert_nil Octobox.config.github_organization_id
  end

  test 'github_organization_id configured by ENV var' do
    stub_env_var('GITHUB_ORGANIZATION_ID', 20)
    assert_equal 20, Octobox.config.github_organization_id
  end

  test 'github_team_id default value' do
    stub_env_var('GITHUB_TEAM_ID', nil)
    assert_nil Octobox.config.github_team_id
  end

  test 'github_team_id configured by ENV var' do
    stub_env_var('GITHUB_TEAM_ID', 20)
    assert_equal 20, Octobox.config.github_team_id
  end
end
