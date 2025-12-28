FactoryBot.define do
  factory :brand_membership do

    association :user
    brand_name { "MyString" }
    member_number { "MyString" }
    member_level { "MyString" }
    status { "MyString" }

  end
end
