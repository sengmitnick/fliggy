# frozen_string_literal: true

# hotels_v1 数据包 - 统一的酒店数据包
# 合并所有城市、套餐酒店、Phase2字段更新、价格修复、套餐关联
#
# 用途：
# - 创建全国主要城市的酒店数据
# - 为酒店套餐提供对应的酒店
# - 添加Phase 2字段（facilities, cancellation_policy, price_per_night）
# - 同步酒店价格为实际最低房价
# - 更新酒店套餐与酒店的关联关系
#
# 加载方式：
# rake validator:reset_baseline

require_relative '../../../../../app/helpers/image_seed_helper'
require 'bcrypt'

puts "正在加载 hotels_v1 数据包..."

timestamp = Time.current

# ==================== 城市和品牌配置 ====================
cities = [
  "深圳", "上海", "北京", "广州", "杭州",
  "成都", "西安", "南京", "武汉", "重庆",
  "天津", "苏州", "厦门", "青岛", "长沙",
  "郑州", "济南", "合肥", "南昌", "昆明",
  "三亚"  # 新增三亚，支持v180验证器
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

# ==================== 步骤1: 批量创建主要城市酒店 ====================
puts "\n[步骤1] 批量创建主要城市酒店..."
hotels_data = []
hotel_index = 0

# 国际品牌酒店 (每个城市 4-6 家)
cities.each do |city|
  international_brands.sample(rand(4..6)).each do |brand|
    hotel_index += 1
    star_level = brand[:star]
    
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
      price: base_price,
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
      price: base_price,
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
["北京", "杭州"].each do |city|
  next unless cities.include?(city)
  
  5.times do
    hotel_index += 1
    location_suffix = city == "北京" ? ['中关村', '国贸', '金融街', '望京', '亦庄'].sample : ['西湖', '滨江', '钓鱼台', '萎萃', '城西'].sample
    
    hotels_data << {
      name: "#{city}商务酒店·#{location_suffix}店",
      brand: "商务酒店",
      city: city,
      address: "#{city}#{address_suffixes.sample}#{rand(1..999)}号",
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

# 上海低价青旅和经济型酒店（支持 v186 验证器 - 预算≤500元，酒店≤200元）
if cities.include?("上海")
  # 青年旅舍（多床位房间，价格80-150元）
  [
    { name: "上海外滩国际青年旅舍", price: 120 },
    { name: "上海人民广场青旅", price: 100 },
    { name: "上海虹桥机场青旅", price: 90 },
    { name: "上海浦东青年旅社", price: 110 },
    { name: "上海南京路背包客栈", price: 85 }
  ].each do |hostel|
    hotel_index += 1
    hotels_data << {
      name: hostel[:name],
      brand: "青旅",
      city: "上海",
      address: "上海#{address_suffixes.sample}#{rand(1..999)}号",
      rating: (3.8 + rand * 0.6).round(1),
      price: hostel[:price],
      original_price: (hostel[:price] * 1.2).round(0),
      distance: "#{rand(1..8)}.#{rand(0..9)}km",
      features: ["免费WiFi", "公共厨房", "洗衣房", "行李寄存", "24小时前台"],
      star_level: 2,
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
  
  # 经济型连锁酒店（单人间，价格150-200元）
  [
    { name: "速8酒店·上海火车站店", price: 180 },
    { name: "宜必思酒店·上海南站店", price: 190 },
    { name: "布丁酒店·上海徐家汇店", price: 160 },
    { name: "格林豪泰·上海虹桥店", price: 175 },
    { name: "莫泰168·上海人民广场店", price: 170 }
  ].each do |budget_hotel|
    hotel_index += 1
    hotels_data << {
      name: budget_hotel[:name],
      brand: budget_hotel[:name].split('·').first,
      city: "上海",
      address: "上海#{address_suffixes.sample}#{rand(1..999)}号",
      rating: (3.9 + rand * 0.5).round(1),
      price: budget_hotel[:price],
      original_price: (budget_hotel[:price] * 1.15).round(0),
      distance: "#{rand(1..10)}.#{rand(0..9)}km",
      features: ["免费WiFi", "24小时前台", "空调", "独立卫浴"],
      star_level: 2,
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

# 上海CBD核心区的民宿（支持 v099/v111 验证器）
if cities.include?("上海")
  ["山海居", "云溪小筑", "半山客栈", "水云间", "竹林雅居"].each_with_index do |homestay_name, idx|
    hotel_index += 1
    rating = 4.5 + (idx * 0.1)
    base_price = rand(250..450)
    
    hotels_data << {
      name: "上海#{homestay_name}",
      brand: "",
      city: "上海",
      address: "上海CBD核心区#{rand(1..999)}号",
      rating: rating,
      price: base_price,
      original_price: (base_price * rand(1.1..1.2)).round(0),
      distance: "#{rand(1..5)}.#{rand(0..9)}km",
      features: ["免费WiFi", "厨房", "洗衣机", "独立卫浴", "景观阳台", "24小时热水"],
      star_level: nil,
      is_featured: idx < 2,
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

# 火车站附近酒店（支持 V131/V134/V197 等验证器）
["上海", "天津"].each do |city|
  next unless cities.include?(city)
  
  3.times do |idx|
    hotel_index += 1
    brand = domestic_brands.sample
    star_level = brand[:star]
    
    base_price = case star_level
    when 4 then rand(300..500)
    else rand(200..350)
    end
    
    hotel_name = if idx == 0
      "#{brand[:name]}酒店·#{city}火车站店"
    else
      "#{brand[:name]}酒店·#{city}店"
    end
    
    # V197要求距离≤1.0km，所以第一家酒店设置为0.8km
    distance_value = if idx == 0
      "0.8km"
    else
      "#{rand(1..3)}.#{rand(0..9)}km"
    end
    
    hotels_data << {
      name: hotel_name,
      brand: brand[:name],
      city: city,
      address: "#{city}火车站#{rand(1..999)}号",
      rating: (4.0 + rand * 0.8).round(1),
      price: base_price,
      original_price: (base_price * rand(1.1..1.25)).round(0),
      distance: distance_value,
      features: features_pool.sample,
      star_level: star_level,
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

puts "   💾 批量插入 #{hotels_data.count} 家主要城市酒店..."

# ==================== 步骤1.5: 添加验证器特定酒店到主数组 ====================
puts "   ⚡️ 添加验证器特定酒店..."

# V318: 张家界武陵源度假酒店
hotels_data << {
  name: "张家界武陵源度假酒店",
  brand: "度假酒店",
  city: "张家界",
  address: "张家界市武陵源区武陵大道168号",
  rating: 4.7,
  price: 480,
  original_price: 580,
  distance: "3.2km",
  features: ["免费WiFi", "景区接送", "山景房", "餐厅", "景区门票代订"],
  star_level: 4,
  is_featured: true,
  display_order: 20001,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: ImageSeedHelper.random_image_from_category(:hotels),
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# V319: 三亚亚龙湾亲子度假酒店
hotels_data << {
  name: "三亚亚龙湾亲子度假酒店",
  brand: "亲子度假",
  city: "三亚",
  address: "三亚市亚龙湾旅游度假区龙源路88号",
  rating: 4.8,
  price: 880,
  original_price: 1080,
  distance: "1.5km",
  features: ["免费WiFi", "儿童乐园", "游泳池", "亲子活动", "海景房", "餐厅"],
  star_level: 5,
  is_featured: true,
  display_order: 20002,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: ImageSeedHelper.random_image_from_category(:hotels),
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# V320: 崇礼万龙度假酒店
hotels_data << {
  name: "崇礼万龙度假酒店",
  brand: "万龙",
  city: "张家口",
  address: "张家口市崇礼区红花梁滑雪场",
  rating: 4.8,
  price: 980,
  original_price: 1280,
  distance: "0.5km",
  features: ["免费WiFi", "滑雪装备租赁", "温泉SPA", "雪道直达", "餐厅", "酒吧"],
  star_level: 4,
  is_featured: true,
  display_order: 20003,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: ImageSeedHelper.random_image_from_category(:hotels),
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# V198: 北京欢乐谷主题酒店
hotels_data << {
  name: "北京欢乐谷主题酒店",
  brand: "欢乐谷",
  city: "北京",
  address: "北京市朝阳区东四环小武基北路欢乐谷景区1号",
  rating: 4.6,
  price: 380,
  original_price: 480,
  distance: "0.2km",
  features: ["免费WiFi", "主题房间", "欢乐谷门票优惠", "景区直达", "餐厅", "儿童乐园"],
  star_level: 4,
  is_featured: true,
  display_order: 20004,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: ImageSeedHelper.random_image_from_category(:hotels),
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# V198: 如家酒店·北京欢乐谷店
hotels_data << {
  name: "如家酒店·北京欢乐谷店",
  brand: "如家",
  city: "北京",
  address: "北京市朝阳区东四环小武基北路88号",
  rating: 4.3,
  price: 220,
  original_price: 280,
  distance: "0.5km",
  features: ["免费WiFi", "24小时前台", "欢乐谷门票代订", "免费早餐", "行李寄存"],
  star_level: 3,
  is_featured: false,
  display_order: 20005,
  hotel_type: 'hotel',
  is_domestic: true,
  region: '国内',
  image_url: ImageSeedHelper.random_image_from_category(:hotels),
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

puts "   ✓ 添加了 5 家验证器特定酒店到主数组"

Hotel.insert_all(hotels_data)

# ==================== 步骤2: 为酒店套餐创建配套酒店 (hotels_for_packages) ====================
puts "\n[步骤2] 为酒店套餐创建配套酒店..."

brand_city_configs = [
  # 武汉地区 - 华中地区
  { brand: "华住", city: "武汉", region: "华中地区", star: 4, suffix: "酒店", base_price: 350 },
  { brand: "万豪", city: "武汉", region: "华中地区", star: 5, suffix: "大酒店", base_price: 800 },
  { brand: "希尔顿", city: "武汉", region: "华中地区", star: 5, suffix: "酒店", base_price: 750 },
  { brand: "洲际", city: "武汉", region: "华中地区", star: 5, suffix: "酒店", base_price: 750 },
  { brand: "凯悦", city: "武汉", region: "华中地区", star: 5, suffix: "酒店", base_price: 700 },
  { brand: "如家", city: "武汉", region: "华中地区", star: 3, suffix: "酒店", base_price: 200 },
  { brand: "汉庭", city: "武汉", region: "华中地区", star: 3, suffix: "酒店", base_price: 180 },
  { brand: "7天", city: "武汉", region: "华中地区", star: 3, suffix: "酒店", base_price: 150 },
  
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
  { brand: "希尔顿", city: "深圳", region: "华南地区", star: 5, suffix: "酒店", base_price: 1050 },
  
  # 广州地区 - 华南地区
  { brand: "华住", city: "广州", region: "华南地区", star: 4, suffix: "酒店", base_price: 450 },
  { brand: "万豪", city: "广州", region: "华南地区", star: 5, suffix: "大酒店", base_price: 1000 },
  { brand: "希尔顿", city: "广州", region: "华南地区", star: 5, suffix: "酒店", base_price: 980 },
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

location_markers = {
  "武汉" => ["武昌", "汉口", "汉阳", "光谷", "江汉路"],
  "上海" => ["浦东", "静安", "徐汇", "黄浦", "虹桥"],
  "北京" => ["朝阳", "海淀", "东城", "西城", "CBD"],
  "深圳" => ["福田", "南山", "罗湖", "宝安", "龙岗"],
  "广州" => ["天河", "越秀", "海珠", "番禺", "荔湾"],
  "成都" => ["锦江", "青羊", "武侯", "成华", "高新"]
}

package_hotels_data = []

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
    
    price_variation = (base_price * rand(0.8..1.2)).round(0)
    
    rating = case star_level
    when 5 then (4.5 + rand * 0.4).round(1)
    when 4 then (4.0 + rand * 0.7).round(1)
    else (3.8 + rand * 0.9).round(1)
    end
    
    location = location_markers[city]&.sample || "中心"
    
    package_hotels_data << {
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
      image_url: ImageSeedHelper.random_image_from_category(:hotels),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

if package_hotels_data.any?
  Hotel.insert_all(package_hotels_data)
  puts "   ✓ 成功创建 #{package_hotels_data.count} 家配套酒店"
else
  puts "   ✓ 没有需要创建的配套酒店"
end

# ==================== 步骤3: 创建酒店房间 ====================
puts "\n[步骤3] 创建酒店房间..."

# 获取所有酒店
all_hotels = Hotel.where(data_version: 0).pluck(:id, :hotel_type, :price, :star_level, :city).map do |id, type, price, star, city|
  { id: id, type: type, price: price, star: star, city: city }
end

room_types = [
  { name: "标准大床房", bed_type: "1张大床", area: "25㎡" },
  { name: "标准双床房", bed_type: "2张单床", area: "28㎡" },
  { name: "豪华大床房", bed_type: "1张特大床", area: "35㎡" },
  { name: "豪华套房", bed_type: "1张特大床+沙发床", area: "50㎡" },
  { name: "行政套房", bed_type: "1张特大床+沙发床", area: "65㎡" }
]

overnight_room_types = [
  { type: "标准双床房", bed: "双床", area: "28㎡", category: "overnight", factor: 1.0 },
  { type: "豪华大床房", bed: "大床", area: "35㎡", category: "overnight", factor: 1.3 },
  { type: "行政套房", bed: "大床", area: "50㎡", category: "overnight", factor: 1.8 },
  { type: "家庭房", bed: "双床+沙发床", area: "45㎡", category: "overnight", factor: 1.5 }
]

# 含早餐房型（支持v183验证器）
breakfast_room_types = [
  { type: "标准双床房（含早）", bed: "双床", area: "28㎡", category: "overnight", factor: 1.15 },
  { type: "豪华大床房（含早）", bed: "大床", area: "35㎡", category: "overnight", factor: 1.45 },
  { type: "行政套房（含早）", bed: "大床", area: "50㎡", category: "overnight", factor: 1.95 }
]

hourly_room_types = [
  { type: "2小时房", bed: "大床", area: "25㎡", category: "hourly", factor: 0.3 },
  { type: "3小时房", bed: "大床", area: "28㎡", category: "hourly", factor: 0.4 },
  { type: "4小时房", bed: "双床", area: "30㎡", category: "hourly", factor: 0.5 }
]

hotel_rooms_data = []

all_hotels.each do |hotel_info|
  hotel_id = hotel_info[:id]
  is_homestay = hotel_info[:type] == 'homestay'
  base_price = hotel_info[:price]
  star_level = hotel_info[:star] || 3
  
  # CRITICAL: 确保第一个房型 factor=1.0 总是被选中，保证 hotel.price = minimum(room.price)
  if is_homestay
    selected_rooms = [overnight_room_types[0]]
    selected_rooms += overnight_room_types[1..-1].sample(rand(0..1))
  else
    selected_rooms = [overnight_room_types[0]]
    selected_rooms += overnight_room_types[1..-1].sample(rand(1..2))
    
    # 星级酒店添加含早餐房型 (star >= 4)
    if star_level >= 4
      selected_rooms += breakfast_room_types.sample(rand(1..2))
    end
    
    # 部分酒店有钟点房 (30%概率)
    if rand < 0.3
      selected_rooms += hourly_room_types.sample(rand(1..2))
    end
  end
  
  selected_rooms.each do |room|
    hotel_rooms_data << {
      hotel_id: hotel_id,
      room_type: room[:type],
      bed_type: room[:bed],
      area: room[:area],
      room_category: room[:category],
      price: (base_price * room[:factor]).round(0),
      available_rooms: is_homestay ? rand(2..5) : rand(5..20),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

if hotel_rooms_data.any?
  HotelRoom.insert_all(hotel_rooms_data)
  puts "   ✓ 成功创建 #{hotel_rooms_data.count} 个房间"
else
  puts "   ✓ 没有需要创建的房间"
end

# 杭州无烟房（Phase 2专用）
puts "   ⚡️ 为杭州酒店添加无烟房..."
hangzhou_hotels = Hotel.where(city: "杭州", data_version: 0).limit(5)
non_smoking_rooms_data = []

hangzhou_hotels.each do |hotel|
  next if HotelRoom.exists?(hotel_id: hotel.id, room_type: "无烟客房", data_version: 0)
  
  non_smoking_rooms_data << {
    hotel_id: hotel.id,
    room_type: "无烟客房",
    bed_type: "双床",
    area: 30.0,
    room_category: "overnight",
    price: hotel.price + 50,
    available_rooms: 8,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

if non_smoking_rooms_data.any?
  HotelRoom.insert_all(non_smoking_rooms_data)
  puts "      ✅ 成功为杭州 #{non_smoking_rooms_data.size} 家酒店添加无烟房"
end

# ==================== 步骤4: 创建酒店关联数据 (设施、政策、评论、亮点、周边) ====================
puts "\n[步骤4] 创建酒店关联数据..."

# 创建真实用户
real_users_data = [
  { email: "zhangwei@163.com", name: "张伟" },
  { email: "liping@qq.com", name: "李婷" },
  { email: "wanghao@gmail.com", name: "王昊" },
  { email: "liujing@126.com", name: "刘静" },
  { email: "chenlei@sina.com", name: "陈雷" }
]

real_users = []
real_users_data.each do |user_data|
  user = User.find_or_create_by(email: user_data[:email]) do |u|
    u.name = user_data[:name]
    u.password_digest = BCrypt::Password.create("password123")
  end
  real_users << user
end

facilities_templates = [
  { name: "免费WiFi", icon: "wifi", description: "全酒店覆盖高速无线网络", category: "网络" },
  { name: "健身房", icon: "dumbbell", description: "24小时开放的现代化健身中心", category: "健身" },
  { name: "游泳池", icon: "swimmer", description: "室内恒温游泳池", category: "娱乐" },
  { name: "餐厅", icon: "utensils", description: "提供中西式美食", category: "餐饮" },
  { name: "停车场", icon: "parking", description: "免费地下停车位", category: "停车" }
]

hotel_comments = [
  "酒店位置很好，交通便利，服务周到。",
  "房间宽敞明亮,设施齐全，非常满意。",
  "早餐丰富美味，员工态度友好热情。"
]

homestay_comments = [
  "民宿很温馨，像在家一样舒适。",
  "房东很热情，给了很多旅游建议。"
]

facilities_data = []
policies_data = []
reviews_data = []
highlights_data = []
nearby_places_data = []

all_hotels.each_with_index do |hotel_info, index|
  hotel_id = hotel_info[:id]
  is_homestay = hotel_info[:type] == 'homestay'
  star_level = hotel_info[:star] || 3
  
  # 设施
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
  
  # 政策
  # 上海的4-5星酒店有50%概率支持提前入住
  city_name = hotel_info[:city]
  supports_early_checkin = (city_name == '上海' && star_level >= 4 && rand < 0.5)
  
  policies_data << {
    hotel_id: hotel_id,
    check_in_time: "14:00后",
    check_out_time: "12:00前",
    pet_policy: is_homestay ? "可携带宠物" : "暂不支持携带宠物",
    breakfast_type: (star_level >= 4 && !is_homestay) ? "含早餐" : "不含早餐",
    breakfast_hours: "每天07:00-10:00",
    breakfast_price: (star_level >= 4 && !is_homestay) ? 0 : rand(20..50),
    payment_methods: ["银联", "支付宝", "微信支付"],
    early_checkin_available: supports_early_checkin,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 评论
  comments = is_homestay ? homestay_comments : hotel_comments
  comments.sample(rand(2..3)).each do |comment|
    reviews_data << {
      hotel_id: hotel_id,
      user_id: real_users.sample.id,
      rating: (4.0 + rand * 1.0).round(1),
      comment: comment,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
  
  # 亮点 (仅前50家)
  if index < 50 && star_level >= 4
    highlights_data << {
      hotel_id: hotel_id,
      title: "活力健身中心",
      description: "配备先进器械的健身房",
      icon: "fitness",
      display_order: 1,
      data_version: '0',
      created_at: timestamp,
      updated_at: timestamp
    }
  end
  
  # 周边信息 (仅前50家)
  if index < 50
    nearby_places_data << {
      hotel_id: hotel_id,
      place_type: "地铁站",
      name: "地铁站",
      distance: "距酒店步行#{rand(200..800)}米",
      description: "",
      display_order: 1,
      data_version: '0',
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

HotelFacility.insert_all(facilities_data) if facilities_data.any?
HotelPolicy.insert_all(policies_data) if policies_data.any?
HotelReview.insert_all(reviews_data) if reviews_data.any?
HotelHighlight.insert_all(highlights_data) if highlights_data.any?
HotelNearbyPlace.insert_all(nearby_places_data) if nearby_places_data.any?

puts "   ✓ 设施: #{facilities_data.count}, 政策: #{policies_data.count}, 评论: #{reviews_data.count}"

# ==================== 步骤5: Phase 2字段更新 (hotels_phase2_fields_update) ====================
puts "\n[步骤5] 更新Phase 2字段..."

hotels = Hotel.where(data_version: 0).to_a

hotels.each_slice(100) do |batch|
  updates = batch.map do |hotel|
    is_premium = hotel.price.to_f >= 500
    has_pool = is_premium || (hotel.rating.to_f >= 4.5)
    has_gym = is_premium
    has_breakfast = hotel.rating.to_f >= 4.0
    # 成都的某些酒店支持宠物友好
    is_chengdu_pet_friendly = hotel.city == '成都' && ['华住', '万豪', '希尔顿'].include?(hotel.brand) && hotel.rating.to_f >= 4.0
    # 杭州的酒店提供无烟客房
    is_hangzhou_non_smoking = hotel.city == '杭州' && hotel.rating.to_f >= 4.0
    
    facilities_list = ['WiFi', '停车场']
    facilities_list << '游泳池' if has_pool
    facilities_list << '健身房' if has_gym
    facilities_list << '早餐' if has_breakfast
    facilities_list << '餐厅' if is_premium
    facilities_list << '宠物友好' if is_chengdu_pet_friendly
    facilities_list << '无烟客房' if is_hangzhou_non_smoking
    
    cancellation = if is_premium
      '任何时间免费取消'
    elsif hotel.rating.to_f >= 4.0
      '入住前24小时免费取消'
    else
      '入住前48小时免费取消'
    end
    
    {
      id: hotel.id,
      facilities: facilities_list.join(', '),
      cancellation_policy: cancellation,
      price_per_night: hotel.price
    }
  end
  
  Hotel.upsert_all(updates, unique_by: :id)
end

puts "   ✓ 已更新 #{hotels.count} 家酒店的Phase 2字段"

# ==================== 步骤6: 同步酒店价格 (hotels_all_fix) ====================
puts "\n[步骤6] 同步酒店价格为实际最低房价..."

hotel_price_updates = []
Hotel.where(data_version: 0).find_each do |hotel|
  min_room_price = hotel.hotel_rooms.minimum(:price)
  if min_room_price && hotel.price != min_room_price
    hotel_price_updates << { id: hotel.id, price: min_room_price }
  end
end

if hotel_price_updates.any?
  when_clauses = hotel_price_updates.map { |h| "WHEN #{h[:id]} THEN #{h[:price]}" }.join(" ")
  Hotel.where(id: hotel_price_updates.map { |h| h[:id] }).update_all("price = CASE id #{when_clauses} END")
  puts "   ✓ 已同步 #{hotel_price_updates.size} 家酒店价格"
else
  puts "   ✓ 所有酒店价格已一致，无需同步"
end

# ==================== 步骤7: 更新酒店套餐关联 (z_hotel_packages_associations) ====================
puts "\n[步骤7] 更新酒店套餐关联..."

created_packages = HotelPackage.where(data_version: 0, hotel_id: nil)

if created_packages.empty?
  puts "   ✓ 没有需要更新关联的套餐"
else
  hotel_associations = {}
  updated_count = 0
  missing_hotels = []
  
  created_packages.each do |package|
    cache_key = "#{package.brand_name}|#{package.city}"
    
    unless hotel_associations.key?(cache_key)
      hotel = Hotel.find_by(brand: package.brand_name, city: package.city, data_version: 0)
      hotel_associations[cache_key] = hotel&.id
    end
    
    hotel_id = hotel_associations[cache_key]
    
    if hotel_id
      package.update_column(:hotel_id, hotel_id)
      updated_count += 1
    else
      missing_hotels << "#{package.brand_name} (#{package.city})"
    end
  end
  
  puts "   ✅ 已更新 #{updated_count} 个套餐的酒店关联"
  
  if missing_hotels.any?
    puts "   ⚠️  以下品牌+城市组合未找到匹配的酒店:"
    missing_hotels.uniq.each { |missing| puts "      → #{missing}" }
  end
end

puts "\n📊 统计信息："
puts "  总酒店数: #{Hotel.count}"
puts "  - 国内酒店: #{Hotel.where(hotel_type: 'hotel').count}"
puts "  - 民宿: #{Hotel.where(hotel_type: 'homestay').count}"
puts "  总房间数: #{HotelRoom.count}"

puts "\n✅ hotels_v1 数据包加载完成！"
