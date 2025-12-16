FactoryBot.define do
  factory :flight_offer do

    association :flight
    provider_name { "MyString" }
    offer_type { "MyString" }
    price { 9.99 }
    original_price { 9.99 }
    cashback_amount { 9.99 }
    discount_items { "MyText" }
    seat_class { "MyString" }
    services { "MyText" }
    tags { "MyText" }
    baggage_info { "MyString" }
    meal_included { true }
    refund_policy { "MyString" }
    is_featured { true }
    display_order { 1 }

  end
end
