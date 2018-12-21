# frozen_string_literal: true
require 'test_helper'

class SubscriptionPlanTest < ActiveSupport::TestCase
  setup do
    @subscription_plan = create(:subscription_plan)
  end

  test 'must have a name' do
    @subscription_plan.name = nil
    refute @subscription_plan.valid?
  end

  test 'private_repositories_enabled for "private" plans' do
    @subscription_plan.name = 'Private projects'
    assert @subscription_plan.private_repositories_enabled?
  end

  test 'private_repositories_enabled for "personal" plans' do
    @subscription_plan.name = 'Personal projects'
    assert @subscription_plan.private_repositories_enabled?
  end

  test 'private_repositories_enabled for "other" plans' do
    @subscription_plan.name = 'Free'
    refute @subscription_plan.private_repositories_enabled?
  end

  test 'github?' do
    @subscription_plan.github_id = 1
    assert @subscription_plan.github?
  end

  test 'not github?' do
    @subscription_plan.github_id = nil
    refute @subscription_plan.github?
  end

  test 'open_collective?' do
    @subscription_plan.name = 'Open Collective Sponsor'
    assert @subscription_plan.open_collective?
  end

  test 'not open_collective?' do
    @subscription_plan.name = 'Free'
    refute @subscription_plan.open_collective?
  end
end
