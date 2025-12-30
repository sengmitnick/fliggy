FactoryBot.define do
  factory :hotel do

    name { "MyString" }
    city { "MyString" }
    address { "MyText" }
    rating { 4.5 }
    price { 9.99 }
    original_price { 9.99 }
    distance { "MyString" }
    features { "MyText" }
    star_level { 1 }
    image_url { "MyString" }
    is_featured { true }
    display_order { 1 }

  end
end
