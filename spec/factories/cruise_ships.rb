FactoryBot.define do
  factory :cruise_ship do

    association :cruise_line
    name { "MyString" }
    name_en { "MyString" }
    image_url { "MyString" }
    features { nil }

  end
end
