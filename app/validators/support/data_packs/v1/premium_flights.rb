# frozen_string_literal: true

# premium_flights_v1 数据包
# 商务舱和头等舱航班数据
#
# 用途：
# - 为v188-v200验证器提供高端舱位选择
# - 北京<->上海商务舱/头等舱航班（每天各2个）
# - 北京<->广州商务舱/头等舱航班（每天各2个）
# - 上海<->深圳商务舱/头等舱航班（每天各2个）
#
# 加载方式：
# rake validator:reset_baseline

require 'activerecord-import' unless defined?(ActiveRecord::Import)

puts "正在加载 premium_flights_v1 数据包..."

# 使用Date.today确保与验证器日期一致
start_date = Date.today
end_date = start_date + 15.days

puts "  商务舱/头等舱航班日期范围: #{start_date} 至 #{end_date} (共16天)"

all_flights = []
timestamp = Time.current

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - start_date).to_i
  
  # ==================== 北京 -> 上海商务舱/头等舱 ====================
  all_flights << {
    departure_city: "北京",
    destination_city: "上海",
    departure_time: base_datetime.change(hour: 8, min: 30),
    arrival_time: base_datetime.change(hour: 11, min: 0),
    departure_airport: "首都T3",
    arrival_airport: "虹桥T2",
    airline: "中国国航",
    flight_number: "CA#{1800 + day_suffix}",
    aircraft_type: "波音787(大)",
    price: 1580.0,
    discount_price: 0.0,
    seat_class: "business",
    available_seats: 20,
    flight_date: date,
    created_at: timestamp,
    updated_at: timestamp,
    data_version: '0'
  }
  
  all_flights << {
    departure_city: "北京",
    destination_city: "上海",
    departure_time: base_datetime.change(hour: 14, min: 0),
    arrival_time: base_datetime.change(hour: 16, min: 30),
    departure_airport: "大兴",
    arrival_airport: "浦东T2",
    airline: "东方航空",
    flight_number: "MU#{5200 + day_suffix}",
    aircraft_type: "空客350(大)",
    price: 1680.0,
    discount_price: 0.0,
    seat_class: "business",
    available_seats: 24,
    flight_date: date,
    created_at: timestamp,
    updated_at: timestamp,
    data_version: '0'
  }
  
  all_flights << {
    departure_city: "北京",
    destination_city: "上海",
    departure_time: base_datetime.change(hour: 10, min: 0),
    arrival_time: base_datetime.change(hour: 12, min: 30),
    departure_airport: "首都T3",
    arrival_airport: "虹桥T2",
    airline: "中国国航",
    flight_number: "CA#{1900 + day_suffix}",
    aircraft_type: "波音777(大)",
    price: 2580.0,
    discount_price: 0.0,
    seat_class: "first",
    available_seats: 8,
    flight_date: date,
    created_at: timestamp,
    updated_at: timestamp,
    data_version: '0'
  }
  
  # ==================== 上海 -> 北京商务舱/头等舱 ====================
  all_flights << {
    departure_city: "上海",
    destination_city: "北京",
    departure_time: base_datetime.change(hour: 9, min: 0),
    arrival_time: base_datetime.change(hour: 11, min: 30),
    departure_airport: "虹桥T2",
    arrival_airport: "首都T3",
    airline: "中国国航",
    flight_number: "CA#{1801 + day_suffix}",
    aircraft_type: "波音787(大)",
    price: 1580.0,
    discount_price: 0.0,
    seat_class: "business",
    available_seats: 20,
    flight_date: date,
    created_at: timestamp,
    updated_at: timestamp,
    data_version: '0'
  }
  
  all_flights << {
    departure_city: "上海",
    destination_city: "北京",
    departure_time: base_datetime.change(hour: 15, min: 30),
    arrival_time: base_datetime.change(hour: 18, min: 0),
    departure_airport: "浦东T2",
    arrival_airport: "大兴",
    airline: "东方航空",
    flight_number: "MU#{5201 + day_suffix}",
    aircraft_type: "空客350(大)",
    price: 1680.0,
    discount_price: 0.0,
    seat_class: "business",
    available_seats: 24,
    flight_date: date,
    created_at: timestamp,
    updated_at: timestamp,
    data_version: '0'
  }
  
  # ==================== 北京 -> 广州商务舱/头等舱 ====================
  all_flights << {
    departure_city: "北京",
    destination_city: "广州",
    departure_time: base_datetime.change(hour: 7, min: 30),
    arrival_time: base_datetime.change(hour: 10, min: 45),
    departure_airport: "首都T2",
    arrival_airport: "白云T2",
    airline: "南方航空",
    flight_number: "CZ#{3100 + day_suffix}",
    aircraft_type: "波音787(大)",
    price: 1780.0,
    discount_price: 0.0,
    seat_class: "business",
    available_seats: 28,
    flight_date: date,
    created_at: timestamp,
    updated_at: timestamp,
    data_version: '0'
  }
  
  all_flights << {
    departure_city: "北京",
    destination_city: "广州",
    departure_time: base_datetime.change(hour: 13, min: 0),
    arrival_time: base_datetime.change(hour: 16, min: 15),
    departure_airport: "大兴",
    arrival_airport: "白云T2",
    airline: "南方航空",
    flight_number: "CZ#{3200 + day_suffix}",
    aircraft_type: "空客330(大)",
    price: 1880.0,
    discount_price: 0.0,
    seat_class: "business",
    available_seats: 24,
    flight_date: date,
    created_at: timestamp,
    updated_at: timestamp,
    data_version: '0'
  }
  
  # ==================== 广州 -> 北京商务舱/头等舱 ====================
  all_flights << {
    departure_city: "广州",
    destination_city: "北京",
    departure_time: base_datetime.change(hour: 8, min: 0),
    arrival_time: base_datetime.change(hour: 11, min: 15),
    departure_airport: "白云T2",
    arrival_airport: "首都T2",
    airline: "南方航空",
    flight_number: "CZ#{3101 + day_suffix}",
    aircraft_type: "波音787(大)",
    price: 1780.0,
    discount_price: 0.0,
    seat_class: "business",
    available_seats: 28,
    flight_date: date,
    created_at: timestamp,
    updated_at: timestamp,
    data_version: '0'
  }
  
  # ==================== 上海 -> 深圳商务舱 ====================
  all_flights << {
    departure_city: "上海",
    destination_city: "深圳",
    departure_time: base_datetime.change(hour: 10, min: 30),
    arrival_time: base_datetime.change(hour: 13, min: 15),
    departure_airport: "虹桥T2",
    arrival_airport: "宝安T3",
    airline: "东方航空",
    flight_number: "MU#{5300 + day_suffix}",
    aircraft_type: "空客321(中)",
    price: 1380.0,
    discount_price: 0.0,
    seat_class: "business",
    available_seats: 16,
    flight_date: date,
    created_at: timestamp,
    updated_at: timestamp,
    data_version: '0'
  }
  
  # ==================== 深圳 -> 上海商务舱 ====================
  all_flights << {
    departure_city: "深圳",
    destination_city: "上海",
    departure_time: base_datetime.change(hour: 14, min: 0),
    arrival_time: base_datetime.change(hour: 16, min: 45),
    departure_airport: "宝安T3",
    arrival_airport: "虹桥T2",
    airline: "东方航空",
    flight_number: "MU#{5301 + day_suffix}",
    aircraft_type: "空客321(中)",
    price: 1380.0,
    discount_price: 0.0,
    seat_class: "business",
    available_seats: 16,
    flight_date: date,
    created_at: timestamp,
    updated_at: timestamp,
    data_version: '0'
  }
end

Flight.insert_all(all_flights)

puts "✓ premium_flights_v1 数据包加载完成（#{all_flights.size}条商务舱/头等舱航班记录）"
