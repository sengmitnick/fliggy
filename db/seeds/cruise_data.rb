# 游轮游种子数据
puts "🚢 开始创建游轮游数据..."

# 1. 创建游轮公司（品牌）
puts "  创建游轮公司..."

royal_caribbean = CruiseLine.find_or_create_by!(name: '皇家加勒比国际游轮') do |line|
  line.name_en = 'Royal Caribbean International'
  line.logo_url = 'https://images.unsplash.com/photo-1548574505-5e239809ee19?w=200&h=200&fit=crop'
  line.description = '全球豪华游轮领导品牌，拥有超量子系列、绿洲系列等多个创新船队'
end

msc_cruises = CruiseLine.find_or_create_by!(name: '地中海邮轮') do |line|
  line.name_en = 'MSC Cruises'
  line.logo_url = 'https://images.unsplash.com/photo-1563298723-dcfebaa392e3?w=200&h=200&fit=crop'
  line.description = '欧洲第一、世界第四大邮轮公司，提供地中海特色服务'
end

costa_cruises = CruiseLine.find_or_create_by!(name: '爱达邮轮') do |line|
  line.name_en = 'AIDA Cruises'
  line.logo_url = 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=200&h=200&fit=crop'
  line.description = '德国邮轮品牌，以年轻时尚的邮轮体验著称'
end

# 2. 创建游轮船只
puts "  创建游轮船只..."

spectrum = CruiseShip.find_or_create_by!(name: '海洋光谱号') do |ship|
  ship.cruise_line = royal_caribbean
  ship.name_en = 'Spectrum of the Seas'
  ship.image_url = 'https://images.unsplash.com/photo-1568481572796-cac3501604fc?w=800&h=600&fit=crop'
  ship.features = ['超量子系列首艘邮轮', '甲板跳伞', '正宗川菜料理', '春房专享皇家府邸']
end

bellissima = CruiseShip.find_or_create_by!(name: '地中海辉煌号') do |ship|
  ship.cruise_line = msc_cruises
  ship.name_en = 'MSC Bellissima'
  ship.image_url = 'https://images.unsplash.com/photo-1599640842225-85d111c60e6b?w=800&h=600&fit=crop'
  ship.features = ['米其林星级餐厅', '豪华购物长廊', '海上水上乐园']
end

aida_nova = CruiseShip.find_or_create_by!(name: '爱达新星号') do |ship|
  ship.cruise_line = costa_cruises
  ship.name_en = 'AIDA Nova'
  ship.image_url = 'https://images.unsplash.com/photo-1605408499391-6368c628ef42?w=800&h=600&fit=crop'
  ship.features = ['环保LNG动力', '全景观景台', '海上啤酒花园']
end

# 3. 创建航线
puts "  创建航线..."

routes_data = [
  { name: '日韩', region: 'japan_korea', icon_url: 'tourism/邮轮游.png' },
  { name: '三峡', region: 'yangtze_river', icon_url: 'tourism/邮轮游.png' },
  { name: '南北极', region: 'north_pole', icon_url: 'tourism/邮轮游.png' },
  { name: '东南亚', region: 'southeast_asia', icon_url: 'tourism/邮轮游.png' },
  { name: '地中海', region: 'mediterranean', icon_url: 'tourism/邮轮游.png' },
  { name: '阿拉斯加', region: 'alaska', icon_url: 'tourism/邮轮游.png' },
  { name: '欧洲河轮', region: 'europe_river', icon_url: 'tourism/邮轮游.png' },
  { name: '加勒比', region: 'caribbean', icon_url: 'tourism/邮轮游.png' },
  { name: '中东', region: 'middle_east', icon_url: 'tourism/邮轮游.png' },
  { name: '西沙群岛', region: 'xisha_islands', icon_url: 'tourism/邮轮游.png' }
]

routes = routes_data.map do |data|
  CruiseRoute.find_or_create_by!(name: data[:name]) do |route|
    route.region = data[:region]
    route.icon_url = data[:icon_url]
  end
end

japan_korea_route = routes.find { |r| r.region == 'japan_korea' }
mediterranean_route = routes.find { |r| r.region == 'mediterranean' }
southeast_asia_route = routes.find { |r| r.region == 'southeast_asia' }

# 4. 创建班次（Sailing）
puts "  创建游轮班次..."

# 日韩航线 - 海洋光谱号 (1月23日出发)
sailing_1 = CruiseSailing.find_or_create_by!(
  cruise_ship: spectrum,
  cruise_route: japan_korea_route,
  departure_date: Date.parse('2026-01-23')
) do |sailing|
  sailing.return_date = Date.parse('2026-01-28')
  sailing.duration_days = 6
  sailing.duration_nights = 5
  sailing.departure_port = '香港登船'
  sailing.arrival_port = '上海离船'
  sailing.status = 'on_sale'
  sailing.itinerary = [
    { day: 1, port: '香港', description: '下午登船，晚上启航' },
    { day: 2, port: '海上巡航', description: '享受船上设施' },
    { day: 3, port: '冲绳', description: '自由活动，探索琉球文化' },
    { day: 4, port: '福冈', description: '品尝地道日本料理' },
    { day: 5, port: '海上巡航', description: '甲板活动' },
    { day: 6, port: '上海', description: '早晨抵达，离船' }
  ]
end

# 日韩航线 - 海洋光谱号 (1月28日出发)
sailing_2 = CruiseSailing.find_or_create_by!(
  cruise_ship: spectrum,
  cruise_route: japan_korea_route,
  departure_date: Date.parse('2026-01-28')
) do |sailing|
  sailing.return_date = Date.parse('2026-02-01')
  sailing.duration_days = 5
  sailing.duration_nights = 4
  sailing.departure_port = '上海登船'
  sailing.arrival_port = '上海离船'
  sailing.status = 'on_sale'
  sailing.itinerary = [
    { day: 1, port: '上海', description: '下午登船，晚上启航' },
    { day: 2, port: '济州岛', description: '探索韩国文化' },
    { day: 3, port: '釜山', description: '海云台海滩' },
    { day: 4, port: '海上巡航', description: '船上娱乐' },
    { day: 5, port: '上海', description: '早晨抵达' }
  ]
end

# 地中海航线 - 地中海辉煌号
sailing_3 = CruiseSailing.find_or_create_by!(
  cruise_ship: bellissima,
  cruise_route: mediterranean_route,
  departure_date: Date.parse('2026-02-10')
) do |sailing|
  sailing.return_date = Date.parse('2026-02-17')
  sailing.duration_days = 8
  sailing.duration_nights = 7
  sailing.departure_port = '上海登船'
  sailing.arrival_port = '上海离船'
  sailing.status = 'on_sale'
  sailing.itinerary = [
    { day: 1, port: '上海', description: '下午登船' },
    { day: 2, port: '长崎', description: '日本历史名城' },
    { day: 3, port: '福冈', description: '购物天堂' },
    { day: 4, port: '海上巡航', description: '享受船上设施' },
    { day: 5, port: '冲绳', description: '热带风情' },
    { day: 6, port: '海上巡航', description: '甲板活动' },
    { day: 7, port: '海上巡航', description: '晚宴之夜' },
    { day: 8, port: '上海', description: '早晨抵达' }
  ]
end

# 5. 创建舱房类型
puts "  创建舱房类型..."

# 海洋光谱号 - 舱房类型
balcony_cabin = CabinType.find_or_create_by!(
  cruise_ship: spectrum,
  name: '部分遮挡超值家庭阳台房'
) do |cabin|
  cabin.category = 'balcony'
  cabin.floor_range = '6,8-13层'
  cabin.area = 18
  cabin.has_balcony = true
  cabin.has_window = true
  cabin.max_occupancy = 4
  cabin.description = '在舒适的阳台上聆听大海的声音，放松身心，畅享超值的海上假期。'
  cabin.image_urls = [
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=600&h=400&fit=crop',
    'https://images.unsplash.com/photo-1582719478250-c89cae4dc85b?w=600&h=400&fit=crop'
  ]
end

single_balcony = CabinType.find_or_create_by!(
  cruise_ship: spectrum,
  name: '单人尊享阳台房'
) do |cabin|
  cabin.category = 'balcony'
  cabin.floor_range = '6-7层'
  cabin.area = 11
  cabin.has_balcony = true
  cabin.has_window = true
  cabin.max_occupancy = 1
  cabin.description = '推门可见的迷人海景，让您在充分享受私人空间的同时体验一段难忘的海上假期。'
  cabin.image_urls = [
    'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=600&h=400&fit=crop'
  ]
end

ocean_view_cabin = CabinType.find_or_create_by!(
  cruise_ship: spectrum,
  name: '海景房'
) do |cabin|
  cabin.category = 'ocean_view'
  cabin.floor_range = '超大观海窗户'
  cabin.area = 16
  cabin.has_balcony = false
  cabin.has_window = true
  cabin.max_occupancy = 3
  cabin.description = '超大观海窗户，性价比之选'
  cabin.image_urls = [
    'https://images.unsplash.com/photo-1590490360182-c33d57733427?w=600&h=400&fit=crop'
  ]
end

interior_cabin = CabinType.find_or_create_by!(
  cruise_ship: spectrum,
  name: '内舱房'
) do |cabin|
  cabin.category = 'interior'
  cabin.floor_range = '性价比之选'
  cabin.area = 14
  cabin.has_balcony = false
  cabin.has_window = false
  cabin.max_occupancy = 2
  cabin.description = '性价比之选，享受船上设施'
  cabin.image_urls = [
    'https://images.unsplash.com/photo-1611892440504-42a792e24d32?w=600&h=400&fit=crop'
  ]
end

suite_cabin = CabinType.find_or_create_by!(
  cruise_ship: spectrum,
  name: '套房'
) do |cabin|
  cabin.category = 'suite'
  cabin.floor_range = '尊享VIP权益'
  cabin.area = 35
  cabin.has_balcony = true
  cabin.has_window = true
  cabin.max_occupancy = 4
  cabin.description = '尊享VIP权益，包含专属管家服务'
  cabin.image_urls = [
    'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=600&h=400&fit=crop',
    'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=600&h=400&fit=crop'
  ]
end

# 地中海辉煌号 - 舱房类型
msc_balcony = CabinType.find_or_create_by!(
  cruise_ship: bellissima,
  name: '阳台房'
) do |cabin|
  cabin.category = 'balcony'
  cabin.floor_range = '7-11层'
  cabin.area = 20
  cabin.has_balcony = true
  cabin.has_window = true
  cabin.max_occupancy = 4
  cabin.description = '地中海风格装饰，享受海风拂面'
  cabin.image_urls = [
    'https://images.unsplash.com/photo-1584132967334-10e028bd69f7?w=600&h=400&fit=crop'
  ]
end

# 6. 创建商家产品
puts "  创建商家产品..."

# Sailing 1 - 海洋光谱号 (01月23日) - 阳台房
CruiseProduct.find_or_create_by!(
  cruise_sailing: sailing_1,
  cabin_type: balcony_cabin,
  merchant_name: '渝之旅旅游旗舰店'
) do |product|
  product.price_per_person = 3560
  product.occupancy_requirement = 3
  product.stock = 10
  product.sales_count = 1151
  product.is_refundable = false
  product.requires_confirmation = true
  product.status = 'on_sale'
  product.badge = '近期热销'
end

CruiseProduct.find_or_create_by!(
  cruise_sailing: sailing_1,
  cabin_type: balcony_cabin,
  merchant_name: '杭州乐满程旅游专卖'
) do |product|
  product.price_per_person = 3418
  product.occupancy_requirement = 3
  product.stock = 8
  product.sales_count = 939
  product.is_refundable = false
  product.requires_confirmation = true
  product.status = 'on_sale'
  product.badge = '低价之选'
end

# Sailing 1 - 阳台房 (4人间)
CruiseProduct.find_or_create_by!(
  cruise_sailing: sailing_1,
  cabin_type: balcony_cabin,
  merchant_name: '渝之旅旅游旗舰店'
) do |product|
  product.price_per_person = 2425
  product.occupancy_requirement = 4
  product.stock = 5
  product.sales_count = 456
  product.is_refundable = false
  product.requires_confirmation = true
  product.status = 'on_sale'
end

# Sailing 1 - 单人阳台房
CruiseProduct.find_or_create_by!(
  cruise_sailing: sailing_1,
  cabin_type: single_balcony,
  merchant_name: '皇家加勒比官方旗舰店'
) do |product|
  product.price_per_person = 5985
  product.occupancy_requirement = 1
  product.stock = 3
  product.sales_count = 89
  product.is_refundable = true
  product.requires_confirmation = false
  product.status = 'on_sale'
end

# Sailing 1 - 海景房
CruiseProduct.find_or_create_by!(
  cruise_sailing: sailing_1,
  cabin_type: ocean_view_cabin,
  merchant_name: '杭州乐满程旅游专卖'
) do |product|
  product.price_per_person = 2980
  product.occupancy_requirement = 2
  product.stock = 12
  product.sales_count = 678
  product.is_refundable = false
  product.requires_confirmation = true
  product.status = 'on_sale'
  product.badge = '低价之选'
end

# Sailing 1 - 内舱房
CruiseProduct.find_or_create_by!(
  cruise_sailing: sailing_1,
  cabin_type: interior_cabin,
  merchant_name: '携程旅游旗舰店'
) do |product|
  product.price_per_person = 1999
  product.occupancy_requirement = 2
  product.stock = 20
  product.sales_count = 1234
  product.is_refundable = false
  product.requires_confirmation = true
  product.status = 'on_sale'
  product.badge = '近期热销'
end

# Sailing 1 - 套房
CruiseProduct.find_or_create_by!(
  cruise_sailing: sailing_1,
  cabin_type: suite_cabin,
  merchant_name: '皇家加勒比官方旗舰店'
) do |product|
  product.price_per_person = 8888
  product.occupancy_requirement = 2
  product.stock = 2
  product.sales_count = 45
  product.is_refundable = true
  product.requires_confirmation = false
  product.status = 'on_sale'
end

# Sailing 2 - 海洋光谱号 (01月28日) 韩国航线
CruiseProduct.find_or_create_by!(
  cruise_sailing: sailing_2,
  cabin_type: balcony_cabin,
  merchant_name: '渝之旅旅游旗舰店'
) do |product|
  product.price_per_person = 2999
  product.occupancy_requirement = 3
  product.stock = 15
  product.sales_count = 567
  product.is_refundable = false
  product.requires_confirmation = true
  product.status = 'on_sale'
end

# Sailing 3 - 地中海辉煌号
CruiseProduct.find_or_create_by!(
  cruise_sailing: sailing_3,
  cabin_type: msc_balcony,
  merchant_name: 'msc邮轮旗舰店'
) do |product|
  product.price_per_person = 1999
  product.occupancy_requirement = 2
  product.stock = 25
  product.sales_count = 3000
  product.is_refundable = true
  product.requires_confirmation = false
  product.status = 'on_sale'
  product.badge = '近期热销'
end

puts "✅ 游轮游数据创建完成！"
puts "  - #{CruiseLine.count} 个游轮公司"
puts "  - #{CruiseShip.count} 艘游轮船只"
puts "  - #{CruiseRoute.count} 条航线"
puts "  - #{CruiseSailing.count} 个班次"
puts "  - #{CabinType.count} 种舱房类型"
puts "  - #{CruiseProduct.count} 个商家产品"
