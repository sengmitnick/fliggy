FactoryBot.define do
  factory :address do

    association :user
    name { "张三" }
    phone { "13800138000" }
    province { "广东省" }
    city { "深圳" }
    district { "南山区" }
    detail { "科技园南区" }
    is_default { true }
    address_type { "delivery" }

  end
end
