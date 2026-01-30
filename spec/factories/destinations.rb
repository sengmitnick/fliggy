FactoryBot.define do
  factory :destination do
    sequence(:name) { |n| "深圳#{n}" }
    region { "广东" }
    description { "创新之都，现代化滨海城市" }
    image_url { "https://images.unsplash.com/photo-1548919973-5cef591cdbc9?w=800" }
    is_hot { true }
  end
end
