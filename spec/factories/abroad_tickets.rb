FactoryBot.define do
  factory :abroad_ticket do

    region { "MyString" }
    ticket_type { "MyString" }
    origin { "MyString" }
    destination { "MyString" }
    departure_date { Date.today }
    time_slot_start { "MyString" }
    time_slot_end { "MyString" }
    price { 9.99 }
    seat_type { "MyString" }
    status { "MyString" }
    origin_en { "MyString" }
    destination_en { "MyString" }

  end
end
