FactoryBot.define do
  factory :notification do
    sequence(:github_id, 1000000) { |n| n }
    repository_id { 930405 }
    repository_full_name { "octobox/octobox" }
    repository_owner_name { "andrew" }
    subject_title { "Test" }
    sequence(:subject_url) { |n| "https://api.github.com/repos/#{repository_full_name}/issues/#{n}" }
    subject_type { "Issue" }
    reason { "subscribed" }
    unread { true }
    updated_at { "2015-06-22 14:37:57" }
    last_read_at { "2015-06-22 13:34:48 UTC" }
    sequence(:url) { |n| "https://api.github.com/notifications/threads/#{n}" }
    archived { false }
    starred { false }
    user

    factory :archived do
      repository_id { 2 }
      last_read_at { 5.days.ago }
      updated_at { 30.minutes.ago }
      archived { true }
    end

    factory :morty_updated do
      unread { false }
      github_id { 2147650093 }
      url { "https://api.github.com/notifications/threads/420" }
      subject_url { "https://api.github.com/repos/octobox/octobox/issues/56" }
      archived { true }
      updated_at { "2016-12-17T22:00:00Z" }
      last_read_at { "2016-12-18T22:00:00Z" }
    end
  end
end
