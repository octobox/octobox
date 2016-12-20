# frozen_string_literal: true
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'must have a github id' do
    user = users(:andrew)
    user.github_id = nil
    refute user.valid?
  end

  test 'must have a unique github_id' do
    user = User.create(github_id: users(:andrew), access_token: 'abcdefg')
    refute user.valid?
  end

  test 'must have an access_token' do
    user = users(:andrew)
    user.access_token = nil
    refute user.valid?
  end

  test 'must have a unique access_token' do
    user = User.create(github_id: 42, access_token: users(:andrew).access_token)
    refute user.valid?
  end

  test 'must have a github_login' do
    user = users(:andrew)
    user.github_login = nil
    refute user.valid?
  end

  test '.find_by_auth_hash finds a User by their github_id' do
    omniauth_config     = OmniAuth.config.mock_auth[:github]
    omniauth_config.uid = users(:andrew).github_id
    assert_equal users(:andrew), User.find_by_auth_hash(omniauth_config)
  end

  test '#assign_from_auth_hash updates the users github_id and access_token' do
    user                              = users(:andrew)
    omniauth_config                   = OmniAuth.config.mock_auth[:github]
    omniauth_config.uid               = 1
    omniauth_config.credentials.token = 'abcdefg'

    user.assign_from_auth_hash(omniauth_config)

    assert_equal 1, user.github_id
    assert_equal 'abcdefg', user.access_token
  end

  test '#github_client returns an Octokit::Client with the correct access_token' do
    user = users(:andrew)
    assert_equal user.github_client.class, Octokit::Client
    assert_equal user.github_client.access_token, user.access_token
  end

  test '#archive_all archives all notifications' do
    user = users(:andrew)
    5.times.each { create(:notification, user: user, archived: false) }
    user.archive_all

    user.notifications.each do |n|
      assert_equal n.archived, true
    end
  end

  test "triggers sync_notifications on save" do
    notifications_url = %r{https://api.github.com/notifications}

    body     = '[]'
    headers  = { 'Content-Type' => 'application/json' }
    response = { status: 200, body: body, headers: headers }

    stub_request(:get, notifications_url).to_return(response)

    User.create(github_id: 42, github_login: 'douglas_adams', access_token: 'abcdefg')

    assert_requested :get, notifications_url
  end
end
