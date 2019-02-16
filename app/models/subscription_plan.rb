class SubscriptionPlan < ApplicationRecord
  has_many :subscription_purchases

  validates :name, presence: true

  scope :github, -> { where.not(github_id: nil) }

  def private_repositories_enabled?
    name.match?(/private/i) || name.match?(/personal/i) || name.match?(/individual/i) || name.match?(/organisation/i)
  end

  def github?
    github_id.present?
  end

  def open_collective?
    name.match?(/Open Collective/i)
  end

  def self.sync_plans
    Octobox.github_app_client.list_plans.each do |remote_plan|
      plan = find_or_initialize_by(github_id: remote_plan.id)
      plan.update({
        name:                   remote_plan.name,
        description:            remote_plan.description,
        monthly_price_in_cents: remote_plan.monthly_price_in_cents,
        yearly_price_in_cents:  remote_plan.yearly_price_in_cents,
        price_model:            remote_plan.price_model,
        has_free_trial:         remote_plan.has_free_trial,
        unit_name:              remote_plan.unit_name,
        number:                 remote_plan.number
      })
    end
  end

  def sync_purchases
    Octobox.github_app_client.list_accounts_for_plan(self.github_id).each do |remote_purchase|
      purchase = SubscriptionPurchase.find_or_initialize_by(account_id: remote_purchase.id)

      purchase.update({
        billing_cycle:      remote_purchase.marketplace_purchase.billing_cycle,
        unit_count:         remote_purchase.marketplace_purchase.unit_count,
        on_free_trial:      remote_purchase.marketplace_purchase.on_free_trial,
        free_trial_ends_on: remote_purchase.marketplace_purchase.free_trial_ends_on,
        updated_at:         remote_purchase.marketplace_purchase.updated_at,
        next_billing_date:  remote_purchase.marketplace_purchase.next_billing_date,
        subscription_plan_id: self.id
      })
    end
  end
end
