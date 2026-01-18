FactoryBot.define do
  factory :family_coupon do

    title { "MyString" }
    coupon_type { "MyString" }
    amount { 9.99 }
    valid_until { Date.today }
    status { "MyString" }
    description { "MyText" }

  end
end
