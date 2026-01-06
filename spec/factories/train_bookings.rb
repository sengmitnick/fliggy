FactoryBot.define do
  factory :train_booking do

    association :user
    association :train
    passenger_name { "张三" }
    passenger_id_number { "110101199001011234" }
    contact_phone { "13800138000" }
    seat_type { "second_class" }
    carriage_number { "05" }
    seat_number { "08A" }
    total_price { 100.0 }
    insurance_type { "standard" }
    insurance_price { 50.0 }
    status { "pending" }
    accept_terms { true }

  end
end
