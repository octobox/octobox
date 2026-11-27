# frozen_string_literal: true
require 'test_helper'

class SubscriptionPurchaseTest < ActiveSupport::TestCase
  test 'edit_url is the marketplace for a GitHub plan' do
    Octobox.config.stubs(:marketplace_url).returns('https://github.com/marketplace/octobox')
    purchase = create(:subscription_purchase, subscription_plan: create(:subscription_plan, github_id: 1))

    assert_equal 'https://github.com/marketplace/octobox', purchase.edit_url
  end

  test 'edit_url is Open Collective for an Open Collective plan' do
    purchase = create(:subscription_purchase, subscription_plan: create(:subscription_plan, name: 'Open Collective Individual'))

    assert_equal 'https://opencollective.com/octobox', purchase.edit_url
  end

  test 'edit_url is nil for any other plan' do
    assert_nil create(:subscription_purchase).edit_url
  end

  test 'private_repositories_enabled? needs an active purchase of a private plan' do
    plan = create(:subscription_plan, name: 'Private projects')

    assert create(:subscription_purchase, subscription_plan: plan, unit_count: 1).private_repositories_enabled?
    refute create(:subscription_purchase, subscription_plan: plan, unit_count: 0).private_repositories_enabled?
    refute create(:subscription_purchase, unit_count: 1).private_repositories_enabled?
  end
end
