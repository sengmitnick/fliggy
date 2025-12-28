FactoryBot.define do
  factory :hotel_review do

    association :hotel
    association :user
    rating { 9.99 }
    comment { "MyText" }
    helpful_count { 1 }

  end
end
