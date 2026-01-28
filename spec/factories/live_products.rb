FactoryBot.define do
  factory :live_product do

    association :productable
    position { 1 }
    live_room_name { "MyString" }

  end
end
