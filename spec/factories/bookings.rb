FactoryBot.define do
  factory :booking do

    association :user
    association :flight
    passenger_name { "MyString" }
    passenger_id_number { "MyString" }
    contact_phone { "MyString" }
    total_price { 9.99 }
    status { "MyString" }
    accept_terms { true }

  end
end
