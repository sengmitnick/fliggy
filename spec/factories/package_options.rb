FactoryBot.define do
  factory :package_option do

    association :hotel_package
    name { "MyString" }
    price { 9.99 }
    original_price { 9.99 }
    night_count { 1 }
    description { "MyText" }
    can_split { true }
    display_order { 1 }
    is_active { true }

  end
end
