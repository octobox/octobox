# frozen_string_literal: true
require 'test_helper'

class SyncInstallationPermissionsWorkerTest < ActiveSupport::TestCase
  test 'grants and removes access to match the installations GitHub lists for the user' do
    user = create(:user, app_token: SecureRandom.hex(20))
    listed = create(:app_installation)
    unlisted = create(:app_installation)
    user.app_installation_permissions.create!(app_installation: unlisted)
    body = { total_count: 1, installations: [{ id: listed.github_id }] }.to_json
    stub_request(:get, %r{https://api\.github\.com/user/installations})
      .to_return(status: 200, body: body, headers: { 'Content-Type' => 'application/json' })

    SyncInstallationPermissionsWorker.new.perform(user.id)

    assert_equal [listed], user.reload.app_installations.to_a
  end

  test 'does nothing for a user that no longer exists' do
    assert_nil SyncInstallationPermissionsWorker.new.perform(0)
    assert_not_requested :get, %r{https://api\.github\.com/user/installations}
  end
end
