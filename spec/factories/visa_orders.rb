FactoryBot.define do
  factory :visa_order do
    association :user
    association :visa_product
    traveler_count { 1 }
    total_price { 500.0 }
    unit_price { 500.0 }
    status { "pending" }
    expected_date { Date.today + 7.days }
    delivery_method { "courier" }
    delivery_address { "广东省深圳市南山区科技园南区" }
    contact_name { "张三" }
    contact_phone { "13800138000" }
    notes { "" }
    insurance_type { "none" }
    insurance_selected { false }
    insurance_price { 0 }
    payment_status { "unpaid" }
    paid_at { nil }
    slug { nil }
  end
end
