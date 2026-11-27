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

  test 'sync_plans creates and updates plans from the GitHub Marketplace' do
    stub_access_tokens_request
    @subscription_plan.update(github_id: 9)
    plans = [
      { id: 9, name: 'Private projects', description: 'For private repositories', monthly_price_in_cents: 1000,
        yearly_price_in_cents: 10000, price_model: 'flat-rate', has_free_trial: true, unit_name: nil, number: 2 },
      { id: 10, name: 'Open source', description: 'Free', monthly_price_in_cents: 0,
        yearly_price_in_cents: 0, price_model: 'free', has_free_trial: false, unit_name: nil, number: 1 }
    ]
    stub_request(:get, %r{https://api\.github\.com/marketplace_listing/plans})
      .to_return(status: 200, body: plans.to_json, headers: { 'Content-Type' => 'application/json' })

    SubscriptionPlan.sync_plans

    assert_equal 2, SubscriptionPlan.count
    assert_equal 'Private projects', @subscription_plan.reload.name
    assert_equal 1000, @subscription_plan.monthly_price_in_cents
    assert @subscription_plan.has_free_trial
    assert_equal 'Open source', SubscriptionPlan.find_by(github_id: 10).name
  end

  test 'sync_purchases records the accounts that bought the plan' do
    stub_access_tokens_request
    @subscription_plan.update(github_id: 9)
    accounts = [
      { id: 1060, login: 'andrew', marketplace_purchase: { billing_cycle: 'monthly', unit_count: 1, on_free_trial: false,
                                                           free_trial_ends_on: nil, updated_at: '2026-01-02T03:04:05Z',
                                                           next_billing_date: '2026-02-02T00:00:00Z' } }
    ]
    stub_request(:get, %r{https://api\.github\.com/marketplace_listing/plans/9/accounts})
      .to_return(status: 200, body: accounts.to_json, headers: { 'Content-Type' => 'application/json' })

    @subscription_plan.sync_purchases

    purchase = SubscriptionPurchase.find_by(account_id: 1060)
    assert_equal @subscription_plan, purchase.subscription_plan
    assert_equal 'monthly', purchase.billing_cycle
    assert_equal 1, purchase.unit_count
    assert_equal Time.utc(2026, 2, 2), purchase.next_billing_date
  end
end
