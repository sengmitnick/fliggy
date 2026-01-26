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
# rails runner "load Rails.root.join('app/validators/support/data_packs/v1/cruises.rb')"

puts "正在加载 cruises_v1 数据包..."

# ==================== 游轮公司数据 ====================

cruise_lines_data = [
  {
    name: '皇家加勒比国际游轮',
    name_en: 'Royal Caribbean International',
    logo_url: 'https://images.unsplash.com/photo-1548574505-5e239809ee19?w=200&h=200&fit=crop',
    description: '全球豪华游轮领导品牌，拥有超量子系列、绿洲系列等多个创新船队',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    name: '地中海邮轮',
    name_en: 'MSC Cruises',
    logo_url: 'https://images.unsplash.com/photo-1563298723-dcfebaa392e3?w=200&h=200&fit=crop',
    description: '欧洲第一、世界第四大邮轮公司，提供地中海特色服务',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    name: '爱达邮轮',
    name_en: 'AIDA Cruises',
    logo_url: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=200&h=200&fit=crop',
    description: '德国邮轮品牌，以年轻时尚的邮轮体验著称',
    created_at: Time.current,
    updated_at: Time.current
  }
]

CruiseLine.insert_all(cruise_lines_data)

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
    image_url: 'https://images.unsplash.com/photo-1568481572796-cac3501604fc?w=800&h=600&fit=crop',
    tonnage: 168666,
    passenger_capacity: 4246,
    features: ['超量子系列首艘邮轮', '甲板跳伞', '正宗川菜料理', '套房专享皇家府邸'],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: msc_cruises.id,
    name: '地中海辉煌号',
    name_en: 'MSC Bellissima',
    image_url: 'https://images.unsplash.com/photo-1599640842225-85d111c60e6b?w=800&h=600&fit=crop',
    tonnage: 171598,
    passenger_capacity: 4500,
    features: ['米其林星级餐厅', '豪华购物长廊', '海上水上乐园'],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_line_id: aida_cruises.id,
    name: '爱达新星号',
    name_en: 'AIDA Nova',
    image_url: 'https://images.unsplash.com/photo-1605408499391-6368c628ef42?w=800&h=600&fit=crop',
    tonnage: 183900,
    passenger_capacity: 5200,
    features: ['环保LNG动力', '全景观景台', '海上啤酒花园'],
    created_at: Time.current,
    updated_at: Time.current
  }
]

CruiseShip.insert_all(cruise_ships_data)
# Regenerate slugs for FriendlyId (insert_all bypasses callbacks)
CruiseShip.find_each(&:save)

# ==================== 航线数据 ====================

cruise_routes_data = [
  { name: '日韩', region: 'japan_korea', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '三峡', region: 'yangtze_river', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '南北极', region: 'north_pole', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '东南亚', region: 'southeast_asia', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '地中海', region: 'mediterranean', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '阿拉斯加', region: 'alaska', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '欧洲河轮', region: 'europe_river', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '加勒比', region: 'caribbean', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '中东', region: 'middle_east', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current },
  { name: '西沙群岛', region: 'xisha_islands', icon_url: 'tourism/邮轮游.png', created_at: Time.current, updated_at: Time.current }
]

CruiseRoute.insert_all(cruise_routes_data)

# ==================== 游轮班次数据 ====================

# 获取船只和航线ID
spectrum = CruiseShip.find_by(name: '海洋光谱号')
bellissima = CruiseShip.find_by(name: '地中海辉煌号')
japan_korea_route = CruiseRoute.find_by(region: 'japan_korea')
mediterranean_route = CruiseRoute.find_by(region: 'mediterranean')

cruise_sailings_data = [
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.parse('2026-01-23'),
    return_date: Date.parse('2026-01-28'),
    duration_days: 6,
    duration_nights: 5,
    departure_port: '香港登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    itinerary: [
      { day: 1, port: '香港', description: '下午登船，晚上启航' },
      { day: 2, port: '海上巡航', description: '享受船上设施' },
      { day: 3, port: '冲绳', description: '自由活动，探索琉球文化' },
      { day: 4, port: '福冈', description: '品尝地道日本料理' },
      { day: 5, port: '海上巡航', description: '甲板活动' },
      { day: 6, port: '上海', description: '早晨抵达，离船' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    cruise_route_id: japan_korea_route.id,
    departure_date: Date.parse('2026-01-28'),
    return_date: Date.parse('2026-02-01'),
    duration_days: 5,
    duration_nights: 4,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    itinerary: [
      { day: 1, port: '上海', description: '下午登船，晚上启航' },
      { day: 2, port: '济州岛', description: '探索韩国文化' },
      { day: 3, port: '釜山', description: '海云台海滩' },
      { day: 4, port: '海上巡航', description: '船上娱乐' },
      { day: 5, port: '上海', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: bellissima.id,
    cruise_route_id: mediterranean_route.id,
    departure_date: Date.parse('2026-02-10'),
    return_date: Date.parse('2026-02-17'),
    duration_days: 8,
    duration_nights: 7,
    departure_port: '上海登船',
    arrival_port: '上海离船',
    status: 'on_sale',
    itinerary: [
      { day: 1, port: '上海', description: '下午登船' },
      { day: 2, port: '长崎', description: '日本历史名城' },
      { day: 3, port: '福冈', description: '购物天堂' },
      { day: 4, port: '海上巡航', description: '享受船上设施' },
      { day: 5, port: '冲绳', description: '热带风情' },
      { day: 6, port: '海上巡航', description: '甲板活动' },
      { day: 7, port: '海上巡航', description: '晚宴之夜' },
      { day: 8, port: '上海', description: '早晨抵达' }
    ],
    created_at: Time.current,
    updated_at: Time.current
  }
]

CruiseSailing.insert_all(cruise_sailings_data)

# ==================== 舱房类型数据 ====================

cabin_types_data = [
  # 海洋光谱号 - 舱房类型
  {
    cruise_ship_id: spectrum.id,
    name: '阳台房',
    category: 'balcony',
    floor_range: '6-13层',
    area: 18,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '独立观海阳台',
    image_urls: [
      'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&h=400&fit=crop',
      'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600&h=400&fit=crop'
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    name: '海景房',
    category: 'ocean_view',
    floor_range: '6-10层',
    area: 16,
    has_balcony: false,
    has_window: true,
    max_occupancy: 3,
    description: '超大观海窗户',
    image_urls: ['https://images.unsplash.com/photo-1590490360182-c33d57733427?w=600&h=400&fit=crop'],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    name: '内舱房',
    category: 'interior',
    floor_range: '3-10层',
    area: 14,
    has_balcony: false,
    has_window: false,
    max_occupancy: 2,
    description: '性价比之选',
    image_urls: ['https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600&h=400&fit=crop'],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: spectrum.id,
    name: '套房',
    category: 'suite',
    floor_range: '11-14层',
    area: 35,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '尊享VIP权益',
    image_urls: [
      'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=600&h=400&fit=crop',
      'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=600&h=400&fit=crop'
    ],
    created_at: Time.current,
    updated_at: Time.current
  },
  # 地中海辉煌号 - 舱房类型
  {
    cruise_ship_id: bellissima.id,
    name: '阳台房',
    category: 'balcony',
    floor_range: '7-11层',
    area: 20,
    has_balcony: true,
    has_window: true,
    max_occupancy: 4,
    description: '地中海风格装饰，享受海风拂面',
    image_urls: ['https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=600&h=400&fit=crop'],
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_ship_id: bellissima.id,
    name: '内舱房',
    category: 'interior',
    floor_range: '4-9层',
    area: 15,
    has_balcony: false,
    has_window: false,
    max_occupancy: 2,
    description: '经济实惠之选',
    image_urls: ['https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600&h=400&fit=crop'],
    created_at: Time.current,
    updated_at: Time.current
  }
]

CabinType.insert_all(cabin_types_data)
puts "    ✓ 已加载 #{cabin_types_data.size} 种舱房类型"

# ==================== 商家数据 ====================
puts "  → 正在加载商家数据..."

travel_agencies_data = [
  {
    name: '皇家加勒比国际游轮旗舰店',
    rating: 4.9,
    is_verified: true,
    description: '皇家加勒比国际游轮官方旗舰店',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    name: 'msc邮轮旗舰店',
    rating: 4.8,
    is_verified: true,
    description: '地中海邮轮官方旗舰店',
    created_at: Time.current,
    updated_at: Time.current
  }
]

TravelAgency.insert_all(travel_agencies_data)
puts "    ✓ 已加载 #{travel_agencies_data.size} 家商家"

# ==================== 商家产品数据 ====================
puts "  → 正在加载商家产品数据..."

# 获取班次ID
sailing_1 = CruiseSailing.find_by(departure_date: Date.parse('2026-01-23'))
sailing_2 = CruiseSailing.find_by(departure_date: Date.parse('2026-01-28'))
sailing_3 = CruiseSailing.find_by(departure_date: Date.parse('2026-02-10'))

cruise_products_data = [
  {
    cruise_sailing_id: sailing_3.id,
    merchant_name: 'msc邮轮旗舰店',
    price_per_person: 1999.5,
    occupancy_requirement: 2,
    stock: 100,
    sales_count: 3000,
    is_refundable: true,
    requires_confirmation: false,
    status: 'on_sale',
    badge: '春节提前订',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_sailing_id: sailing_1.id,
    merchant_name: '皇家加勒比国际游轮旗舰店',
    price_per_person: 1831,
    occupancy_requirement: 2,
    stock: 50,
    sales_count: 75,
    is_refundable: true,
    requires_confirmation: false,
    status: 'on_sale',
    badge: '品牌官方',
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    cruise_sailing_id: sailing_2.id,
    merchant_name: 'msc邮轮旗舰店',
    price_per_person: 1419.5,
    occupancy_requirement: 2,
    stock: 80,
    sales_count: 3000,
    is_refundable: true,
    requires_confirmation: false,
    status: 'on_sale',
    badge: '品牌官方',
    created_at: Time.current,
    updated_at: Time.current
  }
]

CruiseProduct.insert_all(cruise_products_data)
puts "    ✓ 已加载 #{cruise_products_data.size} 个商家产品"

puts "✓ cruises_v1 数据包加载完成"
