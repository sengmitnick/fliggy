FactoryBot.define do
  factory :membership_product do
    sequence(:name) { |n| "会员商品 #{n}" }
    category { 'popular' }
    price_cash { 99.00 }
    price_mileage { 1000 }
    original_price { 129.00 }
    sales_count { 0 }
    stock { 100 }
    rating { 4.8 }
    description { '优质商品，值得购买' }
    image_url { 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400' }
    region { 'domestic' }
    featured { false }
  end
end
