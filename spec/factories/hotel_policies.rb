FactoryBot.define do
  factory :hotel_policy do

    association :hotel
    check_in_time { "MyString" }
    check_out_time { "MyString" }
    pet_policy { "MyString" }
    breakfast_type { "MyString" }
    breakfast_hours { "MyString" }
    breakfast_price { 9.99 }
    payment_methods { "MyText" }

  end
end
