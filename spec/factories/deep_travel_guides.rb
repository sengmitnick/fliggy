FactoryBot.define do
  factory :deep_travel_guide do

    name { "MyString" }
    title { "MyString" }
    description { "MyText" }
    follower_count { 1 }
    experience_years { 1 }
    specialties { "MyText" }
    price { 192 }
    served_count { 1 }
    rank { 1 }
    rating { 4.5 }
    featured { true }

  end
end
