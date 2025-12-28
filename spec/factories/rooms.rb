FactoryBot.define do
  factory :room do

    association :hotel
    name { "MyString" }
    size { "MyString" }
    bed_type { "MyString" }
    price { 9.99 }
    original_price { 9.99 }
    amenities { "MyText" }
    breakfast_included { true }
    cancellation_policy { "MyString" }

  end
end
