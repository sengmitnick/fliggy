# frozen_string_literal: true

# 租车数据补充包 - 补充广州的豪华轿车
# 加载方式: rails runner "load Rails.root.join('app/validators/support/data_packs/v1/cars_supplement.rb')"

puts "🚗 补充租车数据..."

timestamp = Time.current

# 补充广州的豪华轿车
cars_data = [
  {
    brand: "奔驰",
    car_model: "E级",
    category: "豪华轿车",
    seats: 5,
    doors: 4,
    transmission: "自动挡",
    fuel_type: "汽油",
    engine: "2.0T",
    price_per_day: 450,
    total_price: 1800,
    discount_amount: 150,
    location: "广州",
    pickup_location: "白云国际机场T2",
    features: "豪华轿车 | 5座4门 | 自动挡 | 2.0T",
    tags: "豪华商务,机场直达",
    image_url: "https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8",
    is_featured: true,
    is_available: true,
    sales_rank: 301,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    brand: "宝马",
    car_model: "5系",
    category: "豪华轿车",
    seats: 5,
    doors: 4,
    transmission: "自动挡",
    fuel_type: "汽油",
    engine: "2.0T",
    price_per_day: 480,
    total_price: 1920,
    discount_amount: 160,
    location: "广州",
    pickup_location: "广州南站租车中心",
    features: "豪华轿车 | 5座4门 | 自动挡 | 2.0T",
    tags: "豪华商务,高铁便捷",
    image_url: "https://images.unsplash.com/photo-1555215695-3004980ad54e",
    is_featured: true,
    is_available: true,
    sales_rank: 302,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    brand: "奥迪",
    car_model: "A6L",
    category: "豪华轿车",
    seats: 5,
    doors: 4,
    transmission: "自动挡",
    fuel_type: "汽油",
    engine: "2.0T",
    price_per_day: 420,
    total_price: 1680,
    discount_amount: 140,
    location: "广州",
    pickup_location: "天河体育中心租车点",
    features: "豪华轿车 | 5座4门 | 自动挡 | 2.0T",
    tags: "豪华商务,市中心",
    image_url: "https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a",
    is_featured: false,
    is_available: true,
    sales_rank: 303,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    brand: "雷克萨斯",
    car_model: "ES",
    category: "豪华轿车",
    seats: 5,
    doors: 4,
    transmission: "自动挡",
    fuel_type: "混动",
    engine: "2.5L混动",
    price_per_day: 500,
    total_price: 2000,
    discount_amount: 200,
    location: "广州",
    pickup_location: "珠江新城租车服务站",
    features: "豪华轿车 | 5座4门 | 自动挡 | 混动",
    tags: "豪华商务,混合动力,静音舒适",
    image_url: "https://images.unsplash.com/photo-1621007947382-bb3c3994e3fb",
    is_featured: false,
    is_available: true,
    sales_rank: 304,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    brand: "沃尔沃",
    car_model: "S90",
    category: "豪华轿车",
    seats: 5,
    doors: 4,
    transmission: "自动挡",
    fuel_type: "汽油",
    engine: "2.0T",
    price_per_day: 430,
    total_price: 1720,
    discount_amount: 150,
    location: "广州",
    pickup_location: "广州塔租车点",
    features: "豪华轿车 | 5座4门 | 自动挡 | 2.0T",
    tags: "豪华商务,安全可靠",
    image_url: "https://images.unsplash.com/photo-1617469767053-d3b523a0b982",
    is_featured: false,
    is_available: true,
    sales_rank: 305,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

Car.insert_all(cars_data)
puts "  ✓ 已补充广州豪华轿车: #{cars_data.count} 辆"

puts "\n✅ 租车数据补充完成"
