FactoryBot.define do
  factory :visa_order do

    user_id { 1 }
    visa_product_id { 1 }
    traveler_count { 1 }
    total_price { 9.99 }
    unit_price { 9.99 }
    status { "MyString" }
    expected_date { Date.today }
    delivery_method { "MyString" }
    delivery_address { "MyText" }
    contact_name { "MyString" }
    contact_phone { "MyString" }
    notes { "MyText" }
    insurance_selected { true }
    insurance_price { 9.99 }
    payment_status { "MyString" }
    paid_at { Time.current }
    slug { "MyString" }

  end
end
