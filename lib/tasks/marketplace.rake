namespace :marketplace do
  task sync_plans: :environment do
    next unless Octobox.io?

    SubscriptionPlan.sync_plans
  end

  task sync_subscriptions: :environment do
    return unless Octobox.io?

    SubscriptionPlan.github.find_each(&:sync_purchases)
  end
end
