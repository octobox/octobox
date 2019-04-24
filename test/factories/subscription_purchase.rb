FactoryBot.define do
  factory :subscription_purchase do
    app_installation
    subscription_plan
  end
end
