FactoryBot.define do
  factory :subject do
    sequence(:url) { |n| "https://api.github.com/repos/octobox/octobox/issues/#{n}" }
    sequence(:html_url) { |n| "https://github.com/octobox/octobox/issues/#{n}" }
    sequence(:github_id, 1000000) { |n| n }
    state { 'open' }
    author { 'andrew' }
    repository_full_name { 'octobox/octobox' }
    comment_count { 0 }
    sequence(:title) { |n| "issue number #{n}" }
  end
end
