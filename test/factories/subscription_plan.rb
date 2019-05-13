FactoryBot.define do
  factory :subscription_plan do
    name { 'Free projects' }
    sequence(:number, 100) { |n| n }
  end
end
