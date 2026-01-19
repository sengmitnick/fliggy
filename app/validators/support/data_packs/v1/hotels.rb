# 清空现有数据
puts "清理现有酒店数据..."
HotelFacility.destroy_all
HotelReview.destroy_all
HotelPolicy.destroy_all
Room.destroy_all
HotelRoom.destroy_all
Hotel.destroy_all

puts "开始创建酒店数据（使用批量插入优化）..."

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
  { prefix: "索菲特", suffix: "大酒店" }
]

# 民宿名称模板
homestay_names = [
  "山海居", "云溪小筑", "半山客栈", "水云间", "竹林雅居"
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

# 房型定义
overnight_room_types = [
  { type: "标准双床房", bed: "双床", area: "28㎡", category: "overnight" },
  { type: "豪华大床房", bed: "大床", area: "35㎡", category: "overnight" },
  { type: "行政套房", bed: "大床", area: "50㎡", category: "overnight" },
  { type: "家庭房", bed: "双床+沙发床", area: "45㎡", category: "overnight" }
]

hourly_room_types = [
  { type: "2小时房", bed: "大床", area: "25㎡", category: "hourly" },
  { type: "3小时房", bed: "大床", area: "28㎡", category: "hourly" },
  { type: "4小时房", bed: "双床", area: "30㎡", category: "hourly" }
]

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
puts "\n批量创建酒店..."
hotels_data = []
timestamp = Time.current

50.times do |i|
  city = cities[i % cities.length]
  hotel_name_template = hotel_names[i % hotel_names.length]
  hotel_name = "#{city}#{hotel_name_template[:prefix]}#{hotel_name_template[:suffix]}"
  
  star_level = [3, 4, 4, 5, 5].sample
  base_price = case star_level
  when 5
    rand(800..2000)
  when 4
    rand(400..800)
  else
    rand(200..400)
  end
  
  hotels_data << {
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
    display_order: i,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '国内',
    image_url: hotel_images[i % hotel_images.length],
    data_version: 1,
    brand: "",
    created_at: timestamp,
    updated_at: timestamp
  }
end

Hotel.insert_all(hotels_data)
puts "已批量创建 #{hotels_data.size} 家酒店"

# ==================== 批量创建民宿 ====================
puts "\n批量创建民宿..."
homestays_data = []

5.times do |i|
  city = cities[i % cities.length]
  homestay_name = "#{city}#{homestay_names[i]}"
  base_price = rand(150..350)
  
  homestays_data << {
    name: homestay_name,
    city: city,
    address: "#{city}#{address_suffixes[i % address_suffixes.length]}#{rand(1..999)}号",
    rating: (4.0 + rand * 1.0).round(1),
    price: base_price,
    original_price: (base_price * (1.1 + rand * 0.2)).round(0),
    distance: "#{rand(1..10)}.#{rand(0..9)}km",
    features: ["免费WiFi", "厨房", "洗衣机", "独立卫浴"],
    star_level: nil,
    is_featured: [true, false].sample,
    display_order: 50 + i,
    hotel_type: 'homestay',
    is_domestic: true,
    region: '国内',
    image_url: "https://images.unsplash.com/photo-1522798514-97ceb8c4f1c8?w=800&q=80&fm=jpg&fit=crop&auto=format",
    data_version: 1,
    brand: "",
    created_at: timestamp,
    updated_at: timestamp
  }
end

Hotel.insert_all(homestays_data)
puts "已批量创建 #{homestays_data.size} 家民宿"

# 重新加载所有酒店以获取ID
all_hotels = Hotel.all.to_a

# ==================== 批量创建关联数据 ====================
policies_data = []
facilities_data = []
hotel_rooms_data = []
rooms_data = []
reviews_data = []

# 确保有Demo用户
demo_user = User.find_or_create_by(email: "demo@example.com") do |u|
  u.password_digest = BCrypt::Password.create("password123")
end

# 设施分类定义
facility_categories = [
  { name: "免费WiFi", icon: "wifi", description: "全酒店覆盖高速无线网络", category: "网络" },
  { name: "健身房", icon: "dumbbell", description: "24小时开放的现代化健身中心", category: "健身" },
  { name: "游泳池", icon: "swimmer", description: "室内恒温游泳池", category: "娱乐" },
  { name: "餐厅", icon: "utensils", description: "提供中西式美食", category: "餐饮" },
  { name: "停车场", icon: "parking", description: "免费地下停车位", category: "停车" },
  { name: "商务中心", icon: "briefcase", description: "提供办公和会议设施", category: "商务" },
  { name: "水疗中心", icon: "spa", description: "专业按摩和理疗服务", category: "休闲" }
]

# 评论模板
hotel_comments = [
  "酒店位置很好，交通便利，服务周到。",
  "房间宽敞明亮，设施齐全，非常满意。",
  "早餐丰富美味，员工态度友好热情。",
  "性价比很高，下次还会选择入住。",
  "环境优雅，卫生整洁，推荐给大家。",
  "前台办理入住很快，房间隔音效果好。",
  "配套设施完善，健身房和游泳池都很不错。",
  "整体体验不错，就是停车位有点紧张。"
]

homestay_comments = [
  "民宿很温馨，像在家一样舒适。",
  "房东很热情，给了很多旅游建议。",
  "位置安静，适合放松休息。",
  "性价比超高，厨房设施齐全。",
  "装修风格独特，拍照很好看。"
]

puts "\n准备批量创建关联数据..."

all_hotels.each_with_index do |hotel, index|
  is_homestay = hotel.hotel_type == 'homestay'
  base_price = hotel.price
  
  # 1. 创建酒店政策
  policies_data << {
    hotel_id: hotel.id,
    check_in_time: is_homestay ? "15:00" : ["14:00", "15:00", "16:00"].sample,
    check_out_time: is_homestay ? "11:00" : ["12:00", "13:00", "14:00"].sample,
    pet_policy: is_homestay ? "允许携带宠物" : ["允许携带宠物", "不允许携带宠物", "小型宠物可以"].sample,
    breakfast_type: is_homestay ? "不提供早餐" : ["自助餐", "中西式", "仅西式", "仅中式"].sample,
    breakfast_hours: is_homestay ? "" : "07:00-10:00",
    breakfast_price: is_homestay ? 0 : [0, 58, 68, 88, 98].sample,
    payment_methods: ["现金", "信用卡", "微信支付", "支付宝"],
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 2. 创建设施
  if is_homestay
    # 民宿固定设施
    facilities_data << {
      hotel_id: hotel.id,
      name: "厨房",
      icon: "utensils",
      description: "配备完整厨具和餐具",
      category: "生活",
      created_at: timestamp,
      updated_at: timestamp
    }
    facilities_data << {
      hotel_id: hotel.id,
      name: "洗衣机",
      icon: "tshirt",
      description: "免费使用洗衣机和烘干机",
      category: "生活",
      created_at: timestamp,
      updated_at: timestamp
    }
  else
    # 酒店随机设施
    rand(3..5).times do
      facility = facility_categories.sample
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
  end
  
  # 3. 创建过夜房型
  room_count = is_homestay ? rand(1..2) : rand(2..3)
  room_count.times do |j|
    if is_homestay
      room_types = [
        { type: "温馨单间", bed: "大床", area: "20㎡" },
        { type: "舒适双床房", bed: "双床", area: "25㎡" }
      ]
      room = room_types[j]
      room_price = base_price + (j * 50)
      max_guests = j == 0 ? 2 : 3
      multiplier = 1.15
    else
      room = overnight_room_types[j]
      room_price = base_price + (j * 100)
      max_guests = [2, 2, 3, 4][j] || 2
      multiplier = 1.2
    end
    
    hotel_rooms_data << {
      hotel_id: hotel.id,
      room_type: room[:type],
      bed_type: room[:bed],
      price: room_price,
      original_price: (room_price * multiplier).round(0),
      area: room[:area],
      max_guests: max_guests,
      has_window: true,
      available_rooms: is_homestay ? rand(2..5) : rand(5..20),
      room_category: 'overnight',
      created_at: timestamp,
      updated_at: timestamp
    }
    
    rooms_data << {
      hotel_id: hotel.id,
      name: room[:type],
      size: room[:area],
      bed_type: room[:bed],
      price: room_price,
      original_price: (room_price * multiplier).round(0),
      amenities: is_homestay ? ["免费WiFi", "空调", "电视", "独立卫浴", "厨房"] : ["免费WiFi", "空调", "液晶电视", "迷你吧", "保险箱", "吹风机"],
      breakfast_included: is_homestay ? false : [true, false].sample,
      cancellation_policy: is_homestay ? "入住前48小时免费取消" : ["免费取消", "不可取消", "入住前24小时免费取消"].sample,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
  
  # 4. 创建钟点房（部分酒店/民宿）
  has_hourly = is_homestay ? (rand < 0.4) : (rand < 0.6)
  if has_hourly
    hourly_count = is_homestay ? 1 : rand(1..2)
    hourly_count.times do |j|
      if is_homestay
        room = { type: "2小时房", bed: "大床", area: "18㎡" }
        room_price = (base_price * 0.25).round(0)
        multiplier = 1.15
      else
        room = hourly_room_types[j]
        room_price = (base_price * 0.3).round(0) + (j * 30)
        multiplier = 1.2
      end
      
      hotel_rooms_data << {
        hotel_id: hotel.id,
        room_type: room[:type],
        bed_type: room[:bed],
        price: room_price,
        original_price: (room_price * multiplier).round(0),
        area: room[:area],
        max_guests: 2,
        has_window: true,
        available_rooms: is_homestay ? rand(1..3) : rand(3..10),
        room_category: 'hourly',
        created_at: timestamp,
        updated_at: timestamp
      }
      
      rooms_data << {
        hotel_id: hotel.id,
        name: room[:type],
        size: room[:area],
        bed_type: room[:bed],
        price: room_price,
        original_price: (room_price * multiplier).round(0),
        amenities: is_homestay ? ["免费WiFi", "空调", "独立卫浴"] : ["免费WiFi", "空调", "液晶电视"],
        breakfast_included: false,
        cancellation_policy: "不可取消",
        created_at: timestamp,
        updated_at: timestamp
      }
    end
  end
  
  # 5. 创建评论
  review_count = is_homestay ? rand(2..5) : rand(3..8)
  comments = is_homestay ? homestay_comments : hotel_comments
  
  review_count.times do
    reviews_data << {
      hotel_id: hotel.id,
      user_id: demo_user.id,
      rating: (4.0 + rand * 1.0).round(1),
      comment: comments.sample,
      helpful_count: rand(0..50),
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

# ==================== 执行批量插入 ====================
puts "\n执行批量插入..."

puts "  → 插入酒店政策..."
HotelPolicy.insert_all(policies_data) if policies_data.any?

puts "  → 插入酒店设施..."
HotelFacility.insert_all(facilities_data) if facilities_data.any?

puts "  → 插入酒店房型..."
HotelRoom.insert_all(hotel_rooms_data) if hotel_rooms_data.any?

puts "  → 插入房间详情..."
Room.insert_all(rooms_data) if rooms_data.any?

puts "  → 插入酒店评论..."
HotelReview.insert_all(reviews_data) if reviews_data.any?

puts "\n酒店数据创建完成！"
puts "总计创建:"
puts "- 酒店: #{Hotel.where(hotel_type: 'hotel').count} 家"
puts "- 民宿: #{Hotel.where(hotel_type: 'homestay').count} 家"
puts "- 总住宿场所: #{Hotel.count} 家"
puts "- 过夜房型: #{HotelRoom.where(room_category: 'overnight').count} 个"
puts "- 钟点房型: #{HotelRoom.where(room_category: 'hourly').count} 个"
puts "- 总房型: #{HotelRoom.count} 个"
puts "- 房间详情: #{Room.count} 个"
puts "- 酒店政策: #{HotelPolicy.count} 条"
puts "- 酒店设施: #{HotelFacility.count} 个"
puts "- 酒店评论: #{HotelReview.count} 条"
puts "\n有钟点房的住宿场所: #{Hotel.with_hourly_rooms.count} 家"
