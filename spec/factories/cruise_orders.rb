FactoryBot.define do
  factory :cruise_order do

    association :user
    association :cruise_product
    quantity { 1 }
    total_price { 9.99 }
    passenger_info { nil }
    contact_name { "MyString" }
    contact_phone { "MyString" }
    insurance_type { "MyString" }
    insurance_price { 9.99 }
    status { "MyString" }
    order_number { "MyString" }
    accept_terms { true }

  end
end
