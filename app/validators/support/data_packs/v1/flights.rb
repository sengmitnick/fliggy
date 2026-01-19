# frozen_string_literal: true

# 加载 activerecord-import gem
require 'activerecord-import' unless defined?(ActiveRecord::Import)

# flights_v1 数据包
# 用于航班验证任务
#
# 数据说明：
# - 深圳市到北京市：4个航班，最低价550元
# - 上海市到深圳市：2个航班，考虑折扣后最低价450元
# - 使用动态日期：今天+3天（确保日期始终有效）
# - 不使用显式 ID，让数据库自动生成

puts "正在加载 flights_v1 数据包..."

# ==================== 动态日期设置 ====================
# 使用今天+3天作为航班日期，确保数据始终可选
base_date = Date.current + 3.days
base_datetime = base_date.to_time.in_time_zone

puts "  航班日期: #{base_date} (今天+3天)"

# ==================== 航班数据 ====================
# 深圳市 -> 北京市 航班（4个航班，最低价 550元）
flights_sz_to_bj = [
  {
    departure_city: "深圳市",
    destination_city: "北京市",
    departure_time: base_datetime.change(hour: 8, min: 0),
    arrival_time: base_datetime.change(hour: 11, min: 30),
    departure_airport: "宝安T3",
    arrival_airport: "首都T3",
    airline: "中国国航",
    flight_number: "CA1234",
    aircraft_type: "波音737(中)",
    price: 680.0,
    discount_price: 0.0,
    seat_class: "economy",
    available_seats: 50,
    flight_date: base_date
  },
  {
    departure_city: "深圳市",
    destination_city: "北京市",
    departure_time: base_datetime.change(hour: 10, min: 30),
    arrival_time: base_datetime.change(hour: 14, min: 0),
    departure_airport: "宝安T3",
    arrival_airport: "大兴",
    airline: "南方航空",
    flight_number: "CZ5678",
    aircraft_type: "空客320(中)",
    price: 1200.0,
    discount_price: 0.0,
    seat_class: "economy",
    available_seats: 30,
    flight_date: base_date
  },
  {
    departure_city: "深圳市",
    destination_city: "北京市",
    departure_time: base_datetime.change(hour: 14, min: 0),
    arrival_time: base_datetime.change(hour: 17, min: 30),
    departure_airport: "宝安T3",
    arrival_airport: "首都T2",
    airline: "东方航空",
    flight_number: "MU9012",
    aircraft_type: "空客321(中)",
    price: 550.0,  # 最低价
    discount_price: 0.0,
    seat_class: "economy",
    available_seats: 20,
    flight_date: base_date
  },
  {
    departure_city: "深圳市",
    destination_city: "北京市",
    departure_time: base_datetime.change(hour: 18, min: 0),
    arrival_time: base_datetime.change(hour: 21, min: 30),
    departure_airport: "宝安T3",
    arrival_airport: "大兴",
    airline: "海南航空",
    flight_number: "HU7890",
    aircraft_type: "空客330(大)",
    price: 890.0,
    discount_price: 100.0,
    seat_class: "economy",
    available_seats: 60,
    flight_date: base_date
  }
]

# 批量插入航班（使用 Rails 原生 insert_all）
timestamp = Time.current
flights_with_timestamps = flights_sz_to_bj.map { |attrs| attrs.merge(created_at: timestamp, updated_at: timestamp) }
Flight.insert_all(flights_with_timestamps)

# 批量生成优惠信息
imported_flights = Flight.where(flight_number: flights_sz_to_bj.map { |f| f[:flight_number] })
imported_flights.each(&:generate_offers)

# 上海市 -> 深圳市 航班（2个航班，最低价 450元）
flights_sh_to_sz = [
  {
    departure_city: "上海市",
    destination_city: "深圳市",
    departure_time: base_datetime.change(hour: 9, min: 0),
    arrival_time: base_datetime.change(hour: 11, min: 45),
    departure_airport: "虹桥T2",
    arrival_airport: "宝安T3",
    airline: "春秋航空",
    flight_number: "9C8765",
    aircraft_type: "空客320(中)",
    price: 450.0,  # 最低价
    discount_price: 0.0,
    seat_class: "economy",
    available_seats: 150,
    flight_date: base_date
  },
  {
    departure_city: "上海市",
    destination_city: "深圳市",
    departure_time: base_datetime.change(hour: 13, min: 30),
    arrival_time: base_datetime.change(hour: 16, min: 15),
    departure_airport: "浦东T2",
    arrival_airport: "宝安T3",
    airline: "吉祥航空",
    flight_number: "HO1234",
    aircraft_type: "波音737(中)",
    price: 520.0,
    discount_price: 20.0,
    seat_class: "economy",
    available_seats: 80,
    flight_date: base_date
  }
]

# 批量插入航班（使用 Rails 原生 insert_all）
timestamp = Time.current
flights_with_timestamps = flights_sh_to_sz.map { |attrs| attrs.merge(created_at: timestamp, updated_at: timestamp) }
Flight.insert_all(flights_with_timestamps)

# 批量生成优惠信息
imported_flights = Flight.where(flight_number: flights_sh_to_sz.map { |f| f[:flight_number] })
imported_flights.each(&:generate_offers)

puts "✓ flights_v1 数据包加载完成（6个航班）"
puts "  - 深圳市到北京市: 4个航班，最低价 550元"
puts "  - 上海市到深圳市: 2个航班，最低价 450元"