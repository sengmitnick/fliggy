FactoryBot.define do
  factory :internet_order do

    association :user
    association :orderable
    order_type { "MyString" }
    region { "MyString" }
    quantity { 1 }
    total_price { 9.99 }
    status { "MyString" }
    delivery_method { "MyString" }
    delivery_info { nil }
    contact_info { nil }
    rental_info { nil }
    order_number { "MyString" }

  end
end
