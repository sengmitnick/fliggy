FactoryBot.define do
  factory :address do

    association :user
    name { "MyString" }
    phone { "MyString" }
    province { "MyString" }
    city { "MyString" }
    district { "MyString" }
    detail { "MyString" }
    is_default { true }
    address_type { "MyString" }

  end
end
