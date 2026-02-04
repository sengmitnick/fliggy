FactoryBot.define do
  factory :hotel_highlight do

    association :hotel
    title { "MyString" }
    description { "MyText" }
    icon { "MyString" }
    display_order { 1 }
    data_version { "MyString" }

  end
end
