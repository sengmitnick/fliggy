# 为深圳市创建符合统一品牌的酒店数据
puts "正在为深圳市创建新的酒店数据..."

# 统一品牌列表
brands = [
  { name: "希尔顿", star: 5 },
  { name: "希尔顿欢朋", star: 4 },
  { name: "凯悦", star: 5 },
  { name: "万达酒店", star: 4 },
  { name: "君澜", star: 4 },
  { name: "不棉花", star: 3 },
  { name: "万豪", star: 5 },
  { name: "亚朵", star: 4 },
  { name: "维也纳", star: 3 }
]

# 深圳热门区域
areas = [
  { name: "福田中心区", region: "福田区" },
  { name: "南山科技园", region: "南山区" },
  { name: "罗湖口岸", region: "罗湖区" },
  { name: "宝安机场", region: "宝安区" },
  { name: "前海湾", region: "南山区" },
  { name: "华强北", region: "福田区" },
  { name: "蛇口", region: "南山区" },
  { name: "欢乐海岸", region: "南山区" }
]

# 为每个品牌创建2-3家酒店，共20家左右
created_count = 0

brands.each do |brand_info|
  # 每个品牌创建2家酒店
  2.times do |i|
    area = areas.sample
    
    hotel_name = case brand_info[:name]
    when "希尔顿"
      ["深圳#{area[:region]}希尔顿酒店", "深圳#{area[:name]}希尔顿酒店"].sample
    when "希尔顿欢朋"
      "深圳#{area[:name]}希尔顿欢朋酒店"
    when "凯悦"
      ["深圳#{area[:region]}凯悦酒店", "深圳柏悦酒店(#{area[:name]})"].sample
    when "万达酒店"
      "深圳#{area[:name]}万达酒店"
    when "君澜"
      "深圳#{area[:name]}君澜度假酒店"
    when "不棉花"
      "不棉花酒店·深圳#{area[:name]}店"
    when "万豪"
      ["深圳#{area[:region]}万豪酒店", "深圳万豪行政公寓(#{area[:name]})"].sample
    when "亚朵"
      "亚朵酒店·深圳#{area[:name]}店"
    when "维也纳"
      "维也纳酒店·深圳#{area[:name]}店"
    end
    
    # 根据星级设置价格范围
    price_range = case brand_info[:star]
    when 5
      (800..1500)
    when 4
      (400..800)
    when 3
      (200..400)
    end
    
    base_price = rand(price_range)
    
    hotel = Hotel.create!(
      name: hotel_name,
      brand: brand_info[:name],
      city: "深圳市",
      region: area[:region],
      address: "#{area[:region]}#{area[:name]}商圈",
      star_level: brand_info[:star],
      rating: rand(4.0..4.9).round(1),
      price: base_price,
      image_url: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800",
      features: "免费WiFi,停车场,健身房,游泳池",
      is_featured: false,
      is_domestic: true
    )
    
    # 为每家酒店创建2-3个房型
    room_types = [
      { name: "标准双床房", price_factor: 1.0 },
      { name: "豪华大床房", price_factor: 1.3 },
      { name: "行政套房", price_factor: 1.8 }
    ]
    
    room_types.sample(rand(2..3)).each do |room_type|
      room_price = (base_price * room_type[:price_factor]).round
      
      HotelRoom.create!(
        hotel: hotel,
        room_type: room_type[:name],
        price: room_price,
        available_rooms: rand(5..20)
      )
    end
    
    created_count += 1
    puts "创建酒店: #{hotel_name} (#{brand_info[:name]})"
  end
end

puts "\n深圳市酒店创建完成！共创建 #{created_count} 家酒店"
puts "\n品牌统计:"
Hotel.where(city: '深圳市').group(:brand).count.each do |brand, count|
  puts "  #{brand}: #{count}家"
end
