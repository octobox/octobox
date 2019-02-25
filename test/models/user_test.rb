# frozen_string_literal: true
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  setup do
    @user = create(:user)
    stub_user_request(user: @user)
    stub_notifications_request
  end

  def assert_error_present(model_object, error)
    refute model_object.valid?
    assert model_object.errors[error[0]].include? error[1]
  end

  test 'must have a github id' do
    @user.github_id = nil
    refute @user.valid?
  end

  test 'must have a unique github_id' do
    user = User.create(github_id: @user.github_id, access_token: 'abcdefg')
    refute user.valid?
  end

  test 'must have a unique access_token' do
    user = User.create(github_id: 42, access_token: @user.access_token)
    refute user.valid?
  end

  test 'must have a github_login' do
    @user.github_login = nil
    refute @user.valid?
  end

  test "#admin? returns true when the users's github is included in the ENV variable" do
    Octobox.config.stubs(:github_admin_ids).returns(["#{@user.github_id}"])
    assert_predicate @user, :admin?
  end

  test "users are not admins by default" do
    refute_predicate @user, :admin?
  end

  test '#effective_access_token returns personal_access_token if it is defined' do
    stub_personal_access_tokens_enabled
    user = build(:token_user)
    assert_equal user.personal_access_token, user.effective_access_token
  end

  test '#effective_access_token returns access_token if personal_access_tokens_enabled? is false' do
    stub_personal_access_tokens_enabled(value: false)
    user = build(:token_user)
    assert_equal user.access_token, user.effective_access_token
  end

  test '#effective_access_token returns access_token if no personal_access_token is defined' do
    stub_personal_access_tokens_enabled
    assert_equal @user.access_token, @user.effective_access_token
  end

  test '.find_by_auth_hash finds a User by their github_id' do
    omniauth_config     = OmniAuth.config.mock_auth[:github]
    omniauth_config.uid = @user.github_id
    assert_equal @user, User.find_by_auth_hash(omniauth_config)
  end

  test '#assign_from_auth_hash updates the users github_id and access_token' do
    omniauth_config                   = OmniAuth.config.mock_auth[:github]
    omniauth_config.uid               = 1
    omniauth_config.credentials.token = 'abcdefg'

    @user.assign_from_auth_hash(omniauth_config)

    assert_equal 1, @user.github_id
    assert_equal 'abcdefg', @user.access_token
  end

  test '#github_client returns an Octokit::Client with the correct access_token' do
    assert_equal @user.github_client.class, Octokit::Client
    assert_equal @user.github_client.access_token, @user.access_token
  end

  test '#github_client returns an Octokit::Client with the correct access_token after adding personal_access_token' do
    stub_personal_access_tokens_enabled
    assert_equal @user.github_client.class, Octokit::Client
    assert_equal @user.access_token, @user.github_client.access_token
    @user.personal_access_token = '67890'
    stub_user_request(user: @user)
    @user.save
    assert_equal '67890', @user.github_client.access_token
  end

  test '#masked_personal_access_token returns empty string if personal_access_token is missing' do
    assert_equal @user.masked_personal_access_token, ''
  end

  test '#masked_personal_access_token returns stars with the last 8 chars of token' do
    @user.personal_access_token = 'abcdefghijklmnopqrstuvwxyz'
    assert_equal @user.masked_personal_access_token, '********************************stuvwxyz'
  end

  test 'rejects refresh_interval over a day' do
    @user.refresh_interval = 90_000_000
    refute @user.valid?
    assert_error_present(@user, User::ERRORS[:refresh_interval_size])
  end

  test 'rejects negative refresh_interval' do
    @user.refresh_interval = -90_000
    refute @user.valid?
    assert_error_present(@user, User::ERRORS[:refresh_interval_size])
  end

  test 'sets refresh interval' do
    @user.refresh_interval = 60_000
    @user.save
    assert_equal 60_000, @user.refresh_interval
  end

  test 'sync_notifications sets job id and enqueues job' do
    @user.sync_notifications
    @user.reload
    assert_not_nil @user.sync_job_id
    assert_equal 1, SyncNotificationsWorker.jobs.size
  end

  [{refresh_interval: 90_000, minimum_refresh_interval: 0, expected_result: nil},
   {refresh_interval: 90_000, minimum_refresh_interval: 60, expected_result: 60 * 60_000},
   {refresh_interval: 0, minimum_refresh_interval: 60, expected_result: nil},
   {refresh_interval: 0, minimum_refresh_interval: 0, expected_result: nil}
  ].each do |t|
    test "effective_refresh_interval returns #{t[:expected_result]} when minimum_refresh_interval is #{t[:minimum_refresh_interval]} and refresh_interval is #{t[:refresh_interval]}" do
      stub_minimum_refresh_interval(t[:minimum_refresh_interval])
      @user.refresh_interval = t[:refresh_interval]
      @user.save
      if t[:expected_result].nil?
        assert_nil @user.effective_refresh_interval
      else
        assert_equal t[:expected_result], @user.effective_refresh_interval
      end
    end
  end

  test 'user cannot comment on an open source repo without repo scope' do
    stub_env_var('FETCH_SUBJECT', 'false')
    repository = create(:repository, private: false)
    subject = create(:subject, repository: repository)
    refute @user.can_comment?(subject)
  end

  test 'user can comment on an open source repo with repo scope' do
    stub_env_var('FETCH_SUBJECT', 'true')
    repository = create(:repository, private: false)
    subject = create(:subject, repository: repository)
    
    assert @user.can_comment?(subject)
  end

  test 'user cannot comment on a private subject' do
    stub_env_var('FETCH_SUBJECT', 'false')
    repository = create(:repository, private: true)
    subject = create(:subject, repository: repository)

    refute @user.can_comment?(subject)
  end

  test 'user cannot comment on a private subject without write permissions' do
    stub_env_var('FETCH_SUBJECT', 'false')
    repository = create(:repository, private: true)
    create(:app_installation, repositories: [repository], permission_issues: 'read')
    subject = create(:subject, repository: repository)

    refute @user.can_comment?(subject)
  end

  test 'user can comment on a private subject with an app installation' do
    @user = create(:user, app_token: SecureRandom.hex(20))
    repository = create(:repository, private: true)
    create(:app_installation, repositories: [repository], permission_issues: 'write')
    subject = create(:subject, repository: repository)

    assert @user.can_comment?(subject)
  end

  test 'user cannot comment on a private subject without an app installation token' do
    stub_env_var('FETCH_SUBJECT', 'false')
    
    repository = create(:repository, private: true)
    create(:app_installation, repositories: [repository], permission_issues: 'write')
    subject = create(:subject, repository: repository)

    refute @user.can_comment?(subject)
  end

  test 'user can comment on a subject with a personal token' do
    stub_personal_access_tokens_enabled
    stub_user_request(user: build(:token_user))

    @token_user = create(:token_user)

    repository = create(:repository, private: true)
    create(:app_installation, repositories: [repository])
    subject = create(:subject, repository: repository)

    assert @token_user.can_comment?(subject)
  end

  test 'user can comment if running under repo scope' do
    stub_env_var('FETCH_SUBJECT', 'true')
    repository = create(:repository, private: true)
    subject = create(:subject, repository: repository)

    assert @user.can_comment?(subject)
  end

  test 'comments are created using github tokens on public repositories' do
    user = create(:user)

    repository = create(:repository, private: false)
    subject = create(:subject, repository: repository)
    comment = create(:comment, subject: subject)

    assert_equal user.comment_client(comment).class, Octokit::Client
    assert_equal user.comment_client(comment).access_token, user.access_token
  end

  test 'comments are created using github app tokens on private repositories' do
    @app_user = create(:app_user)

    repository = create(:repository, private: true)
    create(:app_installation, repositories: [repository], permission_issues: 'write')
    subject = create(:subject, repository: repository)
    comment = create(:comment, subject: subject)

    assert_equal @app_user.comment_client(comment).class, Octokit::Client
    assert_equal @app_user.comment_client(comment).access_token, @app_user.app_token
  end

end
