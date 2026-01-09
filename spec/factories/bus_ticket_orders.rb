FactoryBot.define do
  factory :bus_ticket_order do

    association :user
    association :bus_ticket
    passenger_name { "MyString" }
    passenger_id_number { "MyString" }
    contact_phone { "MyString" }
    departure_station { "MyString" }
    arrival_station { "MyString" }
    insurance_type { "MyString" }
    insurance_price { 9.99 }
    total_price { 9.99 }
    status { "MyString" }

  end
end
