# frozen_string_literal: true
require 'test_helper'

class AdminConstraintTest < ActiveSupport::TestCase
  def request_for(user_id)
    stub(cookie_jar: stub(signed: { user_id: user_id }))
  end

  test 'matches a signed in admin' do
    user = create(:user)
    Octobox.config.stubs(:github_admin_ids).returns([user.github_id.to_s])

    assert AdminConstraint.new.matches?(request_for(user.id))
  end

  test 'does not match a signed in user who is not an admin' do
    Octobox.config.stubs(:github_admin_ids).returns([])

    refute AdminConstraint.new.matches?(request_for(create(:user).id))
  end

  test 'does not match when the user cannot be found' do
    refute AdminConstraint.new.matches?(request_for(0))
  end
end
