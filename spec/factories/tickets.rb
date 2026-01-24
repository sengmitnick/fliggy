FactoryBot.define do
  factory :ticket do

    association :attraction
    name { "成人票" }
    ticket_type { "adult" }
    original_price { 100 }
    current_price { 80 }
    discount_info { "限时优惠" }
    requirements { "身份证件" }
    refund_policy { "可退款" }
    booking_notice { "提前预订" }
    validity_days { 30 }
    sales_count { 100 }
    stock { 50 }

  end
end
