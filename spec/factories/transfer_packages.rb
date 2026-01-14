FactoryBot.define do
  factory :transfer_package do

    name { "MyString" }
    vehicle_category { "MyString" }
    seats { 1 }
    luggage { 1 }
    wait_time { 1 }
    refund_policy { "MyString" }
    price { 9.99 }
    original_price { 9.99 }
    discount_amount { 9.99 }
    features { "MyText" }
    provider { "MyString" }
    priority { 1 }
    is_active { true }

  end
end
