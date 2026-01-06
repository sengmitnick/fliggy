FactoryBot.define do
  factory :car do

    brand { "MyString" }
    car_model { "MyString" }
    category { "MyString" }
    seats { 1 }
    doors { 1 }
    transmission { "MyString" }
    fuel_type { "MyString" }
    engine { "MyString" }
    price_per_day { 9.99 }
    total_price { 9.99 }
    discount_amount { 9.99 }
    location { "MyString" }
    pickup_location { "MyString" }
    features { "MyText" }
    tags { "MyText" }
    is_featured { true }
    is_available { true }
    sales_rank { 1 }

  end
end
