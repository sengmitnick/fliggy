FactoryBot.define do
  factory :internet_data_plan do

    name { "MyString" }
    region { "MyString" }
    validity_days { 1 }
    data_limit { "MyString" }
    price { 9.99 }
    phone_number { "MyString" }
    carrier { "MyString" }
    description { "MyText" }

  end
end
