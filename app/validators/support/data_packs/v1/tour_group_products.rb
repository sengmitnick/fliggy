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

travel_agencies = agencies.map { |attrs| TravelAgency.create!(attrs) }

puts "✓ 创建了 #{TravelAgency.count} 家旅行社"

puts "\n🎫 批量创建旅游产品..."

# 热门目的地和出发城市配置
destinations = [
  { name: '上海', departure_cities: ['上海', '杭州', '南京', '苏州', '无锡', '常州', '黄山', '芜湖'] },
  { name: '北京', departure_cities: ['北京', '天津', '石家庄', '太原', '呼和浩特', '郑州', '济南', '青岛'] },
  { name: '杭州', departure_cities: ['杭州', '上海', '南京', '苏州', '无锡', '常州', '黄山', '芜湖', '宁波', '金华', '温州', '绍兴'] },
  { name: '浙江', departure_cities: ['杭州', '上海', '南京', '苏州', '无锡', '常州', '黄山', '芜湖', '宁波', '金华', '温州', '绍兴'] },
  { name: '广州', departure_cities: ['广州', '深圳', '珠海', '佛山', '东莞', '中山', '惠州', '江门', '厦门', '福州'] },
  { name: '成都', departure_cities: ['成都', '重庆', '绵阳', '德阳', '乐山', '雅安', '西安', '昆明'] },
  { name: '深圳', departure_cities: ['深圳', '广州', '珠海', '佛山', '东莞', '中山', '惠州', '江门', '香港', '厦门'] },
  { name: '西安', departure_cities: ['西安', '咸阳', '宝鸡', '渭南', '延安', '汉中', '成都', '郑州', '兰州'] },
  { name: '三亚', departure_cities: ['三亚', '海口', '广州', '深圳', '上海', '杭州', '南京', '北京'] },
  { name: '南京', departure_cities: ['南京', '上海', '杭州', '苏州', '无锡', '常州', '扬州', '镇江', '合肥', '黄山'] },
  { name: '苏州', departure_cities: ['苏州', '上海', '杭州', '南京', '无锡', '常州', '黄山', '宁波'] },
  { name: '厦门', departure_cities: ['厦门', '福州', '泉州', '广州', '深圳', '杭州', '上海', '南昌'] },
  { name: '重庆', departure_cities: ['重庆', '成都', '绵阳', '贵阳', '昆明', '西安', '武汉', '长沙'] },
  { name: '昆明', departure_cities: ['昆明', '成都', '重庆', '贵阳', '广州', '深圳', '南宁', '西双版纳'] },
  { name: '青岛', departure_cities: ['青岛', '济南', '烟台', '威海', '北京', '天津', '石家庄', '郑州'] },
  { name: '长沙', departure_cities: ['长沙', '武汉', '广州', '深圳', '南昌', '重庆', '成都', '贵阳'] },
  { name: '武汉', departure_cities: ['武汉', '长沙', '郑州', '南昌', '合肥', '重庆', '成都', '西安'] },
  { name: '南昌', departure_cities: ['南昌', '长沙', '武汉', '福州', '厦门', '杭州', '上海', '合肥'] },
  { name: '贵阳', departure_cities: ['贵阳', '昆明', '成都', '重庆', '长沙', '广州', '南宁', '遵义'] },
  { name: '兰州', departure_cities: ['兰州', '西安', '西宁', '银川', '乌鲁木齐', '成都', '郑州', '太原'] },
  { name: '西宁', departure_cities: ['西宁', '兰州', '西安', '银川', '乌鲁木齐', '成都', '敦煌', '格尔木'] }
]

# 为每个目的地生成产品
start_date = Date.today
end_date = start_date + 2.days  # 只生成3天的数据，避免数据过多

all_products = []

destinations.each do |dest_config|
  destination = dest_config[:name]
  departure_cities = dest_config[:departure_cities]
  
  puts "  正在为 #{destination} 生成产品..."
  
  # 为每个出发城市都生成产品（覆盖所有出发城市）
  departure_cities.each do |departure_city|
    # 每天生成 4-6 个产品，增加数量和多样性
    count = rand(4..6)
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
