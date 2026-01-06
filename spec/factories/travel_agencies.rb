FactoryBot.define do
  factory :travel_agency do

    name { "MyString" }
    description { "MyText" }
    logo_url { "MyString" }
    rating { 9.99 }
    sales_count { 1 }
    is_verified { true }

  end
end
