# 清空现有数据
puts "清理现有酒店数据..."
HotelFacility.destroy_all
HotelReview.destroy_all
HotelPolicy.destroy_all
Room.destroy_all
HotelRoom.destroy_all
Hotel.destroy_all

puts "开始创建酒店数据..."

# 定义城市列表
cities = [
  "深圳市", "上海市", "北京市", "广州市", "杭州市",
  "成都市", "西安市", "南京市", "武汉市", "重庆市"
]

# 定义酒店名称模板
hotel_names = [
  { prefix: "希尔顿", suffix: "酒店" },
  { prefix: "喜来登", suffix: "大酒店" },
  { prefix: "万豪", suffix: "酒店" },
  { prefix: "香格里拉", suffix: "大酒店" },
  { prefix: "洲际", suffix: "酒店" },
  { prefix: "凯悦", suffix: "酒店" },
  { prefix: "丽思卡尔顿", suffix: "酒店" },
  { prefix: "四季", suffix: "酒店" },
  { prefix: "万丽", suffix: "酒店" },
  { prefix: "威斯汀", suffix: "大酒店" },
  { prefix: "雅高", suffix: "酒店" },
  { prefix: "君悦", suffix: "大酒店" },
  { prefix: "皇冠假日", suffix: "酒店" },
  { prefix: "万达文华", suffix: "酒店" },
  { prefix: "索菲特", suffix: "大酒店" },
  { prefix: "朗廷", suffix: "酒店" },
  { prefix: "康莱德", suffix: "酒店" },
  { prefix: "瑞吉", suffix: "酒店" },
  { prefix: "艾美", suffix: "酒店" },
  { prefix: "柏悦", suffix: "酒店" }
]

# 特色标签
features_pool = [
  ["免费WiFi", "健身房", "游泳池", "餐厅"],
  ["免费停车", "商务中心", "会议室", "机场接送"],
  ["儿童乐园", "宠物友好", "水疗中心", "酒吧"],
  ["免费早餐", "24小时前台", "行李寄存", "洗衣服务"],
  ["景观房", "无烟客房", "残疾人设施", "电梯"],
  ["免费WiFi", "游泳池", "健身房", "免费早餐"],
  ["商务中心", "会议室", "餐厅", "酒吧"],
  ["水疗中心", "桑拿", "按摩服务", "美容美发"],
  ["机场接送", "租车服务", "旅游咨询", "票务服务"],
  ["儿童托管", "游戏室", "儿童餐", "婴儿床"]
]

# 地址后缀
address_suffixes = [
  "中心商务区", "金融街", "科技园", "会展中心",
  "火车站", "机场", "老城区", "新城区",
  "滨海路", "山景路", "湖畔大道", "CBD核心区"
]

# 创建 50 家酒店
50.times do |i|
  city = cities[i % cities.length]
  hotel_name_template = hotel_names[i % hotel_names.length]
  hotel_name = "#{city}#{hotel_name_template[:prefix]}#{hotel_name_template[:suffix]}"
  
  # 随机星级（3-5星）
  star_level = [3, 4, 4, 5, 5].sample
  
  # 基础价格根据星级设定
  base_price = case star_level
  when 5
    rand(800..2000)
  when 4
    rand(400..800)
  else
    rand(200..400)
  end
  
  hotel = Hotel.create!(
    name: hotel_name,
    city: city,
    address: "#{city}#{address_suffixes[i % address_suffixes.length]}#{rand(1..999)}号",
    rating: (4.0 + rand * 1.0).round(1),
    price: base_price,
    original_price: (base_price * (1.1 + rand * 0.3)).round(0),
    distance: "#{rand(1..10)}.#{rand(0..9)}km",
    features: features_pool[i % features_pool.length],
    star_level: star_level,
    is_featured: [true, false, false].sample,
    display_order: i
  )
  
  # 图片使用Unsplash酒店相关图片
  hotel_images = [
    "https://images.unsplash.com/photo-1566073771-7e72bca2f686?w=800&q=80",
    "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80",
    "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80",
    "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800&q=80",
    "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80",
    "https://images.unsplash.com/photo-1549294413-26f195200c16?w=800&q=80",
    "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800&q=80",
    "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800&q=80",
    "https://images.unsplash.com/photo-1517840901100-8179e982acb7?w=800&q=80",
    "https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800&q=80"
  ]
  hotel.update(image_url: hotel_images[i % hotel_images.length])
  
  # 创建酒店政策
  HotelPolicy.create!(
    hotel: hotel,
    check_in_time: ["14:00", "15:00", "16:00"].sample,
    check_out_time: ["12:00", "13:00", "14:00"].sample,
    pet_policy: ["允许携带宠物", "不允许携带宠物", "小型宠物可以"].sample,
    breakfast_type: ["自助餐", "中西式", "仅西式", "仅中式"].sample,
    breakfast_hours: "07:00-10:00",
    breakfast_price: [0, 58, 68, 88, 98].sample,
    payment_methods: ["现金", "信用卡", "微信支付", "支付宝"]
  )
  
  # 创建 3-5 个设施
  facility_categories = [
    { name: "免费WiFi", icon: "wifi", description: "全酒店覆盖高速无线网络", category: "网络" },
    { name: "健身房", icon: "dumbbell", description: "24小时开放的现代化健身中心", category: "健身" },
    { name: "游泳池", icon: "swimmer", description: "室内恒温游泳池", category: "娱乐" },
    { name: "餐厅", icon: "utensils", description: "提供中西式美食", category: "餐饮" },
    { name: "停车场", icon: "parking", description: "免费地下停车位", category: "停车" },
    { name: "商务中心", icon: "briefcase", description: "提供办公和会议设施", category: "商务" },
    { name: "水疗中心", icon: "spa", description: "专业按摩和理疗服务", category: "休闲" }
  ]
  
  rand(3..5).times do
    facility = facility_categories.sample
    HotelFacility.create!(
      hotel: hotel,
      name: facility[:name],
      icon: facility[:icon],
      description: facility[:description],
      category: facility[:category]
    )
  end
  
  # 创建 2-4 个房型
  room_types = [
    { type: "标准双床房", bed: "双床", area: "28㎡" },
    { type: "豪华大床房", bed: "大床", area: "35㎡" },
    { type: "行政套房", bed: "大床", area: "50㎡" },
    { type: "家庭房", bed: "双床+沙发床", area: "45㎡" }
  ]
  
  rand(2..4).times do |j|
    room = room_types[j]
    room_price = base_price + (j * 100)
    
    HotelRoom.create!(
      hotel: hotel,
      room_type: room[:type],
      bed_type: room[:bed],
      price: room_price,
      original_price: (room_price * 1.2).round(0),
      area: room[:area],
      max_guests: [2, 2, 3, 4][j] || 2,
      has_window: true,
      available_rooms: rand(5..20)
    )
    
    # 创建 Room 记录（用于详细房间信息）
    Room.create!(
      hotel: hotel,
      name: room[:type],
      size: room[:area],
      bed_type: room[:bed],
      price: room_price,
      original_price: (room_price * 1.2).round(0),
      amenities: ["免费WiFi", "空调", "液晶电视", "迷你吧", "保险箱", "吹风机"],
      breakfast_included: [true, false].sample,
      cancellation_policy: ["免费取消", "不可取消", "入住前24小时免费取消"].sample
    )
  end
  
  # 创建 3-8 条评论
  rand(3..8).times do
    # 确保有用户存在
    user = User.first || User.create!(
      email: "demo@example.com",
      email_verified: true,
      password_digest: BCrypt::Password.create("password123")
    )
    
    comments = [
      "酒店位置很好，交通便利，服务周到。",
      "房间宽敞明亮，设施齐全，非常满意。",
      "早餐丰富美味，员工态度友好热情。",
      "性价比很高，下次还会选择入住。",
      "环境优雅，卫生整洁，推荐给大家。",
      "前台办理入住很快，房间隔音效果好。",
      "配套设施完善，健身房和游泳池都很不错。",
      "整体体验不错，就是停车位有点紧张。"
    ]
    
    HotelReview.create!(
      hotel: hotel,
      user: user,
      rating: (4.0 + rand * 1.0).round(1),
      comment: comments.sample,
      helpful_count: rand(0..50)
    )
  end
  
  puts "已创建: #{hotel_name} (#{star_level}星)"
end

puts "\n酒店数据创建完成！"
puts "总计创建:"
puts "- 酒店: #{Hotel.count} 家"
puts "- 房型: #{HotelRoom.count} 个"
puts "- 房间详情: #{Room.count} 个"
puts "- 酒店政策: #{HotelPolicy.count} 条"
puts "- 酒店设施: #{HotelFacility.count} 个"
puts "- 酒店评论: #{HotelReview.count} 条"
