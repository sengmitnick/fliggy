FactoryBot.define do
  factory :attraction_review do

    association :attraction
    association :user
    rating { 9.99 }
    comment { "MyText" }
    is_featured { true }
    helpful_count { 1 }

  end
end
