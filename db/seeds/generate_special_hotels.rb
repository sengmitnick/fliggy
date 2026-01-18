# Generate special/featured hotels for multiple cities

cities_data = {
  '深圳市' => [
    { name: '深圳湾万怡酒店', brand: '万豪', star_level: 4, price: 199, original_price: 399, rating: 4.8, address: '南山区深圳湾' },
    { name: '深圳福田香格里拉大酒店', brand: '香格里拉', star_level: 5, price: 299, original_price: 599, rating: 4.9, address: '福田区福华三路' },
    { name: '深圳罗湖希尔顿酒店', brand: '希尔顿', star_level: 5, price: 249, original_price: 499, rating: 4.7, address: '罗湖区建设路' },
    { name: '深圳宝安汉庭酒店', brand: '汉庭', star_level: 3, price: 89, original_price: 159, rating: 4.5, address: '宝安区新安' },
    { name: '深圳南山如家酒店', brand: '如家', star_level: 3, price: 99, original_price: 179, rating: 4.6, address: '南山区科技园' },
    { name: '深圳前海凯悦酒店', brand: '凯悦', star_level: 5, price: 349, original_price: 699, rating: 4.9, address: '南山区前海' },
  ],
  '上海市' => [
    { name: '上海外滩华尔道夫酒店', brand: '华尔道夫', star_level: 5, price: 599, original_price: 1299, rating: 4.9, address: '黄浦区中山东一路' },
    { name: '上海虹桥美居酒店', brand: '美居', star_level: 4, price: 189, original_price: 389, rating: 4.7, address: '闵行区虹桥' },
    { name: '上海浦东7天酒店', brand: '7天', star_level: 2, price: 79, original_price: 149, rating: 4.4, address: '浦东新区张江' },
    { name: '上海静安锦江之星', brand: '锦江之星', star_level: 3, price: 109, original_price: 199, rating: 4.5, address: '静安区南京西路' },
    { name: '上海陆家嘴丽思卡尔顿', brand: '丽思卡尔顿', star_level: 5, price: 699, original_price: 1499, rating: 5.0, address: '浦东新区陆家嘴' },
  ],
  '北京市' => [
    { name: '北京王府井希尔顿酒店', brand: '希尔顿', star_level: 5, price: 399, original_price: 799, rating: 4.8, address: '东城区王府井大街' },
    { name: '北京朝阳桔子酒店', brand: '桔子', star_level: 3, price: 129, original_price: 259, rating: 4.6, address: '朝阳区三里屯' },
    { name: '北京海淀汉庭酒店', brand: '汉庭', star_level: 3, price: 99, original_price: 189, rating: 4.5, address: '海淀区中关村' },
    { name: '北京西城如家酒店', brand: '如家', star_level: 2, price: 89, original_price: 169, rating: 4.4, address: '西城区西单' },
    { name: '北京国贸大酒店', brand: '国贸', star_level: 5, price: 499, original_price: 999, rating: 4.9, address: '朝阳区建国门外大街' },
  ],
  '广州市' => [
    { name: '广州天河万豪酒店', brand: '万豪', star_level: 5, price: 299, original_price: 599, rating: 4.8, address: '天河区天河路' },
    { name: '广州珠江新城希尔顿', brand: '希尔顿', star_level: 5, price: 349, original_price: 699, rating: 4.9, address: '天河区珠江新城' },
    { name: '广州番禺如家酒店', brand: '如家', star_level: 2, price: 79, original_price: 149, rating: 4.5, address: '番禺区市桥' },
    { name: '广州越秀7天酒店', brand: '7天', star_level: 2, price: 69, original_price: 129, rating: 4.3, address: '越秀区北京路' },
    { name: '广州白云国际机场酒店', brand: '机场酒店', star_level: 4, price: 199, original_price: 399, rating: 4.6, address: '白云区机场路' },
  ],
  '杭州市' => [
    { name: '杭州西湖国宾馆', brand: '国宾馆', star_level: 5, price: 499, original_price: 999, rating: 4.9, address: '西湖区杨公堤' },
    { name: '杭州滨江万豪酒店', brand: '万豪', star_level: 5, price: 279, original_price: 559, rating: 4.7, address: '滨江区江南大道' },
    { name: '杭州西湖汉庭酒店', brand: '汉庭', star_level: 3, price: 119, original_price: 229, rating: 4.6, address: '西湖区南山路' },
    { name: '杭州拱墅如家酒店', brand: '如家', star_level: 2, price: 99, original_price: 189, rating: 4.4, address: '拱墅区运河边' },
    { name: '杭州黄龙饭店', brand: '黄龙', star_level: 4, price: 229, original_price: 459, rating: 4.7, address: '西湖区黄龙' },
  ],
  '成都市' => [
    { name: '成都太古里瑞吉酒店', brand: '瑞吉', star_level: 5, price: 399, original_price: 799, rating: 4.9, address: '锦江区红星路' },
    { name: '成都高新区凯悦酒店', brand: '凯悦', star_level: 5, price: 329, original_price: 659, rating: 4.8, address: '高新区天府大道' },
    { name: '成都春熙路7天酒店', brand: '7天', star_level: 2, price: 89, original_price: 169, rating: 4.5, address: '锦江区春熙路' },
    { name: '成都武侯汉庭酒店', brand: '汉庭', star_level: 3, price: 79, original_price: 149, rating: 4.4, address: '武侯区人民南路' },
    { name: '成都天府广场如家酒店', brand: '如家', star_level: 2, price: 69, original_price: 139, rating: 4.3, address: '青羊区天府广场' },
  ]
}

common_features = ['免费WiFi', '24小时前台', '空调', '电视', '热水淋浴']
luxury_features = common_features + ['健身房', '游泳池', '餐厅', '会议室', '停车场']
budget_features = common_features + ['自助洗衣', '行李寄存']

puts "Starting to generate special hotels..."

cities_data.each do |city, hotels|
  puts "\nGenerating hotels for #{city}..."
  
  hotels.each do |hotel_data|
    # Determine features based on star level
    features = case hotel_data[:star_level]
    when 5
      luxury_features + ['管家服务', '礼宾服务', '行政酒廊']
    when 4
      luxury_features + ['商务中心']
    when 3
      common_features + ['电梯', '行李寄存']
    else
      budget_features
    end
    
    hotel = Hotel.find_or_initialize_by(
      name: hotel_data[:name],
      city: city
    )
    
    hotel.assign_attributes(
      brand: hotel_data[:brand],
      star_level: hotel_data[:star_level],
      price: hotel_data[:price],
      original_price: hotel_data[:original_price],
      rating: hotel_data[:rating],
      address: hotel_data[:address],
      features: features,
      is_featured: true,
      is_domestic: true,
      hotel_type: 'hotel',
      region: '国内',
      distance: rand(1.0..5.0).round(1)
    )
    
    if hotel.save
      puts "  ✓ Created/Updated: #{hotel.name} (#{hotel.star_level}星)"
    else
      puts "  ✗ Failed: #{hotel.name} - #{hotel.errors.full_messages.join(', ')}"
    end
  end
end

puts "\n" + "="*50
puts "Summary:"
puts "="*50
Hotel.where(is_featured: true).group(:city).count.each do |city, count|
  puts "#{city}: #{count} featured hotels"
end
puts "\nTotal featured hotels: #{Hotel.where(is_featured: true).count}"
