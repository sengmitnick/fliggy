# 统一的酒店数据包 - 合并所有城市
# 使用 insert_all 批量插入提升性能


# 加载图片辅助工具
require_relative '../../../../../app/helpers/image_seed_helper'

puts "🧹 清理现有酒店数据..."
HotelFacility.destroy_all
HotelReview.destroy_all
HotelPolicy.destroy_all
Room.destroy_all
HotelRoom.destroy_all
Hotel.destroy_all

timestamp = Time.current

# ==================== 城市和品牌配置 ====================
cities = [
  "深圳", "上海", "北京", "广州", "杭州",
  "成都", "西安", "南京", "武汉", "重庆",
  "天津", "苏州", "厦门", "青岛", "长沙",
  "郑州", "济南", "合肥", "南昌", "昆明"
]

# 国际品牌
international_brands = [
  { prefix: "希尔顿", suffix: "酒店", star: 5 },
  { prefix: "喜来登", suffix: "大酒店", star: 5 },
  { prefix: "万豪", suffix: "酒店", star: 5 },
  { prefix: "香格里拉", suffix: "大酒店", star: 5 },
  { prefix: "洲际", suffix: "酒店", star: 5 },
  { prefix: "凯悦", suffix: "酒店", star: 5 },
  { prefix: "丽思卡尔顿", suffix: "酒店", star: 5 },
  { prefix: "四季", suffix: "酒店", star: 5 },
  { prefix: "万丽", suffix: "酒店", star: 4 },
  { prefix: "威斯汀", suffix: "大酒店", star: 5 },
  { prefix: "雅高", suffix: "酒店", star: 4 },
  { prefix: "君悦", suffix: "大酒店", star: 5 },
  { prefix: "皇冠假日", suffix: "酒店", star: 4 },
  { prefix: "万达文华", suffix: "酒店", star: 4 },
  { prefix: "索菲特", suffix: "大酒店", star: 5 },
  { prefix: "希尔顿欢朋", suffix: "酒店", star: 4 }
]

# 国内品牌
domestic_brands = [
  { name: "如家", star: 3 },
  { name: "汉庭", star: 3 },
  { name: "锦江之星", star: 3 },
  { name: "7天", star: 3 },
  { name: "维也纳", star: 3 },
  { name: "全季", star: 4 },
  { name: "桔子", star: 4 },
  { name: "亚朵", star: 4 },
  { name: "君澜", star: 4 },
  { name: "不棉花", star: 3 }
]

# 民宿名称
homestay_names = ["山海居", "云溪小筑", "半山客栈", "水云间", "竹林雅居", "悠然小筑", "花间堂", "听风阁"]

# 地址后缀
address_suffixes = ["中心商务区", "金融街", "科技园", "会展中心", "火车站", "机场", "老城区", "新城区", "滨海路", "CBD核心区"]

# 设施配置
features_pool = [
  ["免费WiFi", "健身房", "游泳池", "餐厅"],
  ["免费停车", "商务中心", "会议室", "机场接送"],
  ["儿童乐园", "宠物友好", "水疗中心", "酒吧"],
  ["免费早餐", "24小时前台", "行李寄存", "洗衣服务"],
  ["景观房", "无烟客房", "残疾人设施", "电梯"],
  ["商务中心", "会议室", "餐厅", "酒吧"],
  ["水疗中心", "桑拿", "按摩服务", "美容美发"]
]

# 图片使用本地图片池
# 无需硬编码 URLs，直接调用 ImageSeedHelper

# ==================== 批量创建酒店 ====================
puts "\n🏨 批量创建酒店..."
hotels_data = []
hotel_index = 0

# 房型因子（用于计算房价）
min_room_factor = 1.0  # 最低房价因子

# 国际品牌酒店 (每个城市 4-6 家)
cities.each do |city|
  international_brands.sample(rand(4..6)).each do |brand|
    hotel_index += 1
    star_level = brand[:star]
    
    # base_price 现在代表最低房价（将作为 hotel.price）
    base_price = case star_level
    when 5 then rand(800..2000)
    when 4 then rand(400..800)
    else rand(200..600)
    end
    
    rating = case star_level
    when 5 then (4.5 + rand * 0.4).round(1)
    when 4 then (4.0 + rand * 0.8).round(1)
    else (3.8 + rand * 1.0).round(1)
    end
    
    hotels_data << {
      name: "#{city}#{brand[:prefix]}#{brand[:suffix]}",
      brand: brand[:prefix],
      city: city,
      address: "#{city}#{address_suffixes.sample}#{rand(1..999)}号",
      rating: rating,
      price: base_price,  # 确保这是最低房价
      original_price: (base_price * rand(1.1..1.3)).round(0),
      distance: "#{rand(1..10)}.#{rand(0..9)}km",
      features: features_pool.sample,
      star_level: star_level,
      is_featured: rand < 0.1,
      display_order: hotel_index,
      hotel_type: 'hotel',
      is_domestic: true,
      region: '国内',
      image_url: ImageSeedHelper.random_image_from_category(:hotels),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

# 国内品牌酒店 (每个城市 6-8 家)
cities.each do |city|
  domestic_brands.sample(rand(6..8)).each do |brand|
    hotel_index += 1
    star_level = brand[:star]
    
    # base_price 现在代表最低房价（将作为 hotel.price）
    base_price = case star_level
    when 4 then rand(300..600)
    else rand(150..400)
    end
    
    rating = case star_level
    when 4 then (4.0 + rand * 0.7).round(1)
    else (3.8 + rand * 0.9).round(1)
    end
    
    hotels_data << {
      name: "#{brand[:name]}酒店·#{city}店",
      brand: brand[:name],
      city: city,
      address: "#{city}#{address_suffixes.sample}#{rand(1..999)}号",
      rating: rating,
      price: base_price,  # 确保这是最低房价
      original_price: (base_price * rand(1.1..1.25)).round(0),
      distance: "#{rand(1..10)}.#{rand(0..9)}km",
      features: features_pool.sample,
      star_level: star_level,
      is_featured: rand < 0.05,
      display_order: hotel_index,
      hotel_type: 'hotel',
      is_domestic: true,
      region: '国内',
      image_url: ImageSeedHelper.random_image_from_category(:hotels),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

# 商务酒店（北京、杭州专门添加）
if cities.include?("北京")
  5.times do
    hotel_index += 1
    hotels_data << {
      name: "北京商务酒店·#{['中关村', '国贸', '金融街', '望京', '亦庄'].sample}店",
      brand: "商务酒店",
      city: "北京",
      address: "北京#{address_suffixes.sample}#{rand(1..999)}号",
      rating: (4.0 + rand * 0.8).round(1),
      price: rand(350..550),
      original_price: rand(450..700),
      distance: "#{rand(1..10)}.#{rand(0..9)}km",
      features: features_pool.sample,
      star_level: 4,
      is_featured: false,
      display_order: hotel_index,
      hotel_type: 'hotel',
      is_domestic: true,
      region: '国内',
      image_url: ImageSeedHelper.random_image_from_category(:hotels),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

if cities.include?("杭州")
  5.times do
    hotel_index += 1
    hotels_data << {
      name: "杭州商务酒店·#{['西湖', '滨江', '钓鱼台', '萎萃', '城西'].sample}店",
      brand: "商务酒店",
      city: "杭州",
      address: "杭州#{address_suffixes.sample}#{rand(1..999)}号",
      rating: (4.0 + rand * 0.8).round(1),
      price: rand(350..550),
      original_price: rand(450..700),
      distance: "#{rand(1..10)}.#{rand(0..9)}km",
      features: features_pool.sample,
      star_level: 4,
      is_featured: false,
      display_order: hotel_index,
      hotel_type: 'hotel',
      is_domestic: true,
      region: '国内',
      image_url: ImageSeedHelper.random_image_from_category(:hotels),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

# 民宿 (每个城市 2-3 家)
cities.each do |city|
  homestay_names.sample(rand(2..3)).each do |homestay_name|
    hotel_index += 1
    base_price = rand(150..400)
    
    hotels_data << {
      name: "#{city}#{homestay_name}",
      brand: "",
      city: city,
      address: "#{city}#{address_suffixes.sample}#{rand(1..999)}号",
      rating: (4.0 + rand * 1.0).round(1),
      price: base_price,
      original_price: (base_price * rand(1.1..1.2)).round(0),
      distance: "#{rand(1..10)}.#{rand(0..9)}km",
      features: ["免费WiFi", "厨房", "洗衣机", "独立卫浴"],
      star_level: nil,
      is_featured: rand < 0.05,
      display_order: hotel_index,
      hotel_type: 'homestay',
      is_domestic: true,
      region: '国内',
      image_url: ImageSeedHelper.random_image_from_category(:hotels),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

# 上海CBD核心区的民宿（支持 v099/v111 验证器）
if cities.include?("上海")
  ["山海居", "云溪小筑", "半山客栈", "水云间", "竹林雅居"].each_with_index do |homestay_name, idx|
    hotel_index += 1
    # 设置不同的 rating，确保有评分最高的民宿
    rating = 4.5 + (idx * 0.1)  # 4.5, 4.6, 4.7, 4.8, 4.9
    base_price = rand(250..450)
    
    hotels_data << {
      name: "上海#{homestay_name}",
      brand: "",
      city: "上海",
      address: "上海CBD核心区#{rand(1..999)}号",  # 确保地址包含 "CBD核心区"
      rating: rating,
      price: base_price,
      original_price: (base_price * rand(1.1..1.2)).round(0),
      distance: "#{rand(1..5)}.#{rand(0..9)}km",
      features: ["免费WiFi", "厨房", "洗衣机", "独立卫浴", "景观阳台", "24小时热水"],
      star_level: nil,
      is_featured: idx < 2,  # 前 2 个为精选
      display_order: hotel_index,
      hotel_type: 'homestay',
      is_domestic: true,
      region: '国内',
      image_url: ImageSeedHelper.random_image_from_category(:hotels),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

puts "💾 批量插入 #{hotels_data.count} 家酒店..."
Hotel.insert_all(hotels_data)

# ==================== 批量创建关联数据 ====================

# 获取所有酒店ID
all_hotels = Hotel.pluck(:id, :hotel_type, :price, :star_level).map do |id, type, price, star|
  { id: id, type: type, price: price, star: star }
end

# 创建多个真实用户
real_users_data = [
  { email: "zhangwei@163.com", name: "张伟" },
  { email: "liping@qq.com", name: "李婷" },
  { email: "wanghao@gmail.com", name: "王昊" },
  { email: "liujing@126.com", name: "刘静" },
  { email: "chenlei@sina.com", name: "陈雷" },
  { email: "yangmei@hotmail.com", name: "杨梅" },
  { email: "zhoujie@outlook.com", name: "周杰" },
  { email: "wuxin@163.com", name: "吴鑫" },
  { email: "zhengmin@qq.com", name: "郑敏" },
  { email: "sunxiaoyu@gmail.com", name: "孙小雨" }
]

real_users = []
real_users_data.each do |user_data|
  user = User.find_or_create_by(email: user_data[:email]) do |u|
    u.name = user_data[:name]
    u.password_digest = BCrypt::Password.create("password123")
  end
  real_users << user
end

# 设施数据
facilities_templates = [
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
  "房间宽敞明亮,设施齐全，非常满意。",
  "早餐丰富美味，员工态度友好热情。",
  "性价比很高，下次还会选择入住。",
  "环境优雅，卫生整洁，推荐给大家。"
]

homestay_comments = [
  "民宿很温馨，像在家一样舒适。",
  "房东很热情，给了很多旅游建议。",
  "位置安静，适合放松休息。",
  "性价比超高，厨房设施齐全。"
]

# 房型配置
# CRITICAL: 第一个房型 factor=1.0 确保 hotel.price = minimum(room.price)
overnight_room_types = [
  { type: "标准双床房", bed: "双床", area: "28㎡", category: "overnight", factor: 1.0 },
  { type: "豪华大床房", bed: "大床", area: "35㎡", category: "overnight", factor: 1.3 },
  { type: "行政套房", bed: "大床", area: "50㎡", category: "overnight", factor: 1.8 },
  { type: "家庭房", bed: "双床+沙发床", area: "45㎡", category: "overnight", factor: 1.5 }
]

# 钟点房 factor < 1.0，因为只住几小时比过夜便宜
hourly_room_types = [
  { type: "2小时房", bed: "大床", area: "25㎡", category: "hourly", factor: 0.3 },
  { type: "3小时房", bed: "大床", area: "28㎡", category: "hourly", factor: 0.4 },
  { type: "4小时房", bed: "双床", area: "30㎡", category: "hourly", factor: 0.5 }
]

facilities_data = []
hotel_rooms_data = []
policies_data = []
reviews_data = []

all_hotels.each do |hotel_info|
  hotel_id = hotel_info[:id]
  is_homestay = hotel_info[:type] == 'homestay'
  base_price = hotel_info[:price]
  star_level = hotel_info[:star] || 3
  
  # 设施 (3-5个)
  facilities_templates.sample(rand(3..5)).each do |facility|
    facilities_data << {
      hotel_id: hotel_id,
      name: facility[:name],
      icon: facility[:icon],
      description: facility[:description],
      category: facility[:category],
      created_at: timestamp,
      updated_at: timestamp
    }
  end
  
  # 房型 (2-4个)
  # CRITICAL FIX: 确保第一个房型 factor=1.0 总是被选中，保证 hotel.price = minimum(room.price)
  if is_homestay
    # 民宿只有过夜房型 - 必须包含标准双床房（factor=1.0）
    selected_rooms = [overnight_room_types[0]]  # 第一个房型 factor=1.0
    selected_rooms += overnight_room_types[1..-1].sample(rand(0..1))  # 随机增加0-1个其他房型
    
    selected_rooms.each do |room|
      hotel_rooms_data << {
        hotel_id: hotel_id,
        room_type: room[:type],
        bed_type: room[:bed],
        area: room[:area],
        room_category: room[:category],
        price: (base_price * room[:factor]).round(0),
        available_rooms: rand(2..5),
        created_at: timestamp,
        updated_at: timestamp
      }
    end
  else
    # 酒店有过夜房型 - 必须包含标准双床房（factor=1.0）
    selected_rooms = [overnight_room_types[0]]  # 第一个房型 factor=1.0
    selected_rooms += overnight_room_types[1..-1].sample(rand(1..2))  # 随机增加1-2个其他房型
    
    selected_rooms.each do |room|
      hotel_rooms_data << {
        hotel_id: hotel_id,
        room_type: room[:type],
        bed_type: room[:bed],
        area: room[:area],
        room_category: room[:category],
        price: (base_price * room[:factor]).round(0),
        available_rooms: rand(5..20),
        created_at: timestamp,
        updated_at: timestamp
      }
    end
    
    # 部分酒店有钟点房 (30%概率)
    if rand < 0.3
      hourly_room_types.sample(rand(1..2)).each do |room|
        hotel_rooms_data << {
          hotel_id: hotel_id,
          room_type: room[:type],
          bed_type: room[:bed],
          area: room[:area],
          room_category: room[:category],
          price: (base_price * room[:factor]).round(0),
          available_rooms: rand(3..10),
          created_at: timestamp,
          updated_at: timestamp
        }
      end
    end
  end
  
  # 政策
  policies_data << {
    hotel_id: hotel_id,
    check_in_time: "14:00后",
    check_out_time: "12:00前",
    pet_policy: is_homestay ? "可携带宠物" : "暂不支持携带宠物",
    breakfast_type: (star_level >= 4 && !is_homestay) ? "含早餐" : "不含早餐",
    breakfast_hours: "每天07:00-10:00",
    breakfast_price: (star_level >= 4 && !is_homestay) ? 0 : rand(20..50),
    payment_methods: ["银联", "支付宝", "微信支付"],
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 评论 (2-4条)
  comments = is_homestay ? homestay_comments : hotel_comments
  comments.sample(rand(2..4)).each do |comment|
    reviews_data << {
      hotel_id: hotel_id,
      user_id: real_users.sample.id,  # 从真实用户中随机选择
      rating: (4.0 + rand * 1.0).round(1),
      comment: comment,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

puts "💾 批量插入关联数据..."
HotelFacility.insert_all(facilities_data) if facilities_data.any?
HotelRoom.insert_all(hotel_rooms_data) if hotel_rooms_data.any?
HotelPolicy.insert_all(policies_data) if policies_data.any?
HotelReview.insert_all(reviews_data) if reviews_data.any?

puts "✓ 已创建 #{HotelFacility.count} 个设施"
puts "✓ 已创建 #{HotelRoom.count} 个房型"
puts "✓ 已创建 #{HotelPolicy.count} 个政策"
puts "✓ 已创建 #{HotelReview.count} 条评论"

# ==================== CRITICAL FIX: 同步酒店价格 ====================
puts "\n🔧 同步酒店价格为实际最低房价..."
hotel_price_updates = []
Hotel.find_each do |hotel|
  min_room_price = hotel.hotel_rooms.minimum(:price)
  if min_room_price && hotel.price != min_room_price
    hotel_price_updates << { id: hotel.id, price: min_room_price }
  end
end

if hotel_price_updates.any?
  # Bulk update using update_all with CASE statement
  when_clauses = hotel_price_updates.map { |h| "WHEN #{h[:id]} THEN #{h[:price]}" }.join(" ")
  Hotel.where(id: hotel_price_updates.map { |h| h[:id] }).update_all("price = CASE id #{when_clauses} END")
  puts "✓ 已同步 #{hotel_price_updates.size} 家酒店价格"
else
  puts "✓ 所有酒店价格已一致，无需同步"
end

puts "\n📊 统计信息："
puts "  总酒店数: #{Hotel.count}"
puts "  - 国内酒店: #{Hotel.where(hotel_type: 'hotel').count}"
puts "  - 民宿: #{Hotel.where(hotel_type: 'homestay').count}"
puts "  - 5星级: #{Hotel.where(star_level: 5).count}"
puts "  - 4星级: #{Hotel.where(star_level: 4).count}"
puts "  - 3星级: #{Hotel.where(star_level: 3).count}"

puts "\n✅ 酒店数据包加载完成！"
