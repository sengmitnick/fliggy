# frozen_string_literal: true

# 加载 activerecord-import gem
require 'activerecord-import' unless defined?(ActiveRecord::Import)

# flights_v1 数据包
# 用于航班验证任务
#
# 数据说明：
# - 深圳到北京：每天4个航班，最低价550元
# - 上海到深圳：每天2个航班，考虑折扣后最低价450元
# - 生成未来7天的航班数据
# - 不使用显式 ID，让数据库自动生成

puts "正在加载 flights_v1 数据包..."

# ==================== 动态日期设置 ====================
# 生成未来7天的航班数据（从明天开始）
start_date = Date.current + 1.day
end_date = start_date + 6.days

puts "  航班日期范围: #{start_date} 至 #{end_date} (共7天)"

# ==================== 航班数据 ====================
# 深圳 -> 北京 航班（每天4个航班，最低价 550元）
all_flights = []
timestamp = Time.current

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i  # 用于生成唯一航班号
  
  flights_sz_to_bj = [
    {
      departure_city: "深圳",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 8, min: 0),
      arrival_time: base_datetime.change(hour: 11, min: 30),
      departure_airport: "宝安T3",
      arrival_airport: "首都T3",
      airline: "中国国航",
      flight_number: "CA#{1234 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 680.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 50,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "深圳",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 10, min: 30),
      arrival_time: base_datetime.change(hour: 14, min: 0),
      departure_airport: "宝安T3",
      arrival_airport: "大兴",
      airline: "南方航空",
      flight_number: "CZ#{5678 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 1200.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 30,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "深圳",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 14, min: 0),
      arrival_time: base_datetime.change(hour: 17, min: 30),
      departure_airport: "宝安T3",
      arrival_airport: "首都T2",
      airline: "东方航空",
      flight_number: "MU#{9012 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 550.0,  # 最低价
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 20,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "深圳",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 18, min: 0),
      arrival_time: base_datetime.change(hour: 21, min: 30),
      departure_airport: "宝安T3",
      arrival_airport: "大兴",
      airline: "海南航空",
      flight_number: "HU#{7890 + day_suffix}",
      aircraft_type: "空客330(大)",
      price: 890.0,
      discount_price: 100.0,
      seat_class: "economy",
      available_seats: 60,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_sz_to_bj)
end

# 批量插入深圳->北京航班
Flight.insert_all(all_flights)

# 上海 -> 深圳 航班（每天2个航班，最低价 450元）
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  flights_sh_to_sz = [
    {
      departure_city: "上海",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 9, min: 0),
      arrival_time: base_datetime.change(hour: 11, min: 45),
      departure_airport: "虹桥T2",
      arrival_airport: "宝安T3",
      airline: "春秋航空",
      flight_number: "9C#{8765 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 450.0,  # 最低价
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 150,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 13, min: 30),
      arrival_time: base_datetime.change(hour: 16, min: 15),
      departure_airport: "浦东T2",
      arrival_airport: "宝安T3",
      airline: "吉祥航空",
      flight_number: "HO#{1234 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 520.0,
      discount_price: 20.0,
      seat_class: "economy",
      available_seats: 80,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_sh_to_sz)
end

# 批量插入上海->深圳航班
Flight.insert_all(all_flights)

# 批量生成优惠信息（为所有航班生成）
total_flights = (start_date..end_date).count * 6  # 每天6个航班（4个深圳->北京 + 2个上海->深圳）
Flight.where(data_version: 0).find_each(&:generate_offers)

puts "✓ flights_v1 数据包加载完成（共 #{total_flights} 个航班）"
puts "  - 深圳到北京: 每天4个航班，最低价 550元（共 #{(start_date..end_date).count * 4} 个）"
puts "  - 上海到深圳: 每天2个航班，最低价 450元（共 #{(start_date..end_date).count * 2} 个）"