FactoryBot.define do
  factory :notification do

    association :user
    category { "MyString" }
    title { "MyString" }
    content { "MyText" }
    read { true }
    badge_count { 1 }

  end
end
