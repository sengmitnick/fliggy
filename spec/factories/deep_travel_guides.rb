FactoryBot.define do
  factory :deep_travel_guide do

    name { "MyString" }
    title { "MyString" }
    description { "MyText" }
    follower_count { 1 }
    experience_years { 1 }
    specialties { "MyText" }
    price { 9.99 }
    served_count { 1 }
    rank { 1 }
    rating { 9.99 }
    featured { true }

  end
end
