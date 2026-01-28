FactoryBot.define do
  factory :hotel_package_order do
    association :hotel_package
    association :package_option
    association :user
    association :passenger
    order_number { "ORDER#{SecureRandom.hex(8).upcase}" }
    quantity { 1 }
    total_price { 699 }
    booking_type { "stockup" }
    status { "pending" }
    contact_name { "张三" }
    contact_phone { "13800138000" }
    check_in_date { 3.days.from_now.to_date }
  end
end
