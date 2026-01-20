# 为多个城市添加酒店数据
puts "正在为多个城市创建酒店数据..."

# 定义目标城市
target_cities = [
  { name: "北京", region: "北京" },
  { name: "上海", region: "上海" },
  { name: "杭州", region: "浙江" },
  { name: "广州", region: "广东" },
  { name: "成都", region: "四川" }
]

# 品牌列表
brands = [
  "希尔顿", "希尔顿欢朋", "凯悦", "万达酒店", "凯悦", 
  "君澜", "不棉花", "万豪", "亚朵", "维也纳"
]

# 地址模板
address_templates = [
  "中心商务区", "金融街", "科技园", "会展中心",
  "火车站附近", "机场", "老城区", "新城区"
]

# 特色标签
features_pool = [
  ["免费WiFi", "健身房", "游泳池", "餐厅"],
  ["免费停车", "商务中心", "会议室", "机场接送"],
  ["儿童乐园", "宠物友好", "水疗中心", "酒吧"],
  ["免费早餐", "24小时前台", "行李寄存", "洗衣服务"]
]

# 酒店图片URL列表
hotel_images = [
  "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80",
  "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80",
  "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80",
  "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800&q=80",
  "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80"
]

created_count = 0

target_cities.each do |city_data|
  city_name = city_data[:name]
  region = city_data[:region]
  
  # 为每个城市创建 5 家酒店
  5.times do |i|
    brand = brands.sample
    star_level = [4, 5].sample
    
    # 基础价格根据星级设定
    base_price = case star_level
    when 5
      rand(800..1200)
    when 4
      rand(400..800)
    else
      rand(200..400)
    end
    
    hotel_name = "#{city_name}#{address_templates[i % address_templates.length]}#{brand}酒店"
    
    hotel = Hotel.create!(
      name: hotel_name,
      city: city_name,
      address: "#{region}#{address_templates[i % address_templates.length]}#{rand(1..999)}号",
      rating: (4.0 + rand * 1.0).round(1),
      price: base_price,
      original_price: (base_price * (1.1 + rand * 0.3)).round(0),
      distance: "#{rand(1..10)}.#{rand(0..9)}km",
      features: features_pool[i % features_pool.length],
      star_level: star_level,
      image_url: hotel_images[i % hotel_images.length],
      is_featured: i == 0, # 第一家设为特色酒店
      display_order: created_count,
      hotel_type: 'hotel',
      is_domestic: true,
      region: region,
      brand: brand
    )
    
    # 创建2-3个房型
    rand(2..3).times do |j|
      room_types = [
        { type: "标准双床房", bed: "双床", area: "28㎡" },
        { type: "豪华大床房", bed: "大床", area: "35㎡" },
        { type: "行政套房", bed: "大床", area: "50㎡" }
      ]
      
      room = room_types[j]
      room_price = base_price + (j * 100)
      
      HotelRoom.create!(
        hotel: hotel,
        room_type: room[:type],
        bed_type: room[:bed],
        price: room_price,
        original_price: (room_price * 1.2).round(0),
        area: room[:area],
        max_guests: [2, 2, 3][j] || 2,
        has_window: true,
        available_rooms: rand(5..20),
        room_category: 'overnight'
      )
    end
    
    created_count += 1
  end
  
  puts "为 #{city_name} 创建了 5 家酒店"
end

puts "总共创建了 #{created_count} 家酒店"
puts "当前酒店总数: #{Hotel.count}"
