FactoryBot.define do
  factory :hotel_nearby_place do

    association :hotel
    place_type { "MyString" }
    name { "MyString" }
    distance { "MyString" }
    description { "MyText" }
    display_order { 1 }
    data_version { "MyString" }

  end
end
