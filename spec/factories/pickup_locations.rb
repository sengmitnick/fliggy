FactoryBot.define do
  factory :pickup_location do

    city { "MyString" }
    district { "MyString" }
    detail { "MyText" }
    phone { "MyString" }
    business_hours { "MyString" }
    notes { "MyText" }
    is_active { true }

  end
end
