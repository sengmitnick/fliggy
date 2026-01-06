FactoryBot.define do
  factory :booking_option do

    association :train
    title { "MyString" }
    description { "MyText" }
    extra_fee { 9.99 }
    benefits { "MyText" }
    priority { 1 }
    is_active { true }

  end
end
