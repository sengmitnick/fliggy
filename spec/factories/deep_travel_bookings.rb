FactoryBot.define do
  factory :deep_travel_booking do

    association :user
    association :deep_travel_guide
    association :deep_travel_product
    travel_date { Date.today }
    adult_count { 1 }
    child_count { 1 }
    traveler_name { "MyString" }
    traveler_id_number { "MyString" }
    traveler_phone { "MyString" }
    contact_name { "MyString" }
    contact_phone { "MyString" }
    total_price { 9.99 }
    insurance_price { 9.99 }
    status { "MyString" }
    notes { "MyText" }

  end
end
