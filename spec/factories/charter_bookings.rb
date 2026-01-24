FactoryBot.define do
  factory :charter_booking do
    association :user
    association :charter_route
    association :vehicle_type
    
    departure_date { Date.today + 1.day }
    departure_time { '09:00' }
    duration_hours { 8 }
    booking_mode { 'by_route' }
    contact_name { '张三' }
    contact_phone { '13800138000' }
    passengers_count { 4 }
    pickup_address { '武汉天河国际机场' }
    note { '请准时到达' }
    total_price { 800.0 }
    status { 'pending' }
    order_number { nil }  # Will be auto-generated
    paid_at { nil }
  end
end
