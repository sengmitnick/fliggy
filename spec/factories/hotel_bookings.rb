FactoryBot.define do
  factory :hotel_booking do

    association :hotel
    association :user
    association :hotel_room
    check_in_date { Date.today }
    check_out_date { Date.today }
    rooms_count { 1 }
    adults_count { 1 }
    children_count { 1 }
    guest_name { "MyString" }
    guest_phone { "MyString" }
    total_price { 9.99 }
    original_price { 9.99 }
    discount_amount { 9.99 }
    payment_method { "MyString" }
    coupon_code { "MyString" }
    special_requests { "MyText" }
    status { "MyString" }

  end
end
