FactoryBot.define do
  factory :visa_product do
    # Note: This project uses data packs for all data
    # Factories should not be used to create test data
    # Data is loaded from app/validators/support/data_packs/v1/
    
    # Fallback: Create minimal Country if none exists (temporary until data pack is ready)
    country { Country.first || Country.create!(name: "泰国", code: "TH", region: "东南亚") }
    name { "MyString" }
    product_type { "MyString" }
    price { 9.99 }
    original_price { 9.99 }
    residence_area { "MyString" }
    processing_days { 1 }
    visa_validity { "MyString" }
    max_stay { "MyString" }
    success_rate { 9.99 }
    required_materials { nil }
    material_count { 1 }
    can_simplify { true }
    home_pickup { true }
    refused_reapply { true }
    supports_family { true }
    features { nil }
    description { "MyText" }
    slug { "MyString" }
    sales_count { 1 }
    merchant_name { "MyString" }
    merchant_avatar { "MyString" }

  end
end
