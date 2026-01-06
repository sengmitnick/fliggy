FactoryBot.define do
  factory :passenger do
    association :user
    name { "张三" }
    id_type { "身份证" }
    id_number { "110101199001011234" }
    phone { "13800138000" }
  end
end
