FactoryBot.define do
  factory :internet_sim_card do

    name { "MyString" }
    region { "MyString" }
    validity_days { 1 }
    data_limit { "MyString" }
    price { 9.99 }
    features { "MyText" }
    sales_count { 1 }
    shop_name { "MyString" }

  end
end
