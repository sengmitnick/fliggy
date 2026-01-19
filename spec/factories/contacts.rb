FactoryBot.define do
  factory :contact do
    name { "测试联系人" }
    sequence(:phone) { |n| "138#{n.to_s.rjust(8, '0')}" }
    sequence(:email) { |n| "contact#{n}@example.com" }
    is_default { false }
    association :user
  end
end
