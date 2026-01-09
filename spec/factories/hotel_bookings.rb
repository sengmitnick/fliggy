FactoryBot.define do
  factory :hotel_booking do
    association :user
    check_in_date { Date.today }
    check_out_date { Date.today + 1.day }
    rooms_count { 1 }
    adults_count { 2 }
    children_count { 0 }
    guest_name { "张三" }
    guest_phone { "13800138000" }
    total_price { 500.0 }
    original_price { 550.0 }
    discount_amount { 50.0 }
    payment_method { "花呗" }
    coupon_code { "" }
    special_requests { "" }
    status { "pending" }

    # Create hotel and hotel_room with proper association
    transient do
      hotel { create(:hotel) }
    end

    after(:build) do |hotel_booking, evaluator|
      hotel_booking.hotel ||= evaluator.hotel
      hotel_booking.hotel_room ||= create(:hotel_room, hotel: evaluator.hotel)
    end
  end
end
