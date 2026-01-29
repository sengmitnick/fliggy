FactoryBot.define do
  factory :deep_travel_review do

    association :deep_travel_guide
    association :user
    rating { 9.99 }
    content { "MyText" }
    helpful_count { 1 }
    visit_date { Date.today }
    data_version { "MyString" }

  end
end
