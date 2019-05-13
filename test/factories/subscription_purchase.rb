FactoryBot.define do
  factory :subscription_purchase do
    app_installation
    subscription_plan
    unit_count { 1 }
  end
end
