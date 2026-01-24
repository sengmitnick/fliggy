FactoryBot.define do
  factory :bus_ticket_order do

    association :user
    association :bus_ticket
    base_price { 50.0 }
    passenger_count { 1 }
    departure_station { "北京" }
    arrival_station { "上海" }
    insurance_type { "none" }
    insurance_price { 0.0 }
    total_price { 50.0 }
    status { "pending" }

  end
end
