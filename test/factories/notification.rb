FactoryGirl.define do
  factory :notification do
    repository_id 930405
    repository_full_name "octobox/octobox"
    subject_title "Test"
    subject_url "https://api.github.com/repos/octobox/octobox/issues/123"
    subject_type "Issue"
    reason "subscribed"
    unread true
    updated_at "2015-06-22 14:37:57"
    last_read_at "2015-06-22 13:34:48 UTC"
    url "https://api.github.com/notifications/threads/930405"
    archived false
    starred false
  end
end
