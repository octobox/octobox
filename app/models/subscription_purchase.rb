class SubscriptionPurchase < ApplicationRecord
  belongs_to :subscription_plan
  belongs_to :app_installation, foreign_key: :account_id, primary_key: :account_id

  validates :account_id, presence: true
  validates :subscription_plan_id, presence: true

  scope :active, -> { where('unit_count > 0') }

  def active?
    unit_count > 0
  end

  def private_repositories_enabled?
    active? && subscription_plan.private_repositories_enabled?
  end

  def edit_url
    return Octobox.config.marketplace_url if subscription_plan.github?
    return "https://opencollective.com/octobox" if subscription_plan.open_collective?
  end
end
