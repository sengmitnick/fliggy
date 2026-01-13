FactoryBot.define do
  factory :visa_order_traveler do

    visa_order_id { 1 }
    name { "MyString" }
    id_number { "MyString" }
    phone { "MyString" }
    relationship { "MyString" }
    passport_number { "MyString" }
    passport_expiry { Date.today }

  end
end
