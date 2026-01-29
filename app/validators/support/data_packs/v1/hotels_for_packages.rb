# frozen_string_literal: true

# hotels_for_packages_v1 数据包
# 为酒店套餐商品补充匹配的酒店数据
#
# 用途：
# - 为现有 hotel_packages 数据包中的套餐提供对应的酒店
# - 确保每个套餐的品牌和城市组合在数据库中都有对应的酒店
# - 支持多地区多城市的套餐使用
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 hotels_for_packages_v1 数据包..."

timestamp = Time.current

# ==================== 图片URL配置 ====================
hotel_images = [
  "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800",
  "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=800",
  "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800",
  "https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=800",
  "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=800",
  "https://images.unsplash.com/photo-1549294413-26f195200c16?w=800",
  "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=800",
  "https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=800",
  "https://images.unsplash.com/photo-1517840901100-8179e982acb7?w=800",
  "https://images.unsplash.com/photo-1564501049412-61c2a3083791?w=800"
]

# ==================== 设施配置 ====================
features_pool = [
  ["免费WiFi", "健身房", "游泳池", "餐厅"],
  ["免费停车", "商务中心", "会议室", "机场接送"],
  ["儿童乐园", "宠物友好", "水疗中心", "酒吧"],
  ["免费早餐", "24小时前台", "行李寄存", "洗衣服务"],
  ["景观房", "无烟客房", "残疾人设施", "电梯"],
  ["商务中心", "会议室", "餐厅", "酒吧"],
  ["水疗中心", "桑拿", "按摩服务", "美容美发"]
]

# ==================== 地址后缀 ====================
address_suffixes = ["中心商务区", "金融街", "科技园", "会展中心", "火车站", "机场", "老城区", "新城区", "滨海路", "CBD核心区"]

# ==================== 品牌和城市配置 ====================
# 根据现有套餐数据定义需要创建的酒店
brand_city_configs = [
  # 武汉地区 - 华中地区
  { brand: "华住", city: "武汉", region: "华中地区", star: 4, suffix: "酒店", base_price: 350 },
  { brand: "万豪", city: "武汉", region: "华中地区", star: 5, suffix: "大酒店", base_price: 800 },
  { brand: "洲际", city: "武汉", region: "华中地区", star: 5, suffix: "酒店", base_price: 750 },
  { brand: "凯悦", city: "武汉", region: "华中地区", star: 5, suffix: "酒店", base_price: 700 },
  
  # 上海地区 - 华东地区
  { brand: "华住", city: "上海", region: "华东地区", star: 4, suffix: "酒店", base_price: 450 },
  { brand: "万豪", city: "上海", region: "华东地区", star: 5, suffix: "大酒店", base_price: 1200 },
  { brand: "希尔顿", city: "上海", region: "华东地区", star: 5, suffix: "酒店", base_price: 1100 },
  { brand: "洲际", city: "上海", region: "华东地区", star: 5, suffix: "大酒店", base_price: 1150 },
  { brand: "香格里拉", city: "上海", region: "华东地区", star: 5, suffix: "大酒店", base_price: 1300 },
  
  # 北京地区 - 华北地区
  { brand: "华住", city: "北京", region: "华北地区", star: 4, suffix: "酒店", base_price: 450 },
  { brand: "万豪", city: "北京", region: "华北地区", star: 5, suffix: "大酒店", base_price: 1200 },
  { brand: "希尔顿", city: "北京", region: "华北地区", star: 5, suffix: "酒店", base_price: 1100 },
  { brand: "洲际", city: "北京", region: "华北地区", star: 5, suffix: "酒店", base_price: 1150 },
  { brand: "凯悦", city: "北京", region: "华北地区", star: 5, suffix: "酒店", base_price: 1100 },
  
  # 深圳地区 - 华南地区
  { brand: "华住", city: "深圳", region: "华南地区", star: 4, suffix: "酒店", base_price: 500 },
  { brand: "洲际", city: "深圳", region: "华南地区", star: 5, suffix: "酒店", base_price: 1000 },
  { brand: "香格里拉", city: "深圳", region: "华南地区", star: 5, suffix: "大酒店", base_price: 1200 },
  
  # 广州地区 - 华南地区
  { brand: "华住", city: "广州", region: "华南地区", star: 4, suffix: "酒店", base_price: 450 },
  { brand: "万豪", city: "广州", region: "华南地区", star: 5, suffix: "大酒店", base_price: 1000 },
  { brand: "洲际", city: "广州", region: "华南地区", star: 5, suffix: "酒店", base_price: 950 },
  { brand: "香格里拉", city: "广州", region: "华南地区", star: 5, suffix: "大酒店", base_price: 1100 },
  
  # 成都地区 - 西南地区
  { brand: "华住", city: "成都", region: "西南地区", star: 4, suffix: "酒店", base_price: 400 },
  { brand: "万豪", city: "成都", region: "西南地区", star: 5, suffix: "酒店", base_price: 900 },
  { brand: "希尔顿", city: "成都", region: "西南地区", star: 5, suffix: "酒店", base_price: 850 },
  { brand: "洲际", city: "成都", region: "西南地区", star: 5, suffix: "酒店", base_price: 900 },
  { brand: "凯悦", city: "成都", region: "西南地区", star: 5, suffix: "酒店", base_price: 850 },
  { brand: "香格里拉", city: "成都", region: "西南地区", star: 5, suffix: "大酒店", base_price: 1000 }
]

# ==================== 批量创建酒店 ====================
hotels_data = []

brand_city_configs.each_with_index do |config, index|
  brand_name = config[:brand]
  city = config[:city]
  
  # 检查是否已存在该品牌和城市的酒店
  existing_count = Hotel.where("brand LIKE ?", "%#{brand_name}%").where(city: city).count
  
  # 如果已有该品牌的酒店，只创建1-2家；如果没有，创建2-3家
  hotels_to_create = existing_count > 0 ? rand(1..2) : rand(2..3)
  
  hotels_to_create.times do |i|
    base_price = config[:base_price]
    star_level = config[:star]
    
    # 添加一些价格变化
    price_variation = (base_price * rand(0.8..1.2)).round(0)
    
    rating = case star_level
    when 5 then (4.5 + rand * 0.4).round(1)
    when 4 then (4.0 + rand * 0.7).round(1)
    else (3.8 + rand * 0.9).round(1)
    end
    
    # 添加地区标识符
    location_markers = {
      "武汉" => ["武昌", "汉口", "汉阳", "光谷", "江汉路"],
      "上海" => ["浦东", "静安", "徐汇", "黄浦", "虹桥"],
      "北京" => ["朝阳", "海淀", "东城", "西城", "CBD"],
      "深圳" => ["福田", "南山", "罗湖", "宝安", "龙岗"],
      "广州" => ["天河", "越秀", "海珠", "番禺", "荔湾"],
      "成都" => ["锦江", "青羊", "武侯", "成华", "高新"]
    }
    
    location = location_markers[city]&.sample || "中心"
    
    hotels_data << {
      name: "#{city}#{brand_name}#{config[:suffix]}·#{location}店",
      brand: brand_name,
      city: city,
      address: "#{city}#{location}#{address_suffixes.sample}#{rand(1..999)}号",
      rating: rating,
      price: price_variation,
      original_price: (price_variation * rand(1.15..1.35)).round(0),
      distance: "#{rand(1..15)}.#{rand(0..9)}km",
      features: features_pool.sample,
      star_level: star_level,
      is_featured: rand < 0.15,
      display_order: 10000 + index * 10 + i,
      hotel_type: 'hotel',
      is_domestic: true,
      region: config[:region],
      image_url: hotel_images.sample,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

# 批量插入酒店数据
if hotels_data.any?
  Hotel.insert_all(hotels_data)
  puts "✓ 成功创建 #{hotels_data.count} 家酒店"
  
  # 按品牌和城市统计
  stats = hotels_data.group_by { |h| [h[:brand], h[:city]] }
                     .map { |(brand, city), hotels| "#{brand}(#{city}): #{hotels.count}家" }
                     .join(", ")
  puts "  #{stats}"
else
  puts "✓ 没有需要创建的新酒店"
end

# ==================== 创建酒店房间 ====================
puts "\n正在为新酒店创建房间..."

# 获取刚创建的酒店（通过 data_version=0 和较大的 display_order）
# 注意: insert_all之后需要重新查询才能获取ID
new_hotels = Hotel.where(data_version: 0)
                  .where("display_order >= ?", 10000)

room_types = [
  { name: "标准大床房", bed_type: "1张大床", area: "25㎡" },
  { name: "标准双床房", bed_type: "2张单床", area: "28㎡" },
  { name: "豪华大床房", bed_type: "1张特大床", area: "35㎡" },
  { name: "豪华套房", bed_type: "1张特大床+沙发床", area: "50㎡" },
  { name: "行政套房", bed_type: "1张特大床+沙发床", area: "65㎡" }
]

hotel_rooms_data = []

new_hotels.each do |hotel|
  # 根据酒店星级决定房型数量
  room_count = case hotel.star_level
  when 5 then rand(4..5)  # 5星酒店创建4-5种房型
  when 4 then rand(3..4)  # 4星酒店创建3-4种房型
  else rand(2..3)         # 其他酒店创建2-3种房型
  end
  
  # 选择对应数量的房型
  selected_rooms = room_types.sample(room_count)
  
  selected_rooms.each_with_index do |room_type, idx|
    # 基础价格根据酒店价格和房型等级调整
    base_room_price = hotel.price
    
    price_multiplier = case room_type[:name]
    when "标准大床房", "标准双床房" then 1.0
    when "豪华大床房" then 1.4
    when "豪华套房" then 1.8
    when "行政套房" then 2.3
    else 1.0
    end
    
    room_price = (base_room_price * price_multiplier).round(0)
    
    hotel_rooms_data << {
      hotel_id: hotel.id,
      room_type: room_type[:name],
      bed_type: room_type[:bed_type],
      area: room_type[:area],
      price: room_price,
      original_price: (room_price * rand(1.15..1.30)).round(0),
      available_rooms: rand(5..20),
      room_category: 'overnight',  # 整晚房型
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

# 批量插入房间数据
if hotel_rooms_data.any?
  HotelRoom.insert_all(hotel_rooms_data)
  puts "✓ 成功为 #{new_hotels.count} 家酒店创建 #{hotel_rooms_data.count} 个房间"
else
  puts "✓ 没有需要创建的房间"
end

puts "✓ hotels_for_packages_v1 数据包加载完成"
