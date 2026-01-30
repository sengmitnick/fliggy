FactoryBot.define do
  factory :travel_agency do
    name { "优质旅行社" }
    description { "专业旅游服务提供商" }
    logo_url { "https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=200" }
    rating { 4.8 }
    sales_count { 500 }
    is_verified { true }
  end
end
