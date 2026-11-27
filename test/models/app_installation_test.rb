# frozen_string_literal: true
require 'test_helper'

class AppInstallationTest < ActiveSupport::TestCase
  setup do
    @app_installation = create(:app_installation)
  end

  test 'must have a github id' do
    @app_installation.github_id = nil
    refute @app_installation.valid?
  end

  test 'must have a unique github_id' do
    app_installation = build(:app_installation, github_id: @app_installation.github_id)
    refute app_installation.valid?
  end

  test 'must have an account login' do
    @app_installation.account_login = nil
    refute @app_installation.valid?
  end

  test 'must have a account id' do
    @app_installation.account_id = nil
    refute @app_installation.valid?
  end

  test 'supports large GitHub account ids' do
    large_github_id = 2_147_483_648
    app_installation = create(
      :app_installation,
      app_id: large_github_id,
      account_id: large_github_id,
      target_id: large_github_id
    )

    assert_equal large_github_id, app_installation.app_id
    assert_equal large_github_id, app_installation.account_id
    assert_equal large_github_id, app_installation.target_id
  end

  test 'remove_repositories destroys the repositories and their subjects' do
    removed = create(:repository, full_name: 'andrew/removed', app_installation: @app_installation)
    kept = create(:repository, full_name: 'andrew/kept', app_installation: @app_installation)
    removed_subject = create(:subject, repository_full_name: 'andrew/removed')
    kept_subject = create(:subject, repository_full_name: 'andrew/kept')

    @app_installation.remove_repositories([{ 'id' => removed.github_id }, { 'id' => 123 }])

    refute Repository.exists?(removed.id)
    refute Subject.exists?(removed_subject.id)
    assert Repository.exists?(kept.id)
    assert Subject.exists?(kept_subject.id)
  end

  test 'settings_url points at the user installation settings' do
    @app_installation.update(account_type: 'User')
    assert_equal "https://github.com/settings/installations/#{@app_installation.github_id}", @app_installation.settings_url
  end

  test 'settings_url points at the organization installation settings' do
    @app_installation.update(account_type: 'Organization', account_login: 'octobox')
    assert_equal "https://github.com/organizations/octobox/settings/installations/#{@app_installation.github_id}", @app_installation.settings_url
  end

  test 'github_avatar_url uses the account login' do
    assert_equal 'https://github.com/andrew.png', @app_installation.github_avatar_url
  end

  test 'private_repositories_enabled? is true when not running as octobox.io' do
    Octobox.stubs(:io?).returns(false)
    assert @app_installation.private_repositories_enabled?
  end

  test 'private_repositories_enabled? on octobox.io needs a purchase of a private plan' do
    Octobox.stubs(:io?).returns(true)
    refute @app_installation.private_repositories_enabled?

    plan = create(:subscription_plan, name: 'Private projects')
    create(:subscription_purchase, app_installation: @app_installation, subscription_plan: plan)

    assert @app_installation.reload.private_repositories_enabled?
  end

  test 'read_issues? is true for read and write permissions' do
    refute @app_installation.read_issues?
    refute build(:app_installation, permission_issues: 'none').read_issues?
    assert build(:app_installation, permission_issues: 'read').read_issues?
    assert build(:app_installation, permission_issues: 'write').read_issues?
  end

  test 'sync updates the installation from GitHub' do
    stub_access_tokens_request
    stub_request(:get, "https://api.github.com/app/installations/#{@app_installation.github_id}")
      .to_return(status: 200, body: file_fixture('app_installation.json'), headers: { 'Content-Type' => 'application/json' })

    @app_installation.sync

    assert_equal 'github', @app_installation.reload.account_login
    assert_equal 'Organization', @app_installation.target_type
    assert_equal 'write', @app_installation.permission_issues
  end

  test 'sync destroys an installation that GitHub no longer has' do
    stub_access_tokens_request
    stub_request(:get, "https://api.github.com/app/installations/#{@app_installation.github_id}").to_return(status: 404)

    @app_installation.sync

    refute AppInstallation.exists?(@app_installation.id)
  end

  test 'sync_repositories adds the repositories the installation can access' do
    stub_access_tokens_request
    body = { total_count: 1, repositories: [{ id: 42, full_name: 'andrew/installed', private: true }] }.to_json
    stub_request(:get, %r{https://api\.github\.com/installation/repositories})
      .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

    @app_installation.sync_repositories

    repository = Repository.find_by(github_id: 42)
    assert_equal 'andrew/installed', repository.full_name
    assert_equal 'andrew', repository.owner
    assert repository.private?
    assert_equal @app_installation, repository.app_installation
  end

  test 'sync_repositories ignores client errors from GitHub' do
    stub_access_tokens_request
    stub_request(:get, %r{https://api\.github\.com/installation/repositories}).to_return(status: 403)

    assert_nil @app_installation.sync_repositories
    assert_equal 0, Repository.count
  end

  test 'sync_all creates and updates installations from GitHub' do
    stub_access_tokens_request
    existing = create(:app_installation, github_id: 293804, account_login: 'old-name')
    remote = JSON.parse(file_fixture('app_installation.json').read)
    unseen = remote.deep_merge('id' => 293805, 'account' => { 'login' => 'new-org' })
    stub_request(:get, %r{https://api\.github\.com/app/installations})
      .to_return(status: 200, body: [remote, unseen].to_json, headers: { 'Content-Type' => 'application/json' })

    assert_difference 'AppInstallation.count', 1 do
      AppInstallation.sync_all
    end

    assert_equal 'github', existing.reload.account_login
    assert_equal 'new-org', AppInstallation.find_by(github_id: 293805).account_login
  end
end
