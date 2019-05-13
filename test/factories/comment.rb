FactoryBot.define do
  factory :comment do 
    subject
    sequence(:github_id, 1000000) { |n| n }
    author {'benjam'}
    body {'blah'}
  end
end 