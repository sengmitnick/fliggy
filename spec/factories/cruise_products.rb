FactoryBot.define do
  factory :cruise_product do

    association :cruise_sailing
    association :cabin_type
    merchant_name { "MyString" }
    price_per_person { 9.99 }
    occupancy_requirement { 1 }
    stock { 1 }
    sales_count { 1 }
    is_refundable { true }
    requires_confirmation { true }
    status { "MyString" }
    badge { "MyString" }

  end
end
