# frozen_string_literal: true

require_relative '../../../../../app/helpers/image_seed_helper'

# specialized_tours_v1 数据包
# 为V327-V350验证器提供专项游数据
#
# 用途：
# - 花期限定游、观鸟游、采摘游、登山游等专项旅游产品
# - 区域特色游（西藏、新疆、云南、内蒙古、海南等）
# - 主题定制游（企业包机、私人游艇、名人路线等）
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 specialized_tours_v1 数据包..."

timestamp = Time.current

# ==================== 确保城市数据存在 ====================
cities_to_create = ["伊犁", "九江", "哈尔滨", "婺源", "罗平", "丽江", "拉萨", "乌鲁木齐", "呼和浩特", "桂林", "贵阳"]

cities_data = cities_to_create.map do |city_name|
  next if City.exists?(name: city_name, data_version: 0)
  region = case city_name
           when "伊犁" then "新疆"
           when "九江" then "江西"
           when "哈尔滨" then "黑龙江"
           when "婺源" then "江西"
           when "罗平" then "云南"
           when "丽江" then "云南"
           when "拉萨" then "西藏"
           when "乌鲁木齐" then "新疆"
           when "呼和浩特" then "内蒙古"
           when "桂林" then "广西"
           when "贵阳" then "贵州"
           else "未知"
           end
  {
    name: city_name,
    region: region,
    pinyin: city_name.downcase,
    airport_code: "",
    is_hot: false,
    themes: [],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end.compact

City.insert_all(cities_data) if cities_data.any?

# ==================== 旅行社数据（扩展）====================
additional_agencies_data = [
  {
    name: "江西鄱阳湖生态旅行社",
    description: "专注鄱阳湖候鸟观测、湿地生态游，提供专业观鸟设备和生态讲解服务。",
    logo_url: nil,
    rating: 4.7,
    sales_count: 680,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "内蒙古草原风情旅行社",
    description: "内蒙古本地旅行社，专注草原深度游、蒙古族文化体验、骑马、射箭等活动。",
    logo_url: nil,
    rating: 4.8,
    sales_count: 1280,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "西藏圣地之旅",
    description: "西藏本地旅行社，专注高原旅游、布达拉宫、纳木错、珠峰等线路，提供高原医疗保障。",
    logo_url: nil,
    rating: 4.9,
    sales_count: 1580,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "新疆丝路探险旅行社",
    description: "新疆本地旅行社，专注沙漠探险、戈壁徒步、天山探险等极限旅游线路。",
    logo_url: nil,
    rating: 4.7,
    sales_count: 980,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "云南多彩民族旅行社",
    description: "云南本地旅行社，专注少数民族文化游、彝族、白族、纳西族等民俗体验。",
    logo_url: nil,
    rating: 4.6,
    sales_count: 1120,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "桂林山水国际旅行社",
    description: "桂林本地旅行社，专注漓江游船、阳朔山水、龙脊梯田等经典线路。",
    logo_url: nil,
    rating: 4.7,
    sales_count: 2380,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "贵州溶洞探秘旅行社",
    description: "贵州本地旅行社，专注溶洞探险、黄果树瀑布、织金洞等喀斯特地貌游。",
    logo_url: nil,
    rating: 4.5,
    sales_count: 780,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

# 检查并插入新旅行社
additional_agencies_data.each do |agency_data|
  unless TravelAgency.exists?(name: agency_data[:name], data_version: 0)
    TravelAgency.insert(agency_data)
  end
end

puts "    ✓ 旅行社数据已更新"

# ==================== 景点数据 ====================
attractions_data = []

# V327: 伊犁薰衣草园
if !Attraction.exists?(name: "普罗旺斯风格薰衣草园", city: "伊犁", data_version: 0)
  attractions_data << {
    name: "普罗旺斯风格薰衣草园",
    slug: "yili-lavender-garden",
    city: "伊犁",
    district: "霍城县",
    address: "伊犁哈萨克自治州霍城县",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 44.049,
    longitude: 80.871,
    description: "中国薰衣草之乡，6月薰衣草盛开时节，紫色花海绵延数十公里，宛如普罗旺斯再现。",
    opening_hours: "09:00-19:00（6-8月花期）",
    phone: "0999-8765432",
    rating: 4.8,
    review_count: 2580,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# V328: 鄱阳湖候鸟观测基地
if !Attraction.exists?(name: "鄱阳湖候鸟观测基地", city: "九江", data_version: 0)
  attractions_data << {
    name: "鄱阳湖候鸟观测基地",
    slug: "poyang-lake-bird-watching",
    city: "九江",
    district: "都昌县",
    address: "九江市都昌县鄱阳湖国家湿地公园",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 29.282,
    longitude: 116.204,
    description: "中国最大的候鸟越冬栖息地，每年11月至次年3月有数十万只候鸟迁徙至此，包括珍稀的白鹤、东方白鹳等。",
    opening_hours: "06:30-18:00",
    phone: "0792-8888888",
    rating: 4.7,
    review_count: 1280,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Attraction.insert_all(attractions_data) if attractions_data.any?
puts "    ✓ 创建了 #{attractions_data.size} 个专项景点"

# ==================== 旅游团产品数据 ====================
tour_products_data = []

# V327: 薰衣草花期限定观光游
unless TourGroupProduct.exists?(title: "薰衣草花期限定观光游", destination: "普罗旺斯风格薰衣草园", data_version: 0)
  # 获取或创建新疆旅行社
  xinjiang_agency = TravelAgency.find_by(name: "新疆丝路探险旅行社", data_version: 0) || TravelAgency.first
  
  tour_products_data << {
    title: "薰衣草花期限定观光游",
    travel_agency_id: xinjiang_agency.id,
    destination: "普罗旺斯风格薰衣草园",
    description: "6月薰衣草盛开季节限定，深度游览伊犁薰衣草庄园，含摄影指导、薰衣草精油制作体验。",
    duration: "2天1晚",
    tour_category: "花期限定",
    tags: "花期限定,薰衣草,摄影",
    price: 1280.0,
    cost_includes: "交通、住宿、门票、导游、薰衣草体验活动",
    cost_excludes: "餐费、个人消费",
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# V328: 鄱阳湖候鸟迁徙观测游
unless TourGroupProduct.exists?(title: "鄱阳湖候鸟迁徙观测游", destination: "鄱阳湖候鸟观测基地", data_version: 0)
  # 获取或创建江西旅行社
  jiangxi_agency = TravelAgency.find_by(name: "江西鄱阳湖生态旅行社", data_version: 0) || TravelAgency.first
  
  tour_products_data << {
    title: "鄱阳湖候鸟迁徙观测游",
    travel_agency_id: jiangxi_agency.id,
    destination: "鄱阳湖候鸟观测基地",
    description: "3月候鸟迁徙季节，专业生态导游带领，提供高倍望远镜，观测白鹤、东方白鹳等珍稀候鸟。",
    duration: "1天",
    tour_category: "生态观鸟",
    tags: "观鸟,候鸟,生态游",
    price: 580.0,
    cost_includes: "交通、门票、导游、观鸟设备",
    cost_excludes: "餐费、住宿、个人消费",
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

TourGroupProduct.insert_all(tour_products_data) if tour_products_data.any?
puts "    ✓ 创建了 #{tour_products_data.size} 个旅游团产品"

# ==================== 高端服务数据 ====================
# V345: 企业包机航班
unless Flight.exists?(flight_number: "CZ9001", departure_city: "北京", destination_city: "三亚", data_version: 0)
  charter_date = Date.today + 5.days
  Flight.insert({
    departure_city: "北京",
    destination_city: "三亚",
    departure_time: charter_date.to_time.in_time_zone.change(hour: 9, min: 0),
    arrival_time: charter_date.to_time.in_time_zone.change(hour: 13, min: 0),
    departure_airport: "北京首都国际机场",
    arrival_airport: "三亚凤凰国际机场",
    airline: "南方航空",
    flight_number: "CZ9001",
    aircraft_type: "波音737(包机)",
    price: 50000.0,  # 包机价格
    discount_price: 0.0,
    seat_class: "包机",
    available_seats: 50,
    flight_date: charter_date,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  })
  puts "    ✓ 创建了企业包机航班"
end

# V345: 三亚五星酒店
unless Hotel.exists?(name: "三亚海棠湾万达瑞华酒店", city: "三亚", data_version: 0)
  hotel = Hotel.create!({
    name: "三亚海棠湾万达瑞华酒店",
    brand: "万达瑞华",
    city: "三亚",
    address: "三亚市海棠区海棠北路88号",
    rating: 4.9,
    price: 2880,
    original_price: 3800,
    distance: "1.5km",
    features: ["管家服务", "私人泳池", "米其林餐厅", "水疗中心", "商务中心"],
    star_level: 5,
    is_featured: true,
    display_order: 1,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '国内',
    image_url: ImageSeedHelper.random_image_from_category(:hotels),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  })
  
  # 行政套房
  HotelRoom.create!({
    hotel_id: hotel.id,
    room_type: "行政套房",
    price: 2880,
    original_price: 3800,
    bed_type: "特大床+客厅",
    max_guests: 3,
    area: 88,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  })
  
  puts "    ✓ 创建了五星级酒店及行政套房"
end

# V345: 豪华车队 (暂时禁用 - Car模型字段问题)
# unless Car.exists?(brand: "奔驰", car_model: "S级轿车车队", data_version: 0)
#   Car.create!({
#     brand: "奔驰",
#     car_model: "S级轿车车队",
#     category: "luxury",
#     seats: 4,
#     doors: 4,
#     transmission: "自动",
#     fuel_type: "汽油",
#     engine: "3.0T V6",
#     price_per_day: 2800.0,
#     total_price: 3500.0,
#     discount_amount: 700.0,
#     location: "三亚市",
#     pickup_location: "三亚凤凰机场",
#     features: ["真皮座椅", "按摩座椅", "智能驾驶", "车载WiFi", "豪华音响"],
#     tags: ["豪华型", "商务接待", "机场接送"],
#     is_featured: true,
#     is_available: true,
#     sales_rank: 1,
#     image_url: ImageSeedHelper.random_image_from_category(:cars),
#     data_version: 0,
#     created_at: timestamp,
#     updated_at: timestamp
#   })
#   puts "    ✓ 创建了豪华车队"
# end
puts "    ⚠️  跳过豪华车队创建（Car模型字段问题）"

# V346: 私人游艇服务（暂时禁用 - Cruise模型字段问题）
# unless CruiseLine.exists?(name: "海上奢华游艇服务", data_version: 0)
#   cruise_line = CruiseLine.create!({
#     name: "海上奢华游艇服务",
#     name_en: "Luxury Yacht Services",
#     description: "提供私人游艇租赁服务，含专业船长、厨师、服务人员",
#     logo_url: ImageSeedHelper.random_image_from_category(:cruise_logos),
#     data_version: 0,
#     created_at: timestamp,
#     updated_at: timestamp
#   })
#   
#   cruise_ship = CruiseShip.create!({
#     name: "海洋之星私人游艇",
#     name_en: "Ocean Star Private Yacht",
#     cruise_line_id: cruise_line.id,
#     image_url: ImageSeedHelper.random_image_from_category(:cruise_ships),
#     features: ["50英尺豪华私人游艇", "可容纳8人", "配备专业船长和服务人员"],
#     tonnage: 50,
#     passenger_capacity: 8,
#     data_version: 0,
#     created_at: timestamp,
#     updated_at: timestamp
#   })
#   
#   # 创建航线
#   cruise_route = CruiseRoute.create!({
#     name: "三亚蜈支洲岛游舮航线",
#     region: 'southeast_asia',
#     icon_url: ImageSeedHelper.random_image_from_category(:cruise_destinations),
#     data_version: 0,
#     created_at: timestamp,
#     updated_at: timestamp
#   })
#   
#   # 创建未来10天的航次
#   sailing_date = Date.today + 10.days
#   CruiseSailing.create!({
#     cruise_ship_id: cruise_ship.id,
#     cruise_route_id: cruise_route.id,
#     departure_port: "三亚凤凰岛游艇码头",
#     arrival_port: "蜈支洲岛",
#     departure_date: sailing_date,
#     return_date: sailing_date,
#     duration_days: 1,
#     duration_nights: 1,
#     data_version: 0,
#     created_at: timestamp,
#     updated_at: timestamp
#   })
#   
#   puts "    ✓ 创建了私人游艇服务"
# end
puts "    ⚠️  跳过私人游艇服务创建（Cruise模型字段问题）"

# V346: 海岛度假村
unless Hotel.exists?(name: "三亚亚特兰蒂斯海岛度假村", city: "三亚", data_version: 0)
  hotel = Hotel.create!({
    name: "三亚亚特兰蒂斯海岛度假村",
    brand: "亚特兰蒂斯",
    city: "三亚",
    address: "三亚市海棠湾海棠北路36号",
    rating: 4.9,
    price: 3580,
    original_price: 4800,
    distance: "0km",
    features: ["私人海滩", "水族馆", "水上乐园", "管家服务", "米其林餐厅"],
    star_level: 5,
    is_featured: true,
    display_order: 1,
    hotel_type: 'hotel',  # 酒店类型（原度假村）
    is_domestic: true,
    region: '国内',
    image_url: ImageSeedHelper.random_image_from_category(:hotels),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  })
  
  # 海景别墅套房
  HotelRoom.create!({
    hotel_id: hotel.id,
    room_type: "海景别墅套房",
    price: 3580,
    original_price: 4800,
    bed_type: "特大床+客厅+卧室",
    max_guests: 4,
    area: 120,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  })
  
  puts "    ✓ 创建了海岛度假村及别墅套房"
end

puts "✓ specialized_tours_v1 数据包加载完成"
