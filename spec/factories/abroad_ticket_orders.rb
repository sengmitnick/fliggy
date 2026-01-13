FactoryBot.define do
  factory :abroad_ticket_order do

    association :user
    association :abroad_ticket
    passenger_name { "张三" }
    passenger_id_number { "110101199001011234" }
    contact_phone { "13800138000" }
    contact_email { "test@example.com" }
    passenger_type { "adult" }
    seat_category { "普通座" }
    total_price { 99.9 }
    status { "pending" }
    notes { "备注信息" }

  end
end
