FactoryBot.define do
  factory :notification_setting do

    association :user
    category { "MyString" }
    enabled { true }

  end
end
