FactoryBot.define do
  factory :cruise_sailing do

    association :cruise_ship
    association :cruise_route
    departure_date { Date.today }
    return_date { Date.today }
    duration_days { 1 }
    duration_nights { 1 }
    departure_port { "MyString" }
    arrival_port { "MyString" }
    itinerary { nil }
    status { "MyString" }

  end
end
