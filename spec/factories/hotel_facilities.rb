FactoryBot.define do
  factory :hotel_facility do

    association :hotel
    name { "MyString" }
    icon { "MyString" }
    description { "MyString" }
    category { "MyString" }

  end
end
