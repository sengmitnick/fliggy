FactoryBot.define do
  factory :visa_service do

    title { "MyString" }
    country { "MyString" }
    service_type { "MyString" }
    success_rate { 9.99 }
    processing_days { 1 }
    price { 1 }
    original_price { 1 }
    urgent_processing { true }
    description { "MyText" }
    merchant_name { "MyString" }
    sales_count { 1 }
    slug { "MyString" }
    image_url { "MyString" }

  end
end
