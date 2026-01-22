FactoryBot.define do
  factory :insurance_product do
    sequence(:name) { |n| "保险产品#{n}" }
    company { ['京东安联', '华泰财险', '众安保险', '美亚保险', '安盛保险', '太平洋保险'].sample }
    product_type { %w[domestic international transport].sample }
    sequence(:code) { |n| "PRODUCT_#{n}" }
    
    coverage_details do
      {
        accident: rand(500_000..10_000_000),
        medical: rand(50_000..1_000_000),
        trip_cancellation: rand(5000..50_000)
      }
    end
    
    price_per_day { rand(10..200) }
    min_days { 1 }
    max_days { 365 }
    
    scenes { ['海岛游', '亲子游', '自驾游'].sample(2) }
    highlights { ['高额保障', '快速理赔', '全球可保'].sample(2) }
    
    official_select { false }
    featured { false }
    available_for_embedding { false }
    embedding_code { nil }
    image_url { nil }
    active { true }
    sort_order { 0 }
    
    trait :featured do
      featured { true }
      official_select { true }
    end
    
    trait :embeddable do
      available_for_embedding { true }
      embedding_code { %w[standard premium].sample }
    end
    
    trait :domestic do
      product_type { 'domestic' }
      name { "境内旅行保险" }
    end
    
    trait :international do
      product_type { 'international' }
      name { "境外旅行保险" }
    end
    
    trait :transport do
      product_type { 'transport' }
      name { "交通意外险" }
    end
  end
end
