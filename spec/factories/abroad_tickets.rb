FactoryBot.define do
  factory :abroad_ticket do

    region { "japan" }
    ticket_type { "train" }
    origin { "东京" }
    destination { "京都" }
    departure_date { Date.today }
    time_slot_start { "09:00" }
    time_slot_end { "11:30" }
    price { 9.99 }
    seat_type { "普通座" }
    status { "available" }
    origin_en { "Tokyo" }
    destination_en { "Kyoto" }

  end
end
