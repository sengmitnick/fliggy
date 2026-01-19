# 清空现有数据
puts "清理现有酒店数据..."
HotelFacility.destroy_all
HotelReview.destroy_all
HotelPolicy.destroy_all
Room.destroy_all
HotelRoom.destroy_all
Hotel.destroy_all

puts "开始创建精简版酒店数据（用于验证器测试）..."

# 图片URL池
hotel_images = [
  "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80&fm=jpg&fit=crop&auto=format",
  "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800&q=80&fm=jpg&fit=crop&auto=format",
  "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80&fm=jpg&fit=crop&auto=format",
  "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800&q=80&fm=jpg&fit=crop&auto=format",
  "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800&q=80&fm=jpg&fit=crop&auto=format",
  "https://images.unsplash.com/photo-1549294413-26f195200c16?w=800&q=80&fm=jpg&fit=crop&auto=format",
  "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800&q=80&fm=jpg&fit=crop&auto=format",
  "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800&q=80&fm=jpg&fit=crop&auto=format",
  "https://images.unsplash.com/photo-1517840901100-8179e982acb7?w=800&q=80&fm=jpg&fit=crop&auto=format",
  "https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800&q=80&fm=jpg&fit=crop&auto=format"
]

# ==================== 批量创建酒店 ====================
hotels_data = []
timestamp = Time.current

# 深圳酒店（5家，用于预算筛选测试）
# 目标：找到≤500元且性价比最高的酒店（应该选择如家）
hotels_data << {
  name: "深圳希尔顿酒店",
  city: "深圳市",
  address: "深圳市福田区中心商务区88号",
  rating: 4.8,
  price: 800,
  original_price: 1000,
  distance: "2.5km",
  features: ["免费WiFi", "健身房", "游泳池", "餐厅"],
  star_level: 5,
  is_featured: true,
  display_order: 0,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: hotel_images[0],
  data_version: 0,
  brand: "希尔顿",
  created_at: timestamp,
  updated_at: timestamp
}

hotels_data << {
  name: "深圳喜来登大酒店",
  city: "深圳市",
  address: "深圳市南山区科技园北路128号",
  rating: 4.6,
  price: 600,
  original_price: 750,
  distance: "3.2km",
  features: ["免费WiFi", "健身房", "餐厅", "商务中心"],
  star_level: 4,
  is_featured: false,
  display_order: 1,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: hotel_images[1],
  data_version: 0,
  brand: "喜来登",
  created_at: timestamp,
  updated_at: timestamp
}

hotels_data << {
  name: "深圳如家快捷酒店",
  city: "深圳市",
  address: "深圳市罗湖区东门商业街66号",
  rating: 4.3,
  price: 350,
  original_price: 400,
  distance: "1.8km",
  features: ["免费WiFi", "24小时前台", "免费早餐"],
  star_level: 3,
  is_featured: false,
  display_order: 2,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: hotel_images[2],
  data_version: 0,
  brand: "如家",
  created_at: timestamp,
  updated_at: timestamp
}

hotels_data << {
  name: "深圳汉庭酒店",
  city: "深圳市",
  address: "深圳市福田区华强北路188号",
  rating: 4.1,
  price: 280,
  original_price: 320,
  distance: "2.1km",
  features: ["免费WiFi", "24小时前台", "行李寄存"],
  star_level: 3,
  is_featured: false,
  display_order: 3,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: hotel_images[3],
  data_version: 0,
  brand: "汉庭",
  created_at: timestamp,
  updated_at: timestamp
}

hotels_data << {
  name: "深圳7天连锁酒店",
  city: "深圳市",
  address: "深圳市宝安区新安街道56号",
  rating: 3.9,
  price: 220,
  original_price: 260,
  distance: "4.5km",
  features: ["免费WiFi", "24小时前台"],
  star_level: 3,
  is_featured: false,
  display_order: 4,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: hotel_images[4],
  data_version: 0,
  brand: "7天",
  created_at: timestamp,
  updated_at: timestamp
}

# 北京酒店（5家，用于评分筛选测试）
# 目标：找到4星级及以上、评分最高的酒店（应该选择四季酒店）
hotels_data << {
  name: "北京四季酒店",
  city: "北京市",
  address: "北京市朝阳区建国门外大街1号",
  rating: 4.9,
  price: 1800,
  original_price: 2200,
  distance: "1.2km",
  features: ["免费WiFi", "健身房", "游泳池", "水疗中心", "米其林餐厅"],
  star_level: 5,
  is_featured: true,
  display_order: 5,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: hotel_images[5],
  data_version: 0,
  brand: "四季",
  created_at: timestamp,
  updated_at: timestamp
}

hotels_data << {
  name: "北京丽思卡尔顿酒店",
  city: "北京市",
  address: "北京市朝阳区CBD核心区88号",
  rating: 4.8,
  price: 1500,
  original_price: 1800,
  distance: "1.5km",
  features: ["免费WiFi", "健身房", "游泳池", "水疗中心", "餐厅"],
  star_level: 5,
  is_featured: true,
  display_order: 6,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: hotel_images[6],
  data_version: 0,
  brand: "丽思卡尔顿",
  created_at: timestamp,
  updated_at: timestamp
}

hotels_data << {
  name: "北京万豪酒店",
  city: "北京市",
  address: "北京市东城区金融街158号",
  rating: 4.7,
  price: 800,
  original_price: 950,
  distance: "2.3km",
  features: ["免费WiFi", "健身房", "餐厅", "商务中心"],
  star_level: 4,
  is_featured: false,
  display_order: 7,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: hotel_images[7],
  data_version: 0,
  brand: "万豪",
  created_at: timestamp,
  updated_at: timestamp
}

hotels_data << {
  name: "北京如家快捷酒店",
  city: "北京市",
  address: "北京市西城区西单商业街99号",
  rating: 4.2,
  price: 350,
  original_price: 400,
  distance: "3.5km",
  features: ["免费WiFi", "24小时前台", "免费早餐"],
  star_level: 3,
  is_featured: false,
  display_order: 8,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: hotel_images[8],
  data_version: 0,
  brand: "如家",
  created_at: timestamp,
  updated_at: timestamp
}

hotels_data << {
  name: "北京锦江之星",
  city: "北京市",
  address: "北京市海淀区中关村大街168号",
  rating: 4.0,
  price: 280,
  original_price: 330,
  distance: "4.8km",
  features: ["免费WiFi", "24小时前台"],
  star_level: 3,
  is_featured: false,
  display_order: 9,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: hotel_images[9],
  data_version: 0,
  brand: "锦江之星",
  created_at: timestamp,
  updated_at: timestamp
}

Hotel.insert_all(hotels_data)
puts "已批量创建 #{hotels_data.size} 家酒店（深圳5家 + 北京5家）"

# 重新加载所有酒店以获取ID
all_hotels = Hotel.all.to_a

# ==================== 批量创建关联数据 ====================
policies_data = []
facilities_data = []
hotel_rooms_data = []
rooms_data = []

# 设施定义
facility_templates = [
  { name: "免费WiFi", icon: "wifi", description: "全酒店覆盖高速无线网络", category: "网络" },
  { name: "健身房", icon: "dumbbell", description: "24小时开放的现代化健身中心", category: "健身" },
  { name: "游泳池", icon: "swimmer", description: "室内恒温游泳池", category: "娱乐" },
  { name: "餐厅", icon: "utensils", description: "提供中西式美食", category: "餐饮" },
  { name: "商务中心", icon: "briefcase", description: "提供办公和会议设施", category: "商务" },
  { name: "水疗中心", icon: "spa", description: "专业按摩和理疗服务", category: "休闲" },
  { name: "24小时前台", icon: "concierge-bell", description: "全天候服务", category: "服务" },
  { name: "免费早餐", icon: "coffee", description: "自助早餐", category: "餐饮" },
  { name: "米其林餐厅", icon: "star", description: "米其林星级餐厅", category: "餐饮" }
]

# 房型定义（标准化）
overnight_room_types = [
  { type: "标准双床房", bed: "双床", area: "28㎡" },
  { type: "豪华大床房", bed: "大床", area: "35㎡" },
  { type: "行政套房", bed: "大床", area: "50㎡" }
]

puts "\n准备批量创建关联数据..."

all_hotels.each_with_index do |hotel, index|
  base_price = hotel.price
  
  # 1. 创建酒店政策
  policies_data << {
    hotel_id: hotel.id,
    check_in_time: "14:00",
    check_out_time: "12:00",
    pet_policy: hotel.star_level >= 4 ? "允许携带宠物" : "不允许携带宠物",
    breakfast_type: hotel.star_level >= 4 ? "自助餐" : "不提供早餐",
    breakfast_hours: hotel.star_level >= 4 ? "07:00-10:00" : "",
    breakfast_price: hotel.star_level >= 4 ? (hotel.star_level == 5 ? 88 : 58) : 0,
    payment_methods: ["现金", "信用卡", "微信支付", "支付宝"],
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 2. 创建设施
  hotel.features.each do |feature_name|
    facility = facility_templates.find { |f| f[:name] == feature_name }
    next unless facility
    
    facilities_data << {
      hotel_id: hotel.id,
      name: facility[:name],
      icon: facility[:icon],
      description: facility[:description],
      category: facility[:category],
      created_at: timestamp,
      updated_at: timestamp
    }
  end
  
  # 3. 创建房型和房间
  overnight_room_types.each_with_index do |room_type, rt_index|
    # 根据房型计算价格
    price_multiplier = case room_type[:type]
    when "标准双床房"
      1.0
    when "豪华大床房"
      1.3
    when "行政套房"
      1.8
    else
      1.0
    end
    
    room_price = (base_price * price_multiplier).round(0)
    max_guests = room_type[:type].include?("套房") ? 4 : 2
    
    # HotelRoom 记录（房型信息）
    hotel_rooms_data << {
      hotel_id: hotel.id,
      room_type: room_type[:type],
      bed_type: room_type[:bed],
      price: room_price,
      original_price: (room_price * 1.2).round(0),
      area: room_type[:area],
      max_guests: max_guests,
      has_window: true,
      available_rooms: rand(5..15),
      room_category: 'overnight',
      created_at: timestamp,
      updated_at: timestamp
    }
    
    # Room 记录（房间详情）
    rooms_data << {
      hotel_id: hotel.id,
      name: room_type[:type],
      size: room_type[:area],
      bed_type: room_type[:bed],
      price: room_price,
      original_price: (room_price * 1.2).round(0),
      amenities: ["免费WiFi", "空调", "液晶电视", "迷你吧", "保险箱", "吹风机"],
      breakfast_included: hotel.star_level >= 4,
      cancellation_policy: "入住前24小时免费取消",
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

# 批量插入数据
HotelPolicy.insert_all(policies_data) if policies_data.any?
puts "已批量创建 #{policies_data.size} 条酒店政策"

HotelFacility.insert_all(facilities_data) if facilities_data.any?
puts "已批量创建 #{facilities_data.size} 条设施记录"

HotelRoom.insert_all(hotel_rooms_data) if hotel_rooms_data.any?
puts "已批量创建 #{hotel_rooms_data.size} 个酒店房型（HotelRoom）"

Room.insert_all(rooms_data) if rooms_data.any?
puts "已批量创建 #{rooms_data.size} 个房间详情（Room）"

puts "\n✅ 精简版酒店数据创建完成！"
puts "   - 深圳酒店：5家（价格¥220-¥800，用于预算筛选）"
puts "   - 北京酒店：5家（价格¥280-¥1800，星级3-5星，用于评分筛选）"
puts "   - 数据版本：data_version: 0（基线数据）"
