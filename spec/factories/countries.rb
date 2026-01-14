FactoryBot.define do
  factory :country do

    name { "MyString" }
    code { "MyString" }
    slug { "MyString" }
    region { "MyString" }
    visa_free { true }
    image_url { "MyString" }
    description { "MyText" }
    visa_requirements { "MyText" }
    statistics { nil }

  end
end
