FactoryBot.define do
  factory :attraction_activity do

    association :attraction
    name { "拍摄服务" }
    activity_type { "photo_service" }
    original_price { 200 }
    current_price { 150 }
    discount_info { "限时优惠" }
    refund_policy { "可退款" }
    description { "专业摄影服务" }
    duration { "2小时" }
    sales_count { 50 }

  end
end
