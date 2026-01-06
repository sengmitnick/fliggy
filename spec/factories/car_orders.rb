FactoryBot.define do
  factory :car_order do

    association :user
    association :car
    driver_name { "MyString" }
    driver_id_number { "MyString" }
    contact_phone { "MyString" }
    pickup_datetime { Time.current }
    return_datetime { Time.current }
    pickup_location { "MyString" }
    status { "MyString" }
    total_price { 9.99 }

  end
end
