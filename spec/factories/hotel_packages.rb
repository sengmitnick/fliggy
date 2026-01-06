FactoryBot.define do
  factory :hotel_package do
    brand_name { "华住" }
    title { "华住酒店全国通兑2晚" }
    description { "可拆分通兑全程不加价" }
    price { 699 }
    original_price { 999 }
    sales_count { 100 }
    is_featured { true }
    valid_days { 365 }
    terms { "使用规则" }
    region { "全国" }
    city { "全国" }
    package_type { "standard" }
    night_count { 2 }
    refundable { true }
    instant_booking { true }
    luxury { false }
    display_order { 1 }
  end
end
