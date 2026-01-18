FactoryBot.define do
  factory :flight_package do

    title { "MyString" }
    subtitle { "MyString" }
    price { 9.99 }
    original_price { 9.99 }
    discount_label { "MyString" }
    badge_text { "MyString" }
    badge_color { "MyString" }
    destination { "MyString" }
    image_url { "MyString" }
    valid_days { 1 }
    description { "MyText" }
    features { "MyText" }
    status { "MyString" }

  end
end
