namespace :marketplace do
  task sync_plans: :environment do
    next unless Octobox.octobox_io?

    SubscriptionPlan.sync_plans
  end

  task sync_subscriptions: :environment do
    return unless Octobox.octobox_io?

    SubscriptionPlan.github.find_each(&:sync_purchases)
  end
end
