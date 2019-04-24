FactoryBot.define do
  factory :subscription_purchase do
    sequence(:number, 100) { |n| n }
  end
end
