FactoryBot.define do
  factory :tour_product do

    association :destination
    name { "MyString" }
    product_type { "MyString" }
    category { "MyString" }
    price { 9.99 }
    original_price { 9.99 }
    sales_count { 1 }
    rating { 9.99 }
    tags { "MyText" }
    description { "MyText" }
    image_url { "MyString" }
    rank { 1 }
    is_featured { true }

  end
end
