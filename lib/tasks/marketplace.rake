namespace :marketplace do
  task sync_plans: :environment do
    next unless Octobox.config.marketplace_url

    SubscriptionPlan.sync_plans
  end

  task sync_subscriptions: :environment do
    return unless Octobox.config.marketplace_url

    SubscriptionPlan.github.find_each(&:sync_purchases)
  end
end
