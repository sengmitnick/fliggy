FactoryBot.define do
  factory :cabin_type do

    association :cruise_ship
    name { "MyString" }
    category { "MyString" }
    floor_range { "MyString" }
    area { 9.99 }
    has_balcony { true }
    has_window { true }
    max_occupancy { 1 }
    description { "MyText" }
    image_urls { nil }

  end
end
