# frozen_string_literal: true

# cruises_v1 数据包
# 游轮游模块数据
#
# 用途：
# - 游轮公司、船只、航线数据
# - 游轮班次、舱房类型数据
# - 商家产品数据
#
# 加载方式：
# rake validator:reset_baseline
#
# 日期生成策略：
# - 使用 Date.today + X.days 动态生成未来60-90天的班次
# - 每次重置数据包时自动"滚动前移"，确保始终有未来班次可选
# - 每条主要航线生成8-12个班次（根据行程天数，约每7天一班）

require_relative '../../../../../app/helpers/image_seed_helper'

puts "正在加载 cruises_v1 数据包..."

# ==================== 游轮公司数据 ====================

cruise_lines_data = [
  {
    name: '皇家加勒比国际游轮',
    name_en: 'Royal Caribbean International',
    logo_url: ImageSeedHelper.random_image_from_category(:cruise_logos),
    description: '全球豪华游轮领导品牌，拥有超量子系列、绿洲系列等多个创新船队',
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    name: '地中海邮轮',
    name_en: 'MSC Cruises',
    logo_url: ImageSeedHelper.random_image_from_category(:cruise_logos),
    description: '欧洲第一、世界第四大邮轮公司，提供地中海特色服务',
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    name: '爱达邮轮',
    name_en: 'AIDA Cruises',
    logo_url: ImageSeedHelper.random_image_from_category(:cruise_logos),
    description: '德国邮轮品牌，以年轻时尚的邮轮体验著称',
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  }
]

CruiseLine.insert_all(cruise_lines_data)

# 为新插入的 CruiseLine 生成 slug（FriendlyId 需要 save 触发回调）
puts "     正在为游轮公司生成 slug..."
CruiseLine.where(slug: [nil, '']).find_each(&:save)

# ==================== 游轮船只数据 ====================

# 获取游轮公司ID
royal_caribbean = CruiseLine.find_by(name: '皇家加勒比国际游轮')
msc_cruises = CruiseLine.find_by(name: '地中海邮轮')
aida_cruises = CruiseLine.find_by(name: '爱达邮轮')

cruise_ships_data = [
  {
    cruise_line_id: royal_caribbean.id,
    name: '海洋光谱号',
    name_en: 'Spectrum of the Seas',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 168666,
    passenger_capacity: 4246,
    features: ['超量子系列首艘邮轮', '甲板跳伞', '正宗川菜料理', '套房专享皇家府邸'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: msc_cruises.id,
    name: '地中海辉煌号',
    name_en: 'MSC Bellissima',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 171598,
    passenger_capacity: 4500,
    features: ['米其林星级餐厅', '豪华购物长廊', '海上水上乐园'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: msc_cruises.id,
    name: '地中海荣耀号',
    name_en: 'MSC Grandiosa',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 181000,
    passenger_capacity: 6334,
    features: ['欧洲最大邮轮之一', '室内娱乐长廊', '卡拉拉大理石装饰', 'MSC游艇俱乐部'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: msc_cruises.id,
    name: '地中海传奇号',
    name_en: 'MSC Fantasia',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 137936,
    passenger_capacity: 3959,
    features: ['施华洛世奇水晶楼梯', '四维影院', '一级方程式赛车模拟器'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: royal_caribbean.id,
    name: '海洋和悦号',
    name_en: 'Harmony of the Seas',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 226963,
    passenger_capacity: 6780,
    features: ['世界最大邮轮之一', '中央公园', '百老汇歌剧院', '终极深渊滑梯'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: aida_cruises.id,
    name: '爱达新星号',
    name_en: 'AIDA Nova',
    image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
    tonnage: 183900,
    passenger_capacity: 5200,
    features: ['环保LNG动力', '全景观景台', '海上啤酒花园'],
    data_version: '0',
    created_at: Time.current,
    updated_at: Time.current
  }
]

CruiseShip.insert_all(cruise_ships_data)
# Regenerate slugs for FriendlyId (insert_all bypasses callbacks)
CruiseShip.find_each(&:save)

# ==================== 航线数据 ====================

cruise_routes_data = [
  { name: '日韩', region: 'japan_korea', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '三峡', region: 'yangtze_river', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '南北极', region: 'north_pole', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '东南亚', region: 'southeast_asia', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '地中海', region: 'mediterranean', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '阿拉斯加', region: 'alaska', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '欧洲河轮', region: 'europe_river', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '加勒比', region: 'caribbean', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '中东', region: 'middle_east', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current },
  { name: '西沙群岛', region: 'xisha_islands', icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations), data_version: '0', created_at: Time.current, updated_at: Time.current }
]

CruiseRoute.insert_all(cruise_routes_data)

# ==================== 游轮班次数据 ====================

# 获取船只和航线ID
spectrum = CruiseShip.find_by(name: '海洋光谱号')
bellissima = CruiseShip.find_by(name: '地中海辉煌号')
grandiosa = CruiseShip.find_by(name: '地中海荣耀号')
fantasia = CruiseShip.find_by(name: '地中海传奇号')
harmony = CruiseShip.find_by(name: '海洋和悦号')
aida_nova = CruiseShip.find_by(name: '爱达新星号')
japan_korea_route = CruiseRoute.find_by(region: 'japan_korea')
mediterranean_route = CruiseRoute.find_by(region: 'mediterranean')
southeast_asia_route = CruiseRoute.find_by(region: 'southeast_asia')
caribbean_route = CruiseRoute.find_by(region: 'caribbean')
yangtze_river_route = CruiseRoute.find_by(region: 'yangtze_river')
north_pole_route = CruiseRoute.find_by(region: 'north_pole')
alaska_route = CruiseRoute.find_by(region: 'alaska')
europe_river_route = CruiseRoute.find_by(region: 'europe_river')
middle_east_route = CruiseRoute.find_by(region: 'middle_east')
xisha_islands_route = CruiseRoute.find_by(region: 'xisha_islands')

cruise_sailings_data = []

# ==================== 行程模板定义 ====================
# 避免重复定义，提取为常量

ITINERARY_SPECTRUM_JAPAN_KOREA_6D5N = [
  { day: 1, port: '上海', title: '登船', description: '上海吴淞口码头登船，开启6天5晚日韩之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
  { day: 2, port: '海上巡航', title: '海上巡航', description: '享受游轮上的各种设施和娱乐活动', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
  { day: 3, port: '福冈', title: '岸上观光', description: '日本福冈博多港，购物天堂和美食之都', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
  { day: 4, port: '济州岛', title: '岸上观光', description: '韩国济州岛，火山岛屿风光', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
  { day: 5, port: '海上巡航', title: '海上巡航', description: '海上巡航日，放松休闲', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] },
  { day: 6, port: '上海', title: '离船', description: '返回上海吴淞口码头，结束愉快的游轮之旅', images: [ImageSeedHelper.random_image_from_category(:cruise_destinations)] }
]

ITINERARY_AIDA_SOUTHEAST_ASIA_9D8N_SHANGHAI = [
  { day: 1, port: '上海', description: '下午登船，晚上启航' },
  { day: 2, port: '海上巡航', description: '享受船上设施' },
  { day: 3, port: '海上巡航', description: '甲板活动' },
  { day: 4, port: '岘港', description: '越南海滨城市' },
  { day: 5, port: '芽庄', description: '海岛风光' },
  { day: 6, port: '新加坡', description: '狮城一日游' },
  { day: 7, port: '海上巡航', description: '船上娱乐' },
  { day: 8, port: '海上巡航', description: '晚宴之夜' },
  { day: 9, port: '上海', description: '早晨抵达' }
]

ITINERARY_AIDA_SOUTHEAST_ASIA_7D6N_HONGKONG = [
  { day: 1, port: '香港', description: '下午登船，晚上启航' },
  { day: 2, port: '海上巡航', description: '享受船上设施' },
  { day: 3, port: '岘港', description: '越南海滨城市' },
  { day: 4, port: '芽庄', description: '海岛风光' },
  { day: 5, port: '海上巡航', description: '甲板活动' },
  { day: 6, port: '海上巡航', description: '船上娱乐' },
  { day: 7, port: '香港', description: '早晨抵达' }
]

ITINERARY_BELLISSIMA_JAPAN_KOREA_7D6N_HONGKONG_1 = [
  { day: 1, port: '香港', description: '下午登船，晚上启航' },
  { day: 2, port: '海上巡航', description: '享受船上设施' },
  { day: 3, port: '冲绳', description: '热带风情' },
  { day: 4, port: '福冈', description: '购物天堂' },
  { day: 5, port: '济州岛', description: '探索韩国文化' },
  { day: 6, port: '海上巡航', description: '甲板活动' },
  { day: 7, port: '香港', description: '早晨抵达' }
]

ITINERARY_BELLISSIMA_JAPAN_KOREA_7D6N_HONGKONG_2 = [
  { day: 1, port: '香港', description: '下午登船，晚上启航' },
  { day: 2, port: '海上巡航', description: '享受船上设施' },
  { day: 3, port: '福冈', description: '日本九州' },
  { day: 4, port: '鹿儿岛', description: '樱岛火山' },
  { day: 5, port: '济州', description: '韩国济州岛' },
  { day: 6, port: '海上巡航', description: '船上娱乐' },
  { day: 7, port: '香港', description: '早晨抵达' }
]

# ==================== 动态生成班次 ====================
# 策略：每条航线根据行程天数，每隔7天生成一个班次，覆盖未来60-90天

puts "     正在生成动态日期的邮轮班次..."

# 1. 海洋光谱号 - 日韩航线 6天5晚 上海出发（为v158验证器准备）
# 生成10个班次（70天覆盖）
(0..9).each do |i|
  cruise_sailings_data << {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + (7 * i - 1).days,
    return_date: Date.today + (7 * i + 5).days,
    duration_days: 6,
    duration_nights: 5,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: ITINERARY_SPECTRUM_JAPAN_KOREA_6D5N,
    created_at: Time.current,
    updated_at: Time.current
  }
end

# 2. 爱达新星号 - 东南亚航线 9天8晚 上海出发（v116需要）
# 每10天一班（考虑9天行程），生成8个班次（80天覆盖）
(0..7).each do |i|
  cruise_sailings_data << {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: southeast_asia_route.id,
    departure_date: Date.today + (10 * i - 1).days,
    return_date: Date.today + (10 * i + 7).days,
    duration_days: 9,
    duration_nights: 8,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: ITINERARY_AIDA_SOUTHEAST_ASIA_9D8N_SHANGHAI,
    created_at: Time.current,
    updated_at: Time.current
  }
end

# 3. 爱达新星号 - 东南亚航线 7天6晚 香港出发
# 每8天一班，生成10个班次（80天覆盖）
(0..9).each do |i|
  cruise_sailings_data << {
    cruise_ship_id: aida_nova.id,
    cruise_route_id: southeast_asia_route.id,
    departure_date: Date.today + (8 * i - 1).days,
    return_date: Date.today + (8 * i + 5).days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '香港登船',
    arrival_port: '香港离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: ITINERARY_AIDA_SOUTHEAST_ASIA_7D6N_HONGKONG,
    created_at: Time.current,
    updated_at: Time.current
  }
end

# 4. 地中海辉煌号 - 日韩航线 7天6晚 香港出发（v117需要）
# 生成两种行程各5个班次，交替出发
# 第一种行程：冲绳-福冈-济州岛
(0..4).each do |i|
  cruise_sailings_data << {
    cruise_ship_id: bellissima.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + (14 * i - 1).days,  # 每两周一班，错开另一种行程
    return_date: Date.today + (14 * i + 5).days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '香港登船',
    arrival_port: '香港离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: ITINERARY_BELLISSIMA_JAPAN_KOREA_7D6N_HONGKONG_1,
    created_at: Time.current,
    updated_at: Time.current
  }
end

# 第二种行程：福冈-鹿儿岛-济州
(0..4).each do |i|
  cruise_sailings_data << {
    cruise_ship_id: bellissima.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + (14 * i + 6).days,  # 错开第一种行程7天
    return_date: Date.today + (14 * i + 12).days,
    duration_days: 7,
    duration_nights: 6,
    departure_port: '香港登船',
    arrival_port: '香港离船',
    status: 'on_sale',
    boarding_address: '香港启德邮轮码头 香港九龙承丰道33号',
    boarding_deadline: '14:30',
    itinerary: ITINERARY_BELLISSIMA_JAPAN_KOREA_7D6N_HONGKONG_2,
    created_at: Time.current,
    updated_at: Time.current
  }
end

# 5. 海洋光谱号 - 日韩航线 5天4晚 上海出发
# 生成12个班次（短途更频繁，每6天一班）
(0..11).each do |i|
  cruise_sailings_data << {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.today + (6 * i - 1).days,
    return_date: Date.today + (6 * i + 3).days,
    duration_days: 5,
    duration_nights: 4,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    boarding_address: '上海吴淞口国际邮轮码头 上海市宝山区吴淞口宝杨路1号',
    boarding_deadline: '14:30',
    itinerary: [
      { day: 1, port: '上海', title: '登船', description: '下午登船，晚上启航' },
      { day: 2, port: '济州岛', title: '岸上观光', description: '韩国济州岛，火山岛屿' },
      { day: 3, port: '釜山', title: '岸上观光', description: '韩国第二大城市' },
      { day: 4, port: '海上巡航', title: '海上巡航', description: '享受船上设施' },
      { day: 5, port: '上海', title: '离船', description: '返回上海' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  }
end

# 批量插入数据
puts "     正在插入 #{cruise_sailings_data.size} 条邮轮班次记录..."
CruiseSailing.insert_all(cruise_sailings_data) if cruise_sailings_data.any?

# ==================== 舱房类型数据 ====================

puts "     正在生成舱房类型数据..."

cabin_types_data = []

# 为每艘船生成舱房类型
[spectrum, bellissima, grandiosa, fantasia, harmony, aida_nova].each do |ship|
  cabin_types_data += [
    {
      cruise_ship_id: ship.id,
      name: '内舱房',
      category: 'interior',
      floor_range: '5-7层',
      area: 15.0,
      has_balcony: false,
      has_window: false,
      max_occupancy: 2,
      description: '舒适内舱房，配备双人床、独立卫浴、衣柜、保险箱',
      image_urls: [ImageSeedHelper.random_image_from_category(:cruise_cabins)],
      data_version: '0',
      created_at: Time.current,
      updated_at: Time.current
    },
    {
      cruise_ship_id: ship.id,
      name: '海景房',
      category: 'ocean_view',
      floor_range: '6-8层',
      area: 18.0,
      has_balcony: false,
      has_window: true,
      max_occupancy: 2,
      description: '明亮海景房，配备双人床、独立卫浴、海景窗、小沙发、保险箱',
      image_urls: [ImageSeedHelper.random_image_from_category(:cruise_cabins)],
      data_version: '0',
      created_at: Time.current,
      updated_at: Time.current
    },
    {
      cruise_ship_id: ship.id,
      name: '阳台房',
      category: 'balcony',
      floor_range: '7-10层',
      area: 22.0,
      has_balcony: true,
      has_window: true,
      max_occupancy: 3,
      description: '豪华阳台房，配备双人床、独立卫浴、私人阳台、休闲桌椅、迷你吧、保险箱',
      image_urls: [ImageSeedHelper.random_image_from_category(:cruise_cabins)],
      data_version: '0',
      created_at: Time.current,
      updated_at: Time.current
    },
    {
      cruise_ship_id: ship.id,
      name: '套房',
      category: 'suite',
      floor_range: '9-12层',
      area: 45.0,
      has_balcony: true,
      has_window: true,
      max_occupancy: 4,
      description: '顶级套房，配备特大床、独立客厅、豪华卫浴、大阳台、VIP服务、迷你吧、保险箱、浴缸',
      image_urls: [ImageSeedHelper.random_image_from_category(:cruise_cabins)],
      data_version: '0',
      created_at: Time.current,
      updated_at: Time.current
    }
  ]
end

CabinType.insert_all(cabin_types_data)

# ==================== 邮轮产品数据 ====================
# 为每个班次的每种舱房类型生成商家产品

puts "     正在生成邮轮产品数据..."

cruise_products_data = []

# 获取所有班次
all_sailings = CruiseSailing.where(data_version: '0').includes(:cruise_ship)

# 商家列表（模拟不同旅行社/OTA平台）
merchants = [
  { name: '携程旅行', badge: '近期热销', discount: 0 },
  { name: '途牛旅游', badge: '低价之选', discount: 100 },
  { name: '飞猪旅行', badge: nil, discount: 50 },
  { name: '马蜂窝', badge: nil, discount: 0 }
]

# 舱房类型基础价格（每人每晚）
base_prices = {
  'interior' => 800,
  'ocean_view' => 1200,
  'balcony' => 1800,
  'suite' => 3500
}

all_sailings.each do |sailing|
  # 获取该船只的所有舱房类型
  cabin_types = CabinType.where(cruise_ship_id: sailing.cruise_ship_id, data_version: '0')
  
  cabin_types.each do |cabin_type|
    # 计算价格：基础价格 × 夜数
    base_price = base_prices[cabin_type.category] || 1000
    nights = sailing.duration_nights || (sailing.duration_days - 1)
    price_per_person = base_price * nights
    
    # 为每个舱房类型创建2-3个商家产品（不同价格）
    merchants.sample(rand(2..3)).each do |merchant|
      final_price = price_per_person - merchant[:discount]
      
      cruise_products_data << {
        cruise_sailing_id: sailing.id,
        cabin_type_id: cabin_type.id,
        merchant_name: merchant[:name],
        badge: merchant[:badge],
        price_per_person: final_price,
        occupancy_requirement: cabin_type.max_occupancy >= 2 ? 2 : 1,
        stock: rand(5..20),
        sales_count: rand(0..50),
        status: 'on_sale',
        data_version: '0',
        created_at: Time.current,
        updated_at: Time.current
      }
    end
  end
end

puts "     正在插入 #{cruise_products_data.size} 条邮轮产品记录..."
CruiseProduct.insert_all(cruise_products_data) if cruise_products_data.any?

puts "✓ cruises_v1 数据包加载完成（生成 #{cruise_sailings_data.size} 个邮轮班次，#{cruise_products_data.size} 个商家产品，覆盖未来60-90天）"
