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

end
