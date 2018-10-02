FactoryBot.define do
  factory :label do
    sequence(:github_id, 1000000) { |n| n }
    name { 'bug' }
    color { '#AAAAAA' }
  end
end
