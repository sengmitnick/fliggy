FactoryBot.define do
  factory :bus_ticket_passenger do

    association :bus_ticket_order
    passenger_name { "张三" }
    passenger_id_number { "110101199001011234" }
    insurance_type { "none" }

  end
end
