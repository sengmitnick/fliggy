FactoryBot.define do
  factory :custom_travel_request do

    departure_city { "MyString" }
    destination_city { "MyString" }
    adults_count { 1 }
    children_count { 1 }
    elders_count { 1 }
    departure_date { Date.today }
    days_count { 1 }
    preferences { "MyText" }
    phone { "MyString" }
    expected_merchants { 1 }
    contact_time { "MyString" }
    status { "MyString" }

  end
end
