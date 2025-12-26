FactoryBot.define do
  factory :train do

    departure_city { "MyString" }
    arrival_city { "MyString" }
    departure_time { Time.current }
    arrival_time { Time.current }
    duration { 1 }
    train_number { "MyString" }
    seat_types { "MyText" }
    price_second_class { 9.99 }
    price_first_class { 9.99 }
    price_business_class { 9.99 }
    available_seats { 1 }

  end
end
