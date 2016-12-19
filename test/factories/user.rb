FactoryGirl.define do
  factory :user do
    github_id { rand(0..5000) }
    access_token { SecureRandom.hex(15) }
    github_login 'andrew'
  end
end
