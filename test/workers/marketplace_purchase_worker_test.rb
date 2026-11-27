# frozen_string_literal: true
require 'test_helper'

class MarketplacePurchaseWorkerTest < ActiveSupport::TestCase
  setup do
    @plan = create(:subscription_plan, github_id: 9, name: 'Private projects')
    @payload = {
      'action' => 'purchased',
      'marketplace_purchase' => {
        'account' => { 'id' => 1060, 'login' => 'andrew' },
        'billing_cycle' => 'monthly',
        'unit_count' => 1,
        'on_free_trial' => true,
        'free_trial_ends_on' => '2026-01-15T00:00:00Z',
        'next_billing_date' => '2026-02-01T00:00:00Z',
        'plan' => { 'id' => 9 }
      }
    }
  end

  test 'records a new purchase' do
    MarketplacePurchaseWorker.new.perform(@payload)

    purchase = SubscriptionPurchase.find_by(account_id: 1060)
    assert_equal @plan, purchase.subscription_plan
    assert_equal 'monthly', purchase.billing_cycle
    assert_equal 1, purchase.unit_count
    assert purchase.on_free_trial
    assert_equal Time.utc(2026, 2, 1), purchase.next_billing_date
  end

  test 'updates the existing purchase for an account' do
    old_plan = create(:subscription_plan, github_id: 8)
    purchase = SubscriptionPurchase.create!(account_id: 1060, subscription_plan: old_plan, unit_count: 1)
    @payload['marketplace_purchase']['unit_count'] = 0

    MarketplacePurchaseWorker.new.perform(@payload)

    assert_equal 1, SubscriptionPurchase.where(account_id: 1060).count
    assert_equal @plan, purchase.reload.subscription_plan
    assert_equal 0, purchase.unit_count
  end

  test 'syncs plans when the purchase is for a plan it has not seen' do
    stub_access_tokens_request
    @payload['marketplace_purchase']['plan']['id'] = 10
    plans = [{ id: 10, name: 'Open source', monthly_price_in_cents: 0, yearly_price_in_cents: 0 }]
    stub_request(:get, %r{https://api\.github\.com/marketplace_listing/plans})
      .to_return(status: 200, body: plans.to_json, headers: { 'Content-Type' => 'application/json' })

    MarketplacePurchaseWorker.new.perform(@payload)

    purchase = SubscriptionPurchase.find_by(account_id: 1060)
    assert_equal 'Open source', purchase.subscription_plan.name
  end
end

class MarketplacePurchaseWorkerConcurrencyTest < ActiveSupport::TestCase
  self.use_transactional_tests = false

  teardown do
    SubscriptionPurchase.delete_all
    SubscriptionPlan.delete_all
  end

  test 'two purchases for the same new plan share one plan' do
    stub_access_tokens_request
    both_syncing = Concurrent::CyclicBarrier.new(2)
    plans = [{ id: 10, name: 'Open source', monthly_price_in_cents: 0, yearly_price_in_cents: 0 }]
    stub_request(:get, %r{https://api\.github\.com/marketplace_listing/plans}).to_return do
      both_syncing.wait(5)
      { status: 200, body: plans.to_json, headers: { 'Content-Type' => 'application/json' } }
    end

    [1060, 1061].map do |account_id|
      Thread.new do
        payload = { 'marketplace_purchase' => { 'account' => { 'id' => account_id }, 'unit_count' => 1, 'plan' => { 'id' => 10 } } }
        ActiveRecord::Base.connection_pool.with_connection { MarketplacePurchaseWorker.new.perform(payload) }
      end
    end.each(&:join)

    assert_equal 1, SubscriptionPlan.where(github_id: 10).count
    assert_equal [SubscriptionPlan.find_by(github_id: 10).id], SubscriptionPurchase.distinct.pluck(:subscription_plan_id)
    assert_equal 2, SubscriptionPurchase.count
  end
end
