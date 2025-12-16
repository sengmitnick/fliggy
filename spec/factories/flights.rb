FactoryBot.define do
  factory :flight do

    departure_city { "MyString" }
    destination_city { "MyString" }
    departure_time { Time.current }
    arrival_time { Time.current }
    departure_airport { "MyString" }
    arrival_airport { "MyString" }
    airline { "MyString" }
    flight_number { "MyString" }
    aircraft_type { "MyString" }
    price { 9.99 }
    discount_price { 9.99 }
    seat_class { "MyString" }
    available_seats { 1 }
    flight_date { Date.today }

  end
end
