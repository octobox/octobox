FactoryBot.define do
  factory :app_installation do
    sequence(:github_id, 1000000){|n| n}
    account_login { 'andrew' }
    account_id { 1060 }
  end
end
