FactoryBot.define do
  factory :membership do

    association :user
    level { "MyString" }
    points { 1 }
    experience { 1 }

  end
end
