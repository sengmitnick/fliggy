FactoryBot.define do
  factory :bus_ticket do

    origin { "MyString" }
    destination { "MyString" }
    departure_date { Date.today }
    departure_time { "MyString" }
    arrival_time { "MyString" }
    price { 9.99 }
    status { "MyString" }
    seat_type { "MyString" }

  end
end
