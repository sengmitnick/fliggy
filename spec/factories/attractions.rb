FactoryBot.define do
  factory :attraction do

    name { "MyString" }
    city_id { 1 }
    latitude { 9.99 }
    longitude { 9.99 }
    description { "MyText" }
    cover_image_url { "MyString" }

  end
end
