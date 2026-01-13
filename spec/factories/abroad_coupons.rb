FactoryBot.define do
  factory :abroad_coupon do

    title { "MyString" }
    abroad_brand_id { 1 }
    abroad_shop_id { 1 }
    discount_type { "MyString" }
    discount_value { "MyString" }
    description { "MyText" }
    valid_from { Date.today }
    valid_until { Date.today }
    active { true }

  end
end
