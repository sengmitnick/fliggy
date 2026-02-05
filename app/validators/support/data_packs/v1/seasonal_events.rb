# frozen_string_literal: true

require_relative '../../../../../app/helpers/image_seed_helper'

# seasonal_events_v1 数据包
# 包含节假日高峰期场景所需的数据
#
# 用途：
# - V317-V355 验证器所需的节假日/季节性数据
# - 包含春节、国庆、暑期、寒假等高峰期的火车票、景点、酒店、航班等
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 seasonal_events_v1 数据包..."

timestamp = Time.current

# ==================== 城市数据确保存在 ====================
# 确保基础城市数据已存在
cities_data = ["张家界", "崇礼", "张家口", "三亚"].map do |city_name|
  next if City.exists?(name: city_name, data_version: 0)
  {
    name: city_name,
    region: case city_name
            when "张家界" then "湖南"
            when "崇礼", "张家口" then "河北"
            when "三亚" then "海南"
            else "未知"
            end,
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

# ==================== 目的地数据 ====================
destinations_data = []

# 崇礼滑雪目的地
unless Destination.exists?(name: "崇礼", data_version: 0)
  destinations_data << {
    name: "崇礼",
    region: "河北",
    is_hot: false,
    description: "冬奥会举办地，中国顶级滑雪度假胜地",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Destination.insert_all(destinations_data) if destinations_data.any?

# ==================== 火车票数据（春节返乡） ====================
puts "  创建春节返乡火车票数据..."

# 为未来60-70天生成北京→成都春运火车票（支持v317）
start_date = Date.today + 60.days
end_date = start_date + 10.days

trains_data = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.today).to_i
  
  # Z50: 北京西→成都（直达特快，有卧铺）
  trains_data << {
    departure_city: "北京",
    arrival_city: "成都",
    departure_station: "北京西站",
    arrival_station: "成都站",
    departure_time: base_datetime.change(hour: 19, min: 58),
    arrival_time: (base_datetime + 1.day).change(hour: 9, min: 20),
    train_number: "Z50",
    duration: 803,  # 13小时22分
    price_second_class: 263.5,
    price_first_class: 447.5,
    price_business_class: 0.0,  # 直达特快没有商务座
    available_seats: 200,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Train.insert_all(trains_data)
puts "    ✓ 创建了 #{trains_data.size} 条春运火车票"

# ==================== 景点数据 ====================
puts "  创建节假日景点数据..."

attractions_data = []

# 张家界国家森林公园（支持v318）
if !Attraction.exists?(name: "张家界国家森林公园", city: "张家界", data_version: 0)
  attractions_data << {
    name: "张家界国家森林公园",
    slug: "zhangjiajie-national-forest-park",
    city: "张家界",
    district: "武陵源区",
    address: "张家界市武陵源区",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 29.325,
    longitude: 110.479,
    description: "中国第一个国家森林公园，世界自然遗产，拥有独特的石英砂岩峰林地貌。电影《阿凡达》取景地，以其奇峰异石、云海缭绕而闻名。",
    opening_hours: "07:00-18:00",
    phone: "0744-5712189",
    rating: 4.7,
    review_count: 8520,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 三亚亚龙湾热带天堂森林公园（支持v319）
if !Attraction.exists?(name: "三亚亚龙湾热带天堂森林公园", city: "三亚", data_version: 0)
  attractions_data << {
    name: "三亚亚龙湾热带天堂森林公园",
    slug: "sanya-yalong-bay-tropical-paradise-forest-park",
    city: "三亚",
    district: "吉阳区",
    address: "三亚市吉阳区亚龙湾路",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 18.245,
    longitude: 109.614,
    description: "集热带雨林、滨海风光于一体的森林公园。拥有著名的玻璃栈道、过江龙索桥等景点，可俯瞰亚龙湾全景。电影《非诚勿扰2》取景地。",
    opening_hours: "07:30-17:30",
    phone: "0898-38889898",
    rating: 4.6,
    review_count: 6820,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 崇礼万龙滑雪场（支持v320）
if !Attraction.exists?(name: "崇礼万龙滑雪场", city: "张家口", data_version: 0)
  attractions_data << {
    name: "崇礼万龙滑雪场",
    slug: "chongli-wanlong-ski-resort",
    city: "张家口",
    district: "崇礼区",
    address: "张家口市崇礼区红花梁",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 40.971,
    longitude: 115.348,
    description: "中国首家开放式滑雪场，北京冬奥会赛事场地之一。拥有32条雪道，最高海拔2110米，雪质优良，是滑雪爱好者的天堂。",
    opening_hours: "08:30-16:30（雪季12月-次年3月）",
    phone: "0313-4785888",
    rating: 4.8,
    review_count: 3520,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Attraction.insert_all(attractions_data) if attractions_data.any?
puts "    ✓ 创建了 #{attractions_data.size} 个景点"

# ==================== 门票数据 ====================
puts "  创建门票数据..."

tickets_data = []

# 张家界国家森林公园门票
zjj_attraction = Attraction.find_by(name: "张家界国家森林公园", data_version: 0)
if zjj_attraction && !Ticket.exists?(attraction_id: zjj_attraction.id, ticket_type: "adult", data_version: 0)
  tickets_data << {
    attraction_id: zjj_attraction.id,
    ticket_type: "adult",
    name: "张家界国家森林公园成人票",
    price: 228.0,
    original_price: 248.0,
    description: "四日有效，含金鞭溪、袁家界、天子山、十里画廊等核心景区",
    image_url: ImageSeedHelper.random_image_from_category(:tickets),
    valid_days: 4,
    refund_policy: "未使用可随时退",
    booking_notice: "需提前1小时预订",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 三亚亚龙湾热带天堂森林公园门票
sy_attraction = Attraction.find_by(name: "三亚亚龙湾热带天堂森林公园", data_version: 0)
if sy_attraction && !Ticket.exists?(attraction_id: sy_attraction.id, ticket_type: "adult", data_version: 0)
  tickets_data << {
    attraction_id: sy_attraction.id,
    ticket_type: "adult",
    name: "亚龙湾热带天堂森林公园成人票",
    price: 150.0,
    original_price: 175.0,
    description: "含雨林栈道、过江龙索桥、玻璃栈道等",
    image_url: ImageSeedHelper.random_image_from_category(:tickets),
    valid_days: 1,
    refund_policy: "未使用可随时退",
    booking_notice: "需提前2小时预订",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 崇礼万龙滑雪场门票
cl_attraction = Attraction.find_by(name: "崇礼万龙滑雪场", data_version: 0)
if cl_attraction && !Ticket.exists?(attraction_id: cl_attraction.id, ticket_type: "adult", data_version: 0)
  tickets_data << {
    attraction_id: cl_attraction.id,
    ticket_type: "adult",
    name: "崇礼万龙滑雪场全天票",
    price: 380.0,
    original_price: 450.0,
    description: "全天不限时滑雪，含缆车费用（不含装备租赁）",
    image_url: ImageSeedHelper.random_image_from_category(:tickets),
    valid_days: 1,
    refund_policy: "使用日期前1天18:00前可退",
    booking_notice: "需提前1天预订",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Ticket.insert_all(tickets_data) if tickets_data.any?
puts "    ✓ 创建了 #{tickets_data.size} 张门票"

# ==================== 景点活动数据 ====================
puts "  创建景点活动数据..."

activities_data = []

# 三亚亚龙湾亲子雨林探险活动
if sy_attraction
  unless AttractionActivity.exists?(attraction_id: sy_attraction.id, name: "亲子雨林探险", data_version: 0)
    activities_data << {
      attraction_id: sy_attraction.id,
      name: "亲子雨林探险",
      description: "专为亲子家庭设计的雨林探险活动，含科普讲解、昆虫观察、植物认知等互动环节",
      activity_type: "experience",
      current_price: 180.0,
      original_price: 200.0,
      duration: "3小时",
      image_url: ImageSeedHelper.random_image_from_category(:activities),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

# 崇礼万龙滑雪装备租赁
if cl_attraction
  unless AttractionActivity.exists?(attraction_id: cl_attraction.id, name: "滑雪装备租赁（全套）", data_version: 0)
    activities_data << {
      attraction_id: cl_attraction.id,
      name: "滑雪装备租赁（全套）",
      description: "含滑雪板、雪杖、雪鞋、头盔、雪镜全套装备，专业教练指导",
      activity_type: "experience",
      current_price: 280.0,
      original_price: 320.0,
      duration: "全天",
      image_url: ImageSeedHelper.random_image_from_category(:activities),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

AttractionActivity.insert_all(activities_data) if activities_data.any?
puts "    ✓ 创建了 #{activities_data.size} 个景点活动"

# ==================== 酒店数据 ====================
puts "  创建节假日酒店数据..."

hotels_data = []

# 张家界武陵源度假酒店（支持v318）
city_zjj = City.find_by(name: "张家界", data_version: 0)
unless Hotel.exists?(name: "张家界武陵源度假酒店", city: "张家界", data_version: 0)
  hotels_data << {
    name: "张家界武陵源度假酒店",
    brand: "度假酒店",
    city: "张家界",
    city_id: city_zjj&.id,
    address: "张家界市武陵源区武陵大道",
    rating: 4.6,
    price: 480,
    original_price: 650,
    distance: "2.5km",
    features: ["免费WiFi", "免费停车", "餐厅", "健身房", "室内游泳池"],
    star_level: 4,
    is_featured: true,
    display_order: 1,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '国内',
    image_url: ImageSeedHelper.random_image_from_category(:hotels),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 三亚亚龙湾亲子度假酒店（支持v319）
city_sy = City.find_by(name: "三亚", data_version: 0)
unless Hotel.exists?(name: "三亚亚龙湾亲子度假酒店", city: "三亚", data_version: 0)
  hotels_data << {
    name: "三亚亚龙湾亲子度假酒店",
    brand: "度假酒店",
    city: "三亚",
    city_id: city_sy&.id,
    address: "三亚市吉阳区亚龙湾路",
    rating: 4.7,
    price: 880,
    original_price: 1200,
    distance: "0.5km",
    features: ["免费WiFi", "儿童乐园", "亲子游泳池", "儿童餐厅", "免费早餐"],
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
  }
end

# 崇礼万龙度假酒店（支持v320）
city_zjk = City.find_by(name: "张家口", data_version: 0)
unless Hotel.exists?(name: "崇礼万龙度假酒店", city: "张家口", data_version: 0)
  hotels_data << {
    name: "崇礼万龙度假酒店",
    brand: "度假酒店",
    city: "张家口",
    city_id: city_zjk&.id,
    address: "张家口市崇礼区红花梁万龙滑雪场内",
    rating: 4.8,
    price: 780,
    original_price: 980,
    distance: "0km",
    features: ["免费WiFi", "滑雪装备寄存", "滑雪学校", "温泉中心", "餐厅"],
    star_level: 4,
    is_featured: true,
    display_order: 1,
    hotel_type: 'hotel',
    is_domestic: true,
    region: '国内',
    image_url: ImageSeedHelper.random_image_from_category(:hotels),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Hotel.insert_all(hotels_data) if hotels_data.any?
puts "    ✓ 创建了 #{hotels_data.size} 家酒店"

# ==================== 酒店房型数据 ====================
puts "  创建酒店房型数据..."

hotel_rooms_data = []

# 张家界武陵源度假酒店房型
zjj_hotel = Hotel.find_by(name: "张家界武陵源度假酒店", data_version: 0)
if zjj_hotel && !HotelRoom.exists?(hotel_id: zjj_hotel.id, room_type: "豪华双床房", data_version: 0)
  hotel_rooms_data << {
    hotel_id: zjj_hotel.id,
    room_type: "豪华双床房",
    price: 480,
    original_price: 650,
    bed_type: "双床",
    max_guests: 3,
    area: 42,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 三亚亚龙湾亲子度假酒店房型
sy_hotel = Hotel.find_by(name: "三亚亚龙湾亲子度假酒店", data_version: 0)
if sy_hotel && !HotelRoom.exists?(hotel_id: sy_hotel.id, room_type: "亲子家庭房", data_version: 0)
  hotel_rooms_data << {
    hotel_id: sy_hotel.id,
    room_type: "亲子家庭房",
    price: 880,
    original_price: 1200,
    bed_type: "大床+儿童床",
    max_guests: 3,
    area: 55,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 崇礼万龙度假酒店房型
cl_hotel = Hotel.find_by(name: "崇礼万龙度假酒店", data_version: 0)
if cl_hotel && !HotelRoom.exists?(hotel_id: cl_hotel.id, room_type: "滑雪主题大床房", data_version: 0)
  hotel_rooms_data << {
    hotel_id: cl_hotel.id,
    room_type: "滑雪主题大床房",
    price: 780,
    original_price: 980,
    bed_type: "大床",
    max_guests: 2,
    area: 38,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

HotelRoom.insert_all(hotel_rooms_data) if hotel_rooms_data.any?
puts "    ✓ 创建了 #{hotel_rooms_data.size} 个房型"

# ==================== 航班数据（暑期高峰）====================
puts "  创建暑期高峰航班数据..."

# 为特定日期（7月15日和7月20日）创建北京↔三亚航班（支持v319）
current_year = Date.today.year
july_15 = Date.new(current_year, 7, 15)
july_20 = Date.new(current_year, 7, 20)

if july_15 < Date.today
  july_15 = Date.new(current_year + 1, 7, 15)
  july_20 = Date.new(current_year + 1, 7, 20)
end

flights_data = []

# 7月15日：北京→三亚 (去程)
base_datetime = july_15.to_time.in_time_zone
flights_data << {
  departure_city: "北京",
  destination_city: "三亚",
  departure_time: base_datetime.change(hour: 8, min: 0),
  arrival_time: base_datetime.change(hour: 12, min: 0),
  departure_airport: "首都T3",
  arrival_airport: "凤凰T2",
  airline: "中国国航",
  flight_number: "CA1357",
  aircraft_type: "波音737(中)",
  price: 1580.0,
  discount_price: 200.0,
  seat_class: "economy",
  available_seats: 150,
  flight_date: july_15,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 7月20日：三亚→北京 (返程)
base_datetime_return = july_20.to_time.in_time_zone
flights_data << {
  departure_city: "三亚",
  destination_city: "北京",
  departure_time: base_datetime_return.change(hour: 14, min: 0),
  arrival_time: base_datetime_return.change(hour: 18, min: 0),
  departure_airport: "凤凰T2",
  arrival_airport: "首都T3",
  airline: "中国国航",
  flight_number: "CA1358",
  aircraft_type: "波音737(中)",
  price: 1480.0,
  discount_price: 150.0,
  seat_class: "economy",
  available_seats: 140,
  flight_date: july_20,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

Flight.insert_all(flights_data)
puts "    ✓ 创建了 #{flights_data.size} 个暑期航班"

puts "✓ seasonal_events_v1 数据包加载完成"
