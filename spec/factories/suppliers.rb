FactoryBot.define do
  factory :supplier do

    name { "MyString" }
    supplier_type { "MyString" }
    rating { 9.99 }
    sales_count { 1 }
    description { "MyText" }
    contact_phone { "MyString" }

  end
end
