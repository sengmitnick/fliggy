FactoryBot.define do
  factory :tour_package do

    association :tour_group_product
    name { "MyString" }
    price { 9.99 }
    child_price { 9.99 }
    purchase_count { 1 }
    description { "MyText" }
    is_featured { true }
    display_order { 1 }

  end
end
