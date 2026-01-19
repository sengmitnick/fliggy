# 清理旧数据
TourGroupProduct.destroy_all
TravelAgency.destroy_all

puts "🏢 创建旅行社..."

# 创建旅行社
agencies = [
  { name: '天津梦远旅行社专营店', rating: 4.9, sales_count: 9000, is_verified: true },
  { name: '北京趣发现旅行社专营店', rating: 4.7, sales_count: 500, is_verified: true },
  { name: '江苏五方旅行社', rating: 4.8, sales_count: 3000, is_verified: true },
  { name: '上海春秋旅行社', rating: 4.9, sales_count: 15000, is_verified: true },
  { name: '携程旅行专营店', rating: 4.8, sales_count: 8000, is_verified: true },
  { name: '杭州携程国际旅行社', rating: 4.9, sales_count: 12000, is_verified: true },
  { name: '广州青旅国际旅行社', rating: 4.7, sales_count: 6000, is_verified: true },
  { name: '深圳康辉旅行社', rating: 4.8, sales_count: 7500, is_verified: true }
]

# 批量创建旅行社
timestamp = Time.current
agencies_with_timestamps = agencies.map { |attrs| attrs.merge(created_at: timestamp, updated_at: timestamp) }
TravelAgency.insert_all(agencies_with_timestamps)

travel_agencies = TravelAgency.all.to_a

puts "✓ 创建了 #{TravelAgency.count} 家旅行社"

puts "\n🎫 批量创建旅游产品..."

# 热门目的地和出发城市配置
destinations = [
  { name: '上海', departure_cities: ['上海', '杭州', '南京', '苏州'] },
  { name: '北京', departure_cities: ['北京', '天津', '石家庄'] },
  { name: '杭州', departure_cities: ['杭州', '上海', '宁波', '温州'] },
  { name: '广州', departure_cities: ['广州', '深圳', '珠海', '佛山'] },
  { name: '成都', departure_cities: ['成都', '重庆', '绵阳'] },
  { name: '深圳', departure_cities: ['深圳', '广州', '香港'] },
  { name: '西安', departure_cities: ['西安', '咸阳', '宝鸡'] },
  { name: '三亚', departure_cities: ['三亚', '海口', '广州', '深圳'] }
]

# 为每个目的地生成产品
start_date = Date.today
end_date = start_date + 2.days  # 只生成3天的数据，避免数据过多

all_products = []

destinations.each do |dest_config|
  destination = dest_config[:name]
  departure_cities = dest_config[:departure_cities]
  
  puts "  正在为 #{destination} 生成产品..."
  
  # 为每个出发城市生成一些产品（选择2个出发城市）
  departure_cities.sample(2).each do |departure_city|
    # 每天生成 2-3 个产品
    count = rand(2..3)
    products = TourGroupProduct.generate_for_destination(
      destination,
      departure_city,
      start_date,
      end_date,
      count_per_day: count
    )
    
    all_products.concat(products)
    puts "    ✓ #{departure_city} -> #{destination}: 生成了 #{products.count} 个产品"
  end
end

puts "\n📊 生成统计："
puts "  总产品数: #{TourGroupProduct.count}"
puts "  - 跟团游: #{TourGroupProduct.by_category('group_tour').count}"
puts "  - 私家团: #{TourGroupProduct.by_category('private_group').count}"
puts "  - 自由行: #{TourGroupProduct.by_category('free_travel').count}"
puts "  - 出境必备: #{TourGroupProduct.by_category('outbound_essentials').count}"

# 随机标记一些产品为推荐（约25%的产品）
featured_count = [all_products.count / 4, 15].min
all_products.sample(featured_count).each do |product|
  product.update!(is_featured: true)
end

puts "  - 推荐产品: #{TourGroupProduct.where(is_featured: true).count}"

puts "\n✅ 旅游产品数据包加载完成！"
puts "  创建了多样化的主题、价格、天数和旅游类型产品"
