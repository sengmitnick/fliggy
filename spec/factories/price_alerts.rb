FactoryBot.define do
  factory :price_alert do

    departure { "MyString" }
    destination { "MyString" }
    expected_price { 9.99 }
    departure_date { Date.today }
    status { "MyString" }

  end
end
