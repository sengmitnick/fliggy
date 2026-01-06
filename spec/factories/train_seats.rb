FactoryBot.define do
  factory :train_seat do

    association :train
    seat_type { "MyString" }
    price { 9.99 }
    available_count { 1 }
    total_count { 1 }

  end
end
