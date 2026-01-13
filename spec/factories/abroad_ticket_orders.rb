FactoryBot.define do
  factory :abroad_ticket_order do

    association :user
    association :abroad_ticket
    passenger_name { "MyString" }
    passenger_id_number { "MyString" }
    contact_phone { "MyString" }
    contact_email { "MyString" }
    passenger_type { "MyString" }
    seat_category { "MyString" }
    total_price { 9.99 }
    status { "MyString" }
    notes { "MyText" }

  end
end
