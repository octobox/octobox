FactoryBot.define do
  factory :repository do
    sequence(:github_id, 1000000){|n| n}
    full_name { 'octobox/octobox' }
  end
end
