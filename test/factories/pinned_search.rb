FactoryBot.define do
  factory :pinned_search do
    user
    name { 'work' }
    query { 'inbox:true owner:octobox' }
  end
end
