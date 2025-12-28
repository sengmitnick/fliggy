FactoryBot.define do
  factory :deep_travel_product do

    title { "MyString" }
    subtitle { "MyString" }
    location { "MyString" }
    association :deep_travel_guide
    price { 9.99 }
    sales_count { 1 }
    description { "MyText" }
    itinerary { "MyText" }
    featured { true }

  end
end
