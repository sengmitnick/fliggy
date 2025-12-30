FactoryBot.define do
  factory :hotel_room do

    hotel_id { 1 }
    room_type { "MyString" }
    bed_type { "MyString" }
    price { 9.99 }
    original_price { 9.99 }
    area { "MyString" }
    max_guests { 1 }
    has_window { true }
    available_rooms { 1 }

  end
end
