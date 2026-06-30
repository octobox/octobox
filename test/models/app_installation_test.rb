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
end
