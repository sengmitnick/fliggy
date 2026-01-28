# frozen_string_literal: true

# hotel_packages_v1 数据包
# 酒店套餐验证数据
#
# 用途：
# - 提供丰富的酒店套餐数据用于验证
# - 包含不同城市、不同晚数、不同品牌的套餐
# - 支持1晚、2晚、1-2晚组合套餐
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 hotel_packages_v1 数据包..."

# 品牌数据
brands = [
  { name: "华住", logo: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400&q=80&fm=jpg&fit=crop&auto=format" },
  { name: "万豪", logo: "https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=400&q=80&fm=jpg&fit=crop&auto=format" },
  { name: "希尔顿", logo: "https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=400&q=80&fm=jpg&fit=crop&auto=format" },
  { name: "洲际", logo: "https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400&q=80&fm=jpg&fit=crop&auto=format" },
  { name: "凯悦", logo: "https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=400&q=80&fm=jpg&fit=crop&auto=format" },
  { name: "香格里拉", logo: "https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=400&q=80&fm=jpg&fit=crop&auto=format" }
]

regions = ["全国通用", "华东地区", "华南地区", "华北地区", "西南地区", "华中地区"]

# 清理现有数据（仅限 data_version=0）
HotelPackage.where(data_version: 0).destroy_all

# 准备批量插入数据
hotel_packages = []
current_time = Time.current

# Helper: 根据品牌和城市查找酒店ID
def find_hotel_id(brand_name, city)
  Hotel.find_by(brand: brand_name, city: city)&.id
end

# ============================================================
# 武汉地区套餐（用于 v048 验证器）
# ============================================================

# 1. 华住品牌 - 2晚连住套餐
brand_name = "华住"
city = "武汉"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 4,
  title: "【官方直营】华住美仑品牌全国140+店客房2晚连住通兑 全程不加价",
  description: "含早餐，可叠加会员权益，全国140+门店通用，客房2晚连住",
  price: 699,
  original_price: 999,
  sales_count: 1580,
  is_featured: true,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在品牌旗下任意门店使用\n3. 需提前3天预约\n4. 不可退款，可转让\n5. 节假日可能需要补差价\n6. 客房必须连住2晚，不可拆分",
  region: "华中地区",
  package_type: "vip",
  city: city,
  night_count: 2,
  refundable: false,
  instant_booking: true,
  luxury: false,
  brand_logo_url: brands[0][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 2. 万豪品牌 - 2晚连住套餐
brand_name = "万豪"
city = "武汉"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "万豪酒店客房2晚连住通兑套餐 高端商务之选",
  description: "包含双早，行政酒廊权益，全国万豪旗下酒店通用，客房2晚连住",
  price: 1299,
  original_price: 1799,
  sales_count: 856,
  is_featured: false,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在品牌旗下任意门店使用\n3. 需提前3天预约\n4. 可退款，需扣除10%手续费\n5. 节假日可能需要补差价\n6. 客房必须连住2晚，不可拆分",
  region: "华中地区",
  package_type: "vip",
  city: city,
  night_count: 2,
  refundable: true,
  instant_booking: true,
  luxury: true,
  brand_logo_url: brands[1][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 3. 希尔顿品牌 - 2晚连住套餐
brand_name = "希尔顿"
city = "武汉"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "希尔顿酒店套餐 家庭亲子首选 客房2晚连住",
  description: "含双早+双晚餐，儿童免费，全国希尔顿品牌通用，客房2晚连住",
  price: 1099,
  original_price: 1499,
  sales_count: 2340,
  is_featured: true,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在品牌旗下任意门店使用\n3. 需提前3天预约\n4. 可退款，需扣除10%手续费\n5. 节假日可能需要补差价\n6. 客房必须连住2晚，不可拆分",
  region: "华中地区",
  package_type: "standard",
  city: city,
  night_count: 2,
  refundable: true,
  instant_booking: false,
  luxury: false,
  brand_logo_url: brands[2][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 4. 洲际品牌 - 1晚套餐（武汉）
brand_name = "洲际"
city = "武汉"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "洲际酒店商务快捷1晚套餐 武汉门店通用",
  description: "商务出行首选，含双人早餐，免费停车",
  price: 499,
  original_price: 699,
  sales_count: 1120,
  is_featured: false,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在武汉地区门店使用\n3. 需提前1天预约\n4. 不可退款，可转让\n5. 节假日可能需要补差价",
  region: "华中地区",
  package_type: "standard",
  city: city,
  night_count: 1,
  refundable: false,
  instant_booking: true,
  luxury: false,
  brand_logo_url: brands[3][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 5. 凯悦品牌 - 1-2晚灵活组合套餐（武汉）
brand_name = "凯悦"
city = "武汉"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "凯悦酒店灵活组合套餐 1晚起订 武汉通用",
  description: "可选1晚住宿或2晚连住，含早餐，免费健身房",
  price: 599,
  original_price: 899,
  sales_count: 890,
  is_featured: true,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在武汉地区门店使用\n3. 需提前2天预约\n4. 可退款，需扣除10%手续费\n5. 可选1晚住宿或2晚连住（连住优惠）",
  region: "华中地区",
  package_type: "vip",
  city: city,
  night_count: 1, # 基础是1晚，但有2晚选项
  refundable: true,
  instant_booking: true,
  luxury: false,
  brand_logo_url: brands[4][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 6. 如家品牌 - 经济型1晚套餐（武汉）
brand_name = "如家"
city = "武汉"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 3,
  title: "如家酒店经济舒适1晚套餐 武汉门店通用",
  description: "经济实惠，干净卫生，含早餐，交通便利",
  price: 199,
  original_price: 299,
  sales_count: 5680,
  is_featured: true,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在武汉地区门店使用\n3. 需提前1天预约\n4. 不可退款，可转让\n5. 节假日可能需要补差价",
  region: "华中地区",
  package_type: "standard",
  city: city,
  night_count: 1,
  refundable: false,
  instant_booking: true,
  luxury: false,
  brand_logo_url: brands[0][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 7. 汉庭品牌 - 经济型2晚连住套餐（武汉）
brand_name = "汉庭"
city = "武汉"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 3,
  title: "汉庭酒店超值2晚连住套餐 武汉门店通用",
  description: "商务出行首选，含双早，WiFi免费，客房2晚连住",
  price: 358,
  original_price: 498,
  sales_count: 4320,
  is_featured: false,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在武汉地区门店使用\n3. 需提前1天预约\n4. 不可退款，可转让\n5. 节假日可能需要补差价\n6. 客房必须连住2晚，不可拆分",
  region: "华中地区",
  package_type: "standard",
  city: city,
  night_count: 2,
  refundable: false,
  instant_booking: true,
  luxury: false,
  brand_logo_url: brands[0][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 8. 7天品牌 - 快捷经济1晚套餐（武汉）
brand_name = "7天"
city = "武汉"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 3,
  title: "7天酒店快捷1晚套餐 武汉多店通用",
  description: "性价比之选，基础设施齐全，近地铁站",
  price: 159,
  original_price: 229,
  sales_count: 6780,
  is_featured: true,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在武汉地区门店使用\n3. 需提前1天预约\n4. 不可退款，可转让\n5. 节假日可能需要补差价",
  region: "华中地区",
  package_type: "standard",
  city: city,
  night_count: 1,
  refundable: false,
  instant_booking: true,
  luxury: false,
  brand_logo_url: brands[0][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# ============================================================
# 其他城市套餐
# ============================================================

# 9. 上海 - 洲际品牌 2晚连住套餐
brand_name = "洲际"
city = "上海"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "洲际酒店奢华体验套餐 客房2晚连住",
  description: "豪华房型升级，SPA体验，米其林餐厅体验，客房2晚连住",
  price: 1899,
  original_price: 2599,
  sales_count: 567,
  is_featured: false,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在上海地区门店使用\n3. 需提前3天预约\n4. 不可退款，可转让\n5. 节假日可能需要补差价\n6. 客房必须连住2晚，不可拆分",
  region: "华东地区",
  package_type: "vip",
  city: city,
  night_count: 2,
  refundable: false,
  instant_booking: true,
  luxury: true,
  brand_logo_url: brands[3][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 10. 上海 - 香格里拉品牌 1晚套餐
brand_name = "香格里拉"
city = "上海"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "香格里拉酒店商务1晚套餐 上海门店",
  description: "行政楼层，含早餐+欢迎礼遇",
  price: 799,
  original_price: 1099,
  sales_count: 1456,
  is_featured: true,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在上海地区门店使用\n3. 需提前2天预约\n4. 可退款，需扣除10%手续费\n5. 节假日可能需要补差价",
  region: "华东地区",
  package_type: "standard",
  city: city,
  night_count: 1,
  refundable: true,
  instant_booking: true,
  luxury: true,
  brand_logo_url: brands[5][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 11. 北京 - 凯悦品牌 2晚连住套餐
brand_name = "凯悦"
city = "北京"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "凯悦酒店度假套餐 限时特惠 客房2晚连住",
  description: "含三餐自助，免费延迟退房，景区门票折扣，客房2晚连住",
  price: 1499,
  original_price: 1999,
  sales_count: 2100,
  is_featured: true,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在北京地区门店使用\n3. 需提前3天预约\n4. 可退款，需扣除10%手续费\n5. 节假日可能需要补差价\n6. 客房必须连住2晚，不可拆分",
  region: "华北地区",
  package_type: "limited",
  city: city,
  night_count: 2,
  refundable: true,
  instant_booking: true,
  luxury: false,
  brand_logo_url: brands[4][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 12. 北京 - 万豪品牌 1晚套餐
brand_name = "万豪"
city = "北京"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "万豪酒店商旅快捷1晚套餐 北京通用",
  description: "商务房型，含早餐，行政酒廊",
  price: 599,
  original_price: 899,
  sales_count: 1780,
  is_featured: false,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在北京地区门店使用\n3. 需提前1天预约\n4. 可退款，需扣除10%手续费\n5. 节假日可能需要补差价",
  region: "华北地区",
  package_type: "standard",
  city: city,
  night_count: 1,
  refundable: true,
  instant_booking: true,
  luxury: false,
  brand_logo_url: brands[1][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 13. 深圳 - 香格里拉品牌 2晚连住套餐
brand_name = "香格里拉"
city = "深圳"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "香格里拉酒店尊享套餐 客房2晚连住",
  description: "行政套房，管家服务，机场接送，专属礼遇，客房2晚连住",
  price: 2299,
  original_price: 3299,
  sales_count: 345,
  is_featured: false,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在深圳地区门店使用\n3. 需提前5天预约\n4. 不可退款，可转让\n5. 节假日可能需要补差价\n6. 客房必须连住2晚，不可拆分",
  region: "华南地区",
  package_type: "vip",
  city: city,
  night_count: 2,
  refundable: false,
  instant_booking: false,
  luxury: true,
  brand_logo_url: brands[5][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 14. 深圳 - 华住品牌 1晚套餐
brand_name = "华住"
city = "深圳"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 4,
  title: "华住精选商旅1晚套餐 深圳门店通用",
  description: "经济实惠，含早餐，交通便利",
  price: 299,
  original_price: 399,
  sales_count: 3450,
  is_featured: true,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在深圳地区门店使用\n3. 需提前1天预约\n4. 不可退款，可转让\n5. 节假日可能需要补差价",
  region: "华南地区",
  package_type: "standard",
  city: city,
  night_count: 1,
  refundable: false,
  instant_booking: true,
  luxury: false,
  brand_logo_url: brands[0][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 15. 广州 - 希尔顿品牌 1-2晚灵活组合套餐
brand_name = "希尔顿"
city = "广州"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "希尔顿商务精选灵活套餐 1晚起订 广州通用",
  description: "可选1晚住宿或2晚连住，工作日专用，含早餐，免费会议室使用",
  price: 699,
  original_price: 999,
  sales_count: 1560,
  is_featured: false,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在广州地区门店使用\n3. 需提前2天预约\n4. 不可退款，可转让\n5. 可选1晚住宿或2晚连住（连住优惠）",
  region: "华南地区",
  package_type: "limited",
  city: city,
  night_count: 1, # 基础是1晚，但有2晚选项
  refundable: false,
  instant_booking: true,
  luxury: false,
  brand_logo_url: brands[2][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 16. 成都 - 洲际品牌 2晚连住套餐
brand_name = "洲际"
city = "成都"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "洲际周末度假套餐 客房2晚连住",
  description: "周末专用，含双人早餐+欢迎水果，客房2晚连住",
  price: 1299,
  original_price: 1699,
  sales_count: 980,
  is_featured: true,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在成都地区门店使用\n3. 需提前3天预约\n4. 可退款，需扣除10%手续费\n5. 节假日可能需要补差价\n6. 客房必须连住2晚，不可拆分",
  region: "西南地区",
  package_type: "standard",
  city: city,
  night_count: 2,
  refundable: true,
  instant_booking: false,
  luxury: false,
  brand_logo_url: brands[3][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 17. 成都 - 凯悦品牌 1晚套餐
brand_name = "凯悦"
city = "成都"
hotel_packages << {
  brand_name: brand_name,
  hotel_id: find_hotel_id(brand_name, city),
  star_level: 5,
  title: "凯悦酒店商务1晚套餐 成都通用",
  description: "商务楼层，含早餐，免费健身房和泳池",
  price: 499,
  original_price: 799,
  sales_count: 1890,
  is_featured: false,
  valid_days: 365,
  terms: "1. 套餐有效期365天\n2. 可在成都地区门店使用\n3. 需提前1天预约\n4. 可退款，需扣除10%手续费\n5. 节假日可能需要补差价",
  region: "西南地区",
  package_type: "standard",
  city: city,
  night_count: 1,
  refundable: true,
  instant_booking: true,
  luxury: false,
  brand_logo_url: brands[4][:logo],
  data_version: 0,
  created_at: current_time,
  updated_at: current_time
}

# 批量插入套餐数据
HotelPackage.insert_all!(hotel_packages)

puts "✅ 已创建 #{hotel_packages.length} 个酒店套餐"
puts "   - 武汉地区: #{hotel_packages.count { |p| p[:city] == '武汉' }} 个（1晚、2晚、1-2晚组合）"
puts "   - 其他城市: #{hotel_packages.count { |p| p[:city] != '武汉' }} 个"
puts "   - 1晚套餐: #{hotel_packages.count { |p| p[:night_count] == 1 }} 个"
puts "   - 2晚套餐: #{hotel_packages.count { |p| p[:night_count] == 2 }} 个"

# 为每个套餐生成选项（标准、含早、豪华）
puts "\n正在生成套餐选项..."

HotelPackage.where(data_version: 0).find_each do |package|
  base_price = package.price
  nights = package.night_count
  package_options = []
  
  # 判断是否为1-2晚灵活组合套餐（凯悦武汉、希尔顿广州）
  is_flexible = package.title.include?("灵活") || package.title.include?("1晚起订")
  
  if is_flexible
    # 灵活组合套餐：提供1晚和2晚两种选项
    
    # 选项1: 1晚标准套餐（不含早餐）
    package_options << {
      hotel_package_id: package.id,
      name: "标准套餐（1晚）",
      price: base_price,
      original_price: (base_price * 1.3).to_i,
      night_count: 1,
      description: "1晚住宿，不含早餐",
      display_order: 0,
      data_version: 0,
      created_at: current_time,
      updated_at: current_time
    }
    
    # 选项2: 1晚含早套餐
    package_options << {
      hotel_package_id: package.id,
      name: "含早套餐（1晚）",
      price: base_price + 50,
      original_price: ((base_price + 50) * 1.3).to_i,
      night_count: 1,
      description: "1晚住宿，含双人早餐",
      display_order: 1,
      data_version: 0,
      created_at: current_time,
      updated_at: current_time
    }
    
    # 选项3: 2晚连住标准套餐（不含早餐）
    package_options << {
      hotel_package_id: package.id,
      name: "标准套餐（2晚连住）",
      price: base_price * 2,
      original_price: ((base_price * 2) * 1.3).to_i,
      night_count: 2,
      description: "2晚连住，不含早餐",
      display_order: 2,
      data_version: 0,
      created_at: current_time,
      updated_at: current_time
    }
    
    # 选项4: 2晚连住含早套餐
    package_options << {
      hotel_package_id: package.id,
      name: "含早套餐（2晚连住）",
      price: (base_price * 2) + 100,
      original_price: (((base_price * 2) + 100) * 1.3).to_i,
      night_count: 2,
      description: "2晚连住，含双人早餐",
      display_order: 3,
      data_version: 0,
      created_at: current_time,
      updated_at: current_time
    }
    
    # 选项5: 2晚连住豪华套餐
    package_options << {
      hotel_package_id: package.id,
      name: "豪华套餐（2晚连住）",
      price: (base_price * 2) + 240,
      original_price: (((base_price * 2) + 240) * 1.3).to_i,
      night_count: 2,
      description: "2晚连住，含双人早餐+晚餐",
      display_order: 4,
      data_version: 0,
      created_at: current_time,
      updated_at: current_time
    }
  else
    # 固定晚数套餐：按晚数生成选项
    
    # 选项1: 标准套餐（不含早餐）
    package_options << {
      hotel_package_id: package.id,
      name: "标准套餐",
      price: base_price,
      original_price: (base_price * 1.3).to_i,
      night_count: nights,
      description: "#{nights}晚#{nights > 1 ? '连住' : '住宿'}，不含早餐",
      display_order: 0,
      data_version: 0,
      created_at: current_time,
      updated_at: current_time
    }
    
    # 选项2: 含早套餐
    package_options << {
      hotel_package_id: package.id,
      name: "含早套餐",
      price: base_price + (nights * 50),
      original_price: ((base_price + (nights * 50)) * 1.3).to_i,
      night_count: nights,
      description: "#{nights}晚#{nights > 1 ? '连住' : '住宿'}，含双人早餐",
      display_order: 1,
      data_version: 0,
      created_at: current_time,
      updated_at: current_time
    }
    
    # 选项3: 豪华套餐（仅2晚及以上）
    if nights >= 2
      package_options << {
        hotel_package_id: package.id,
        name: "豪华套餐",
        price: base_price + (nights * 120),
        original_price: ((base_price + (nights * 120)) * 1.3).to_i,
        night_count: nights,
        description: "#{nights}晚连住，含双人早餐+晚餐",
        display_order: 2,
        data_version: 0,
        created_at: current_time,
        updated_at: current_time
      }
    end
  end
  
  PackageOption.insert_all!(package_options)
end

puts "✅ 已生成套餐选项"
puts "   - 总选项数: #{PackageOption.where(data_version: 0).count}"
puts "\n✓ 数据包加载完成"
