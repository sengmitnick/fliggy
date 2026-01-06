FactoryBot.define do
  factory :tour_group_product do

    title { "MyString" }
    subtitle { "MyString" }
    tour_category { "MyString" }
    destination { "MyString" }
    duration { 1 }
    departure_city { "MyString" }
    price { 9.99 }
    original_price { 9.99 }
    rating { 9.99 }
    rating_desc { "MyString" }
    highlights { "MyText" }
    tags { "MyText" }
    provider { "MyString" }
    sales_count { 1 }
    badge { "MyString" }
    departure_label { "MyString" }
    image_url { "MyString" }
    is_featured { true }
    display_order { 1 }

  end
end
