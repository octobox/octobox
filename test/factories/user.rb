FactoryBot.define do
  factory :user do
    sequence(:github_id, 1000000){|n| n}
    access_token { SecureRandom.hex(20) }
    github_login {"user#{github_id}"}
    last_synced_at { Time.parse('2016-12-19T12:00:00Z') }
    api_token { SecureRandom.hex(10) }

    factory :token_user do
      personal_access_token { 'deadbeef' }
      github_login { 'tokenuser' }
      github_id { 8278492 }
    end

    factory :app_user do
      github_login { 'appuser' }
      github_id { 8278492 }
      app_token { 'livepork' }
    end

    factory :morty do
      github_id { 947167 }
      github_login { "morty" }
      last_synced_at {Time.parse('2016-12-19T12:00:00Z')}
      after(:create) do |user|
        create(:archived, user: user)
        create(:morty_updated, user: user)
      end
    end
  end
end
