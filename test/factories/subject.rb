FactoryBot.define do
  factory :subject do
    sequence(:url) { |n| "https://api.github.com/repos/octobox/octobox/issues/#{n}" }
    sequence(:github_id, 1000000) { |n| n }
    state { 'open' }
    author { 'andrew' }
    repository_full_name { 'octobox/octobox' }
  end
end
