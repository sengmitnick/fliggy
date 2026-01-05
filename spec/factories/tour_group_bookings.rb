FactoryBot.define do
  factory :tour_group_booking do

    tour_group_product_id { 1 }
    tour_package_id { 1 }
    user_id { 1 }
    travel_date { Date.today }
    adult_count { 1 }
    child_count { 1 }
    contact_name { "MyString" }
    contact_phone { "MyString" }
    insurance_type { "MyString" }
    status { "MyString" }
    total_price { 9.99 }

  end
end
