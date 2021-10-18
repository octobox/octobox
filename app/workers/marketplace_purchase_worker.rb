# frozen_string_literal: true

class MarketplacePurchaseWorker
  include Sidekiq::Worker
  sidekiq_options queue: :marketplace, lock: :until_and_while_executing

  def perform(payload)
    purchase = SubscriptionPurchase.find_or_initialize_by(account_id: payload['marketplace_purchase']['account']['id'])
    plan = SubscriptionPlan.find_by_github_id(payload['marketplace_purchase']['plan']['id'])

    purchase.update({
      billing_cycle:      payload['marketplace_purchase']['billing_cycle'],
      unit_count:         payload['marketplace_purchase']['unit_count'],
      on_free_trial:      payload['marketplace_purchase']['on_free_trial'],
      free_trial_ends_on: payload['marketplace_purchase']['free_trial_ends_on'],
      updated_at:         payload['marketplace_purchase']['updated_at'] || Time.current,
      next_billing_date:  payload['marketplace_purchase']['next_billing_date'],
      subscription_plan_id: plan.id
    })
  end
end
