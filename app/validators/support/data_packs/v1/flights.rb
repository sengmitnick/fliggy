# frozen_string_literal: true

# 加载 activerecord-import gem
require 'activerecord-import' unless defined?(ActiveRecord::Import)

# flights_v1 数据包
# 用于航班验证任务
#
# 数据说明：
# - 深圳到北京：每天4个航班，最低价550元
# - 上海到深圳：每天3个航班（含18:30晚班），考虑折扣后最低价450元
# - 北京往返深圳：每天各2个航班
# - 北京往返上海：每天各3个航班
# - 广州往返成都：每天各2个航班
# - 杭州往返三亚：每天各2个航班
# - 西安往返南京：每天各2个航班
# - 北京往返杭州：每天各2个航班
# - 北京往返广州：每天各2个航班
# - 上海往返成都：每天各2个航班
# - 北京到上海浦东T1：每天1个航班（V114专用）
# - 成都到杭州：每天2个航班（V116专用）
# - 国际航班到上海浦东T2深夜：每天1个航班（V117专用）
# - 生成未来7天的航班数据
# - 不使用显式 ID，让数据库自动生成

puts "正在加载 flights_v1 数据包..."

# ==================== 动态日期设置 ====================
# 生成未来21天的航班数据（从今天开始，支持20天后的返程航班）
start_date = Date.current
end_date = start_date + 20.days

puts "  航班日期范围: #{start_date} 至 #{end_date} (共21天)"

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

# ==================== 北京 <-> 三亚 往返航班 ====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 北京 -> 三亚
  flights_bj_to_sy = [
    {
      departure_city: "北京",
      destination_city: "三亚",
      departure_time: base_datetime.change(hour: 18, min: 30),
      arrival_time: base_datetime.change(hour: 22, min: 30),
      departure_airport: "首都T3",
      arrival_airport: "凤凰T2",
      airline: "海南航空",
      flight_number: "HU#{7001 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 1280.0,
      discount_price: 150.0,
      seat_class: "economy",
      available_seats: 120,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "三亚",
      departure_time: base_datetime.change(hour: 19, min: 45),
      arrival_time: base_datetime.change(hour: 23, min: 45),
      departure_airport: "大兴",
      arrival_airport: "凤凰T2",
      airline: "中国国航",
      flight_number: "CA#{1371 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 1350.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 110,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "三亚",
      departure_time: base_datetime.change(hour: 20, min: 30),
      arrival_time: (base_datetime + 1.day).change(hour: 0, min: 30),
      departure_airport: "首都T2",
      arrival_airport: "凤凰T2",
      airline: "东方航空",
      flight_number: "MU#{5001 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 1250.0,
      discount_price: 200.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  # 三亚 -> 北京
  flights_sy_to_bj = [
    {
      departure_city: "三亚",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 8, min: 30),
      arrival_time: base_datetime.change(hour: 12, min: 30),
      departure_airport: "凤凰T2",
      arrival_airport: "首都T3",
      airline: "海南航空",
      flight_number: "HU#{7002 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 1300.0,
      discount_price: 180.0,
      seat_class: "economy",
      available_seats: 115,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "三亚",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 14, min: 15),
      arrival_time: base_datetime.change(hour: 18, min: 15),
      departure_airport: "凤凰T2",
      arrival_airport: "大兴",
      airline: "东方航空",
      flight_number: "MU#{5002 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 1280.0,
      discount_price: 150.0,
      seat_class: "economy",
      available_seats: 105,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_bj_to_sy)
  all_flights.concat(flights_sy_to_bj)
end

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
    },
    {
      departure_city: "上海",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 18, min: 30),
      arrival_time: base_datetime.change(hour: 21, min: 15),
      departure_airport: "虹桥T2",
      arrival_airport: "宝安T3",
      airline: "东方航空",
      flight_number: "MU#{5567 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 580.0,
      discount_price: 30.0,
      seat_class: "economy",
      available_seats: 95,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_sh_to_sz)
end

# 批量插入上海->深圳航班
Flight.insert_all(all_flights)

# ==================== 北京 <-> 深圳 往返航班 ====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 北京 -> 深圳
  flights_bj_to_sz = [
    {
      departure_city: "北京",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 8, min: 30),
      arrival_time: base_datetime.change(hour: 11, min: 45),
      departure_airport: "首都T3",
      arrival_airport: "宝安T3",
      airline: "中国国航",
      flight_number: "CA#{1301 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 780.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 14, min: 0),
      arrival_time: base_datetime.change(hour: 17, min: 15),
      departure_airport: "大兴",
      arrival_airport: "宝安T3",
      airline: "南方航空",
      flight_number: "CZ#{3801 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 690.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 80,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_bj_to_sz)
end

# 批量插入北京->深圳航班
Flight.insert_all(all_flights)

# ==================== 北京 <-> 上海 往返航班 ====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 北京 -> 上海
  flights_bj_to_sh = [
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 5, min: 0),
      arrival_time: base_datetime.change(hour: 7, min: 30),
      departure_airport: "首都T3",
      arrival_airport: "虹桥T2",
      airline: "东方航空",
      flight_number: "MU#{5001 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 650.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 5, min: 30),
      arrival_time: base_datetime.change(hour: 8, min: 0),
      departure_airport: "大兴",
      arrival_airport: "虹桥T2",
      airline: "春秋航空",
      flight_number: "9C#{8801 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 580.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 80,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 6, min: 30),
      arrival_time: base_datetime.change(hour: 9, min: 0),
      departure_airport: "首都T2",
      arrival_airport: "虹桥T2",
      airline: "海南航空",
      flight_number: "HU#{7101 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 720.0,
      discount_price: 70.0,
      seat_class: "economy",
      available_seats: 110,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 7, min: 30),
      arrival_time: base_datetime.change(hour: 11, min: 0),
      departure_airport: "首都T3",
      arrival_airport: "浦东T2",
      airline: "中国国航",
      flight_number: "CA#{1801 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 780.0,
      discount_price: 80.0,
      seat_class: "economy",
      available_seats: 120,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 9, min: 0),
      arrival_time: base_datetime.change(hour: 11, min: 30),
      departure_airport: "大兴",
      arrival_airport: "浦东T2",
      airline: "东方航空",
      flight_number: "MU#{5201 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 680.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 90,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 10, min: 30),
      arrival_time: base_datetime.change(hour: 13, min: 0),
      departure_airport: "首都T2",
      arrival_airport: "虹桥T2",
      airline: "南方航空",
      flight_number: "CZ#{3401 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 850.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 75,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 11, min: 30),
      arrival_time: base_datetime.change(hour: 14, min: 0),
      departure_airport: "首都T3",
      arrival_airport: "虹桥T2",
      airline: "中国国航",
      flight_number: "CA#{1901 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 780.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 95,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 23, min: 0),
      arrival_time: (base_datetime + 1.day).change(hour: 1, min: 30),
      departure_airport: "首都T3",
      arrival_airport: "虹桥T2",
      airline: "东方航空",
      flight_number: "MU#{5901 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 520.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 85,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 23, min: 30),
      arrival_time: (base_datetime + 1.day).change(hour: 2, min: 0),
      departure_airport: "大兴",
      arrival_airport: "浦东T2",
      airline: "春秋航空",
      flight_number: "9C#{8901 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 480.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 70,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 23, min: 55),
      arrival_time: (base_datetime + 1.day).change(hour: 2, min: 25),
      departure_airport: "首都T2",
      arrival_airport: "虹桥T2",
      airline: "海南航空",
      flight_number: "HU#{7901 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 500.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 80,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  # 上海 -> 北京
  flights_sh_to_bj = [
    {
      departure_city: "上海",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 8, min: 15),
      arrival_time: base_datetime.change(hour: 10, min: 45),
      departure_airport: "虹桥T2",
      arrival_airport: "首都T3",
      airline: "东方航空",
      flight_number: "MU#{5108 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 720.0,
      discount_price: 70.0,
      seat_class: "economy",
      available_seats: 110,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 10, min: 30),
      arrival_time: base_datetime.change(hour: 12, min: 30),
      departure_airport: "浦东T2",
      arrival_airport: "首都T3",
      airline: "海南航空",
      flight_number: "HU#{7604 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 750.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 13, min: 30),
      arrival_time: base_datetime.change(hour: 16, min: 0),
      departure_airport: "浦东T2",
      arrival_airport: "大兴",
      airline: "中国国航",
      flight_number: "CA#{1802 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 790.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 95,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 18, min: 45),
      arrival_time: base_datetime.change(hour: 21, min: 15),
      departure_airport: "虹桥T2",
      arrival_airport: "首都T2",
      airline: "海南航空",
      flight_number: "HU#{7201 + day_suffix}",
      aircraft_type: "空客330(大)",
      price: 870.0,
      discount_price: 90.0,
      seat_class: "economy",
      available_seats: 135,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_bj_to_sh)
  all_flights.concat(flights_sh_to_bj)
end

Flight.insert_all(all_flights)

# ==================== 广州 <-> 成都 往返航班 ====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 广州 -> 成都
  flights_gz_to_cd = [
    {
      departure_city: "广州",
      destination_city: "成都",
      departure_time: base_datetime.change(hour: 9, min: 20),
      arrival_time: base_datetime.change(hour: 12, min: 10),
      departure_airport: "白云T2",
      arrival_airport: "双流T2",
      airline: "南方航空",
      flight_number: "CZ#{3601 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 680.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 105,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "广州",
      destination_city: "成都",
      departure_time: base_datetime.change(hour: 15, min: 40),
      arrival_time: base_datetime.change(hour: 18, min: 30),
      departure_airport: "白云T2",
      arrival_airport: "双流T1",
      airline: "四川航空",
      flight_number: "3U#{8901 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 620.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 88,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  # 成都 -> 广州
  flights_cd_to_gz = [
    {
      departure_city: "成都",
      destination_city: "广州",
      departure_time: base_datetime.change(hour: 10, min: 15),
      arrival_time: base_datetime.change(hour: 13, min: 5),
      departure_airport: "双流T2",
      arrival_airport: "白云T2",
      airline: "南方航空",
      flight_number: "CZ#{3602 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 700.0,
      discount_price: 70.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "成都",
      destination_city: "广州",
      departure_time: base_datetime.change(hour: 17, min: 25),
      arrival_time: base_datetime.change(hour: 20, min: 15),
      departure_airport: "双流T1",
      arrival_airport: "白云T2",
      airline: "东方航空",
      flight_number: "MU#{5401 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 650.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 92,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_gz_to_cd)
  all_flights.concat(flights_cd_to_gz)
end

Flight.insert_all(all_flights)

# ==================== 杭州 <-> 三亚 往返航班 ====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 杭州 -> 三亚
  flights_hz_to_sy = [
    {
      departure_city: "杭州",
      destination_city: "三亚",
      departure_time: base_datetime.change(hour: 8, min: 40),
      arrival_time: base_datetime.change(hour: 11, min: 30),
      departure_airport: "萧山T3",
      arrival_airport: "凤凰T2",
      airline: "长龙航空",
      flight_number: "GJ#{8801 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 920.0,
      discount_price: 120.0,
      seat_class: "economy",
      available_seats: 98,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "杭州",
      destination_city: "三亚",
      departure_time: base_datetime.change(hour: 14, min: 20),
      arrival_time: base_datetime.change(hour: 17, min: 10),
      departure_airport: "萧山T3",
      arrival_airport: "凤凰T2",
      airline: "海南航空",
      flight_number: "HU#{7601 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 880.0,
      discount_price: 80.0,
      seat_class: "economy",
      available_seats: 85,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  # 三亚 -> 杭州
  flights_sy_to_hz = [
    {
      departure_city: "三亚",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 9, min: 50),
      arrival_time: base_datetime.change(hour: 12, min: 40),
      departure_airport: "凤凰T2",
      arrival_airport: "萧山T3",
      airline: "东方航空",
      flight_number: "MU#{5601 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 950.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 110,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "三亚",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 16, min: 0),
      arrival_time: base_datetime.change(hour: 18, min: 50),
      departure_airport: "凤凰T2",
      arrival_airport: "萧山T3",
      airline: "春秋航空",
      flight_number: "9C#{8901 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 820.0,
      discount_price: 100.0,
      seat_class: "economy",
      available_seats: 125,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_hz_to_sy)
  all_flights.concat(flights_sy_to_hz)
end

Flight.insert_all(all_flights)

# ==================== 西安 <-> 南京 往返航班 ====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 西安 -> 南京
  flights_xa_to_nj = [
    {
      departure_city: "西安",
      destination_city: "南京",
      departure_time: base_datetime.change(hour: 10, min: 30),
      arrival_time: base_datetime.change(hour: 12, min: 40),
      departure_airport: "咸阳T3",
      arrival_airport: "禄口T2",
      airline: "东方航空",
      flight_number: "MU#{2201 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 580.0,
      discount_price: 60.0,
      seat_class: "economy",
      available_seats: 105,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "西安",
      destination_city: "南京",
      departure_time: base_datetime.change(hour: 17, min: 15),
      arrival_time: base_datetime.change(hour: 19, min: 25),
      departure_airport: "咸阳T3",
      arrival_airport: "禄口T2",
      airline: "吉祥航空",
      flight_number: "HO#{1401 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 620.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 90,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  # 南京 -> 西安
  flights_nj_to_xa = [
    {
      departure_city: "南京",
      destination_city: "西安",
      departure_time: base_datetime.change(hour: 11, min: 20),
      arrival_time: base_datetime.change(hour: 13, min: 30),
      departure_airport: "禄口T2",
      arrival_airport: "咸阳T3",
      airline: "东方航空",
      flight_number: "MU#{2202 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 590.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 95,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "南京",
      destination_city: "西安",
      departure_time: base_datetime.change(hour: 18, min: 30),
      arrival_time: base_datetime.change(hour: 20, min: 40),
      departure_airport: "禄口T2",
      arrival_airport: "咸阳T3",
      airline: "中国国航",
      flight_number: "CA#{1601 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 640.0,
      discount_price: 40.0,
      seat_class: "economy",
      available_seats: 88,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_xa_to_nj)
  all_flights.concat(flights_nj_to_xa)
end

Flight.insert_all(all_flights)

# ==================== 北京 <-> 杭州 往返航班 ====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 北京 -> 杭州
  flights_bj_to_hz = [
    {
      departure_city: "北京",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 8, min: 0),
      arrival_time: base_datetime.change(hour: 10, min: 30),
      departure_airport: "首都T3",
      arrival_airport: "萧山T3",
      airline: "中国国航",
      flight_number: "CA#{1701 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 680.0,
      discount_price: 45.0,
      seat_class: "economy",
      available_seats: 120,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 14, min: 30),
      arrival_time: base_datetime.change(hour: 17, min: 0),
      departure_airport: "首都T2",
      arrival_airport: "萧山T3",
      airline: "东方航空",
      flight_number: "MU#{5221 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 720.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 110,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  # 杭州 -> 北京
  flights_hz_to_bj = [
    {
      departure_city: "杭州",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 9, min: 0),
      arrival_time: base_datetime.change(hour: 11, min: 30),
      departure_airport: "萧山T3",
      arrival_airport: "首都T3",
      airline: "东方航空",
      flight_number: "MU#{5231 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 690.0,
      discount_price: 48.0,
      seat_class: "economy",
      available_seats: 115,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "杭州",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 16, min: 0),
      arrival_time: base_datetime.change(hour: 18, min: 30),
      departure_airport: "萧山T3",
      arrival_airport: "首都T2",
      airline: "中国国航",
      flight_number: "CA#{1711 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 730.0,
      discount_price: 55.0,
      seat_class: "economy",
      available_seats: 105,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_bj_to_hz)
  all_flights.concat(flights_hz_to_bj)
end

Flight.insert_all(all_flights)

# ==================== 北京 <-> 广州 往返航班 ====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 北京 -> 广州
  flights_bj_to_gz = [
    {
      departure_city: "北京",
      destination_city: "广州",
      departure_time: base_datetime.change(hour: 7, min: 30),
      arrival_time: base_datetime.change(hour: 10, min: 50),
      departure_airport: "首都T3",
      arrival_airport: "白云T2",
      airline: "南方航空",
      flight_number: "CZ#{3201 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 850.0,
      discount_price: 60.0,
      seat_class: "economy",
      available_seats: 140,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "广州",
      departure_time: base_datetime.change(hour: 15, min: 0),
      arrival_time: base_datetime.change(hour: 18, min: 20),
      departure_airport: "大兴",
      arrival_airport: "白云T1",
      airline: "中国国航",
      flight_number: "CA#{1301 + day_suffix}",
      aircraft_type: "波音738(中)",
      price: 880.0,
      discount_price: 65.0,
      seat_class: "economy",
      available_seats: 135,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  # 广州 -> 北京
  flights_gz_to_bj = [
    {
      departure_city: "广州",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 8, min: 30),
      arrival_time: base_datetime.change(hour: 11, min: 50),
      departure_airport: "白云T2",
      arrival_airport: "首都T3",
      airline: "南方航空",
      flight_number: "CZ#{3211 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 860.0,
      discount_price: 62.0,
      seat_class: "economy",
      available_seats: 145,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "广州",
      destination_city: "北京",
      departure_time: base_datetime.change(hour: 17, min: 0),
      arrival_time: base_datetime.change(hour: 20, min: 20),
      departure_airport: "白云T1",
      arrival_airport: "大兴",
      airline: "中国国航",
      flight_number: "CA#{1311 + day_suffix}",
      aircraft_type: "波音738(中)",
      price: 890.0,
      discount_price: 68.0,
      seat_class: "economy",
      available_seats: 130,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_bj_to_gz)
  all_flights.concat(flights_gz_to_bj)
  
  # 广州 -> 上海
  flights_gz_to_sh = [
    {
      departure_city: "广州",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 9, min: 0),
      arrival_time: base_datetime.change(hour: 11, min: 30),
      departure_airport: "白云T2",
      arrival_airport: "虹桥T2",
      airline: "东方航空",
      flight_number: "MU#{5401 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 720.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 150,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "广州",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 16, min: 0),
      arrival_time: base_datetime.change(hour: 18, min: 30),
      departure_airport: "白云T2",
      arrival_airport: "虹桥T2",
      airline: "南方航空",
      flight_number: "CZ#{8801 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 780.0,
      discount_price: 60.0,
      seat_class: "economy",
      available_seats: 140,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_gz_to_sh)
end

Flight.insert_all(all_flights)

# ==================== 上海 <-> 成都 往返航班 ====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 上海 -> 成都
  flights_sh_to_cd = [
    {
      departure_city: "上海",
      destination_city: "成都",
      departure_time: base_datetime.change(hour: 7, min: 0),
      arrival_time: base_datetime.change(hour: 10, min: 20),
      departure_airport: "浦东T2",
      arrival_airport: "双流T2",
      airline: "东方航空",
      flight_number: "MU#{5424 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 780.0,  # V246: 低价经济舱（Phase 2会设置为无行李）
      discount_price: 55.0,
      seat_class: "economy",
      available_seats: 125,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      destination_city: "成都",
      departure_time: base_datetime.change(hour: 13, min: 30),
      arrival_time: base_datetime.change(hour: 16, min: 50),
      departure_airport: "虹桥T2",
      arrival_airport: "天府T1",
      airline: "四川航空",
      flight_number: "3U#{8924 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 820.0,  # V246: 标准经济舱（Phase 2会设置含行李）
      discount_price: 60.0,
      seat_class: "economy",
      available_seats: 130,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  # 成都 -> 上海
  flights_cd_to_sh = [
    {
      departure_city: "成都",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 8, min: 0),
      arrival_time: base_datetime.change(hour: 11, min: 20),
      departure_airport: "双流T2",
      arrival_airport: "浦东T2",
      airline: "东方航空",
      flight_number: "MU#{5431 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 790.0,
      discount_price: 58.0,
      seat_class: "economy",
      available_seats: 120,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "成都",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 15, min: 0),
      arrival_time: base_datetime.change(hour: 18, min: 20),
      departure_airport: "天府T1",
      arrival_airport: "虹桥T2",
      airline: "四川航空",
      flight_number: "3U#{8931 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 830.0,
      discount_price: 63.0,
      seat_class: "economy",
      available_seats: 135,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_sh_to_cd)
  all_flights.concat(flights_cd_to_sh)
end

Flight.insert_all(all_flights)

# ==================== 北京 -> 上海浦东T1（V114/V199专用）====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  flights_bj_to_sh_t1 = [
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 7, min: 30),
      arrival_time: base_datetime.change(hour: 10, min: 0),
      departure_airport: "首都T3",
      arrival_airport: "浦东T1",
      airline: "中国国航",
      flight_number: "CA1831",  # V199专用：明天上午10:00到达浦东T1
      aircraft_type: "波音737(中)",
      price: 780.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 120,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 12, min: 0),
      arrival_time: base_datetime.change(hour: 14, min: 30),
      departure_airport: "首都T3",
      arrival_airport: "浦东国际机场T1航站楼",
      airline: "东方航空",
      flight_number: "MU#{5301 + day_suffix}",  # V114专用
      aircraft_type: "空客320(中)",
      price: 750.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_bj_to_sh_t1)
end

Flight.insert_all(all_flights)

# ==================== 成都 -> 杭州萧山机场（V116专用）====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  flights_cd_to_hz = [
    {
      departure_city: "成都",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 9, min: 20),
      arrival_time: base_datetime.change(hour: 11, min: 50),
      departure_airport: "双流T2",
      arrival_airport: "萧山国际机场",
      airline: "四川航空",
      flight_number: "3U#{8501 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 880.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 120,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "成都",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 15, min: 30),
      arrival_time: base_datetime.change(hour: 18, min: 0),
      departure_airport: "双流T1",
      arrival_airport: "萧山国际机场",
      airline: "东方航空",
      flight_number: "MU#{5601 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 920.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 95,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_cd_to_hz)
end

Flight.insert_all(all_flights)

# ==================== 国际航班 -> 上海浦东T2深夜（V117专用）====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  flights_international_to_sh = [
    {
      departure_city: "东京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 19, min: 30),
      arrival_time: base_datetime.change(hour: 22, min: 0),
      departure_airport: "成田T1",
      arrival_airport: "浦东国际机场T2航站楼",
      airline: "全日空",
      flight_number: "NH#{921 + day_suffix}",
      aircraft_type: "波音787(大)",
      price: 1580.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 180,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "首尔",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 20, min: 0),
      arrival_time: base_datetime.change(hour: 22, min: 15),
      departure_airport: "仁川T1",
      arrival_airport: "浦东国际机场T2航站楼",
      airline: "大韩航空",
      flight_number: "KE#{891 + day_suffix}",
      aircraft_type: "空客330(大)",
      price: 1280.0,
      discount_price: 100.0,
      seat_class: "economy",
      available_seats: 150,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_international_to_sh)
end

Flight.insert_all(all_flights)

# ==================== 上海 <-> 杭州 往返航班（用于V168验证） ====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 上海 -> 杭州
  flights_sh_to_hz = [
    {
      departure_city: "上海",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 8, min: 0),
      arrival_time: base_datetime.change(hour: 9, min: 0),
      departure_airport: "虹桥T2",
      arrival_airport: "萧山",
      airline: "东方航空",
      flight_number: "MU#{5331 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 280.0,
      discount_price: 20.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 14, min: 30),
      arrival_time: base_datetime.change(hour: 15, min: 30),
      departure_airport: "浦东T2",
      arrival_airport: "萧山",
      airline: "吉祥航空",
      flight_number: "HO#{1188 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 320.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 90,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  # 杭州 -> 上海
  flights_hz_to_sh = [
    {
      departure_city: "杭州",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 10, min: 30),
      arrival_time: base_datetime.change(hour: 11, min: 30),
      departure_airport: "萧山",
      arrival_airport: "虹桥T2",
      airline: "东方航空",
      flight_number: "MU#{5332 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 290.0,
      discount_price: 20.0,
      seat_class: "economy",
      available_seats: 110,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "杭州",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 16, min: 0),
      arrival_time: base_datetime.change(hour: 17, min: 0),
      departure_airport: "萧山",
      arrival_airport: "浦东T2",
      airline: "吉祥航空",
      flight_number: "HO#{1189 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 310.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 95,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_sh_to_hz)
  all_flights.concat(flights_hz_to_sh)
end

Flight.insert_all(all_flights)

# ==================== 上海 -> 广州 航班（用于V169验证） ====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 上海 -> 广州
  flights_sh_to_gz = [
    {
      departure_city: "上海",
      destination_city: "广州",
      departure_time: base_datetime.change(hour: 8, min: 30),
      arrival_time: base_datetime.change(hour: 11, min: 15),
      departure_airport: "虹桥T2",
      arrival_airport: "白云T2",
      airline: "南方航空",
      flight_number: "CZ#{3501 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 680.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 120,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      destination_city: "广州",
      departure_time: base_datetime.change(hour: 14, min: 0),
      arrival_time: base_datetime.change(hour: 16, min: 45),
      departure_airport: "浦东T2",
      arrival_airport: "白云T2",
      airline: "东方航空",
      flight_number: "MU#{5171 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 720.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_sh_to_gz)
end

Flight.insert_all(all_flights)

# 批量生成优惠信息（为所有航班生成）
# 原有36个航班 + 北京上海凌晨航班(3) + 北京上海红眼航班(3) + 北京上海浦东T1(1) + 成都杭州(2) + 国际航班(2) + 上海杭州(4) + 上海广州(2) + 北京三亚(5) = 每天58个航班
total_flights = (start_date..end_date).count * 47
Flight.where(data_version: 0).find_each(&:generate_offers)

puts "  - 深圳到北京: 每天4个航班，最低价 550元（共 #{(start_date..end_date).count * 4} 个）"
puts "  - 上海到深圳: 每天2个航班，最低价 450元（共 #{(start_date..end_date).count * 2} 个）"
puts "  - 北京往返上海: 每天去程9个航班(含3个凌晨航班、3个红眼航班)、返程3个航班（共 #{(start_date..end_date).count * 12} 个）"
puts "  - 广州往返成都: 每天各2个航班（共 #{(start_date..end_date).count * 4} 个）"
puts "  - 北京往返三亚: 每天去程3个航班(含晚上航班)、返程2个航班（共 #{(start_date..end_date).count * 5} 个）"
puts "  - 西安往返南京: 每天各2个航班（共 #{(start_date..end_date).count * 4} 个）"
puts "  - 北京往返杭州: 每天各2个航班（共 #{(start_date..end_date).count * 4} 个）"
puts "  - 北京往返广州: 每天各2个航班（共 #{(start_date..end_date).count * 4} 个）"
puts "  - 上海往返成都: 每天各2个航班（共 #{(start_date..end_date).count * 4} 个）"
puts "  - 北京到上海浦东T1: 每天1个航班（共 #{(start_date..end_date).count * 1} 个）"
puts "  - 成都到杭州: 每天2个航班（共 #{(start_date..end_date).count * 2} 个）"
puts "  - 国际航班到上海浦东T2深夜: 每天2个航班（共 #{(start_date..end_date).count * 2} 个）"
puts "  - 上海往返杭州: 每天各2个航班（共 #{(start_date..end_date).count * 4} 个）"
puts "  - 上海到广州: 每天2个航班（共 #{(start_date..end_date).count * 2} 个）"

# ==================== 北京 → 上海 低价航班（≤300元） ====================
budget_flights_bj_to_sh = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 北京 → 上海 低价航班
  budget_flights = [
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 22, min: 30),
      arrival_time: (base_datetime + 1.day).change(hour: 1, min: 0),
      departure_airport: "大兴",
      arrival_airport: "浦东T2",
      airline: "九元航空",
      flight_number: "AQ#{1101 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 199.0,  # 特价
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 80,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 23, min: 0),
      arrival_time: (base_datetime + 1.day).change(hour: 1, min: 30),
      departure_airport: "大兴",
      arrival_airport: "浦东T1",
      airline: "春秋航空",
      flight_number: "9C#{8901 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 249.0,  # 特价
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 90,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 6, min: 0),
      arrival_time: base_datetime.change(hour: 8, min: 30),
      departure_airport: "大兴",
      arrival_airport: "浦东T2",
      airline: "西部航空",
      flight_number: "PN#{6201 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 279.0,  # 特价
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 85,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 7, min: 0),
      arrival_time: base_datetime.change(hour: 9, min: 30),
      departure_airport: "大兴",
      arrival_airport: "虫桥T2",
      airline: "九元航空",
      flight_number: "AQ#{1201 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 299.0,  # 特价
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 75,
      flight_date: date,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  budget_flights_bj_to_sh.concat(budget_flights)
end

Flight.insert_all(budget_flights_bj_to_sh)

puts "  - 北京到上海低价航班(≤300元): 每天4个航班（共 #{budget_flights_bj_to_sh.count} 个）"

# ==================== 上海 -> 杭州 中转航班（V211专用，18:00出发） ====================
layover_flights_sh_to_hz = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  flight = {
    flight_number: "MU#{5588 + day_suffix}",
    airline: "东方航空",
    departure_city: "上海",
    destination_city: "杭州",
    departure_airport: "虹桥机场",
    arrival_airport: "萧山机场",
    flight_date: date,
    departure_time: base_datetime.change(hour: 18, min: 0),
    arrival_time: base_datetime.change(hour: 19, min: 0),
    price: 480.0,
    discount_price: 0.0,
    available_seats: 50,
    seat_class: "economy",
    mileage_accrual: true,
    baggage_allowance: "20kg",
    meal_service: true,
    aircraft_type: "A320",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  layover_flights_sh_to_hz << flight
end

Flight.insert_all(layover_flights_sh_to_hz)

puts "  - 上海→杭州中转航班(18:00出发): 每天1个航班（共 #{layover_flights_sh_to_hz.count} 个）"

# ==================== 补充路线: 深圳→杭州 (flights_supplement) ====================
puts "\n[补充] 深圳→杭州 航班..."
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  flights_sz_to_hz = [
    {
      departure_city: "深圳",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 8, min: 30),
      arrival_time: base_datetime.change(hour: 10, min: 45),
      departure_airport: "宝安T3",
      arrival_airport: "萧山T3",
      airline: "深圳航空",
      flight_number: "ZH#{9201 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 850.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 150,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "深圳",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 13, min: 0),
      arrival_time: base_datetime.change(hour: 15, min: 20),
      departure_airport: "宝安T3",
      arrival_airport: "萧山T3",
      airline: "东方航空",
      flight_number: "MU#{5701 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 920.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 120,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "深圳",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 17, min: 30),
      arrival_time: base_datetime.change(hour: 19, min: 50),
      departure_airport: "宝安T3",
      arrival_airport: "萧山T3",
      airline: "厦门航空",
      flight_number: "MF#{8301 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 880.0,
      discount_price: 30.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_sz_to_hz)
end

Flight.insert_all(all_flights) if all_flights.any?
puts "   ✓ 深圳→杭州: #{all_flights.count} 个航班"

# ==================== 补充路线: 杭州→深圳 经济舱 (flights_supplement) ====================
puts "\n[补充] 杭州→深圳 航班..."
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  flights_hz_to_sz = [
    {
      departure_city: "杭州",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 7, min: 45),
      arrival_time: base_datetime.change(hour: 10, min: 10),
      departure_airport: "萧山T3",
      arrival_airport: "宝安T3",
      airline: "春秋航空",
      flight_number: "9C#{8901 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 650.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 180,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "杭州",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 11, min: 30),
      arrival_time: base_datetime.change(hour: 14, min: 0),
      departure_airport: "萧山T3",
      arrival_airport: "宝安T3",
      airline: "吉祥航空",
      flight_number: "HO#{1501 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 720.0,
      discount_price: 20.0,
      seat_class: "economy",
      available_seats: 150,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "杭州",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 15, min: 0),
      arrival_time: base_datetime.change(hour: 17, min: 30),
      departure_airport: "萧山T3",
      arrival_airport: "宝安T3",
      airline: "南方航空",
      flight_number: "CZ#{3601 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 800.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 120,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "杭州",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 19, min: 15),
      arrival_time: base_datetime.change(hour: 21, min: 45),
      departure_airport: "萧山T3",
      arrival_airport: "宝安T3",
      airline: "东方航空",
      flight_number: "MU#{5801 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 780.0,
      discount_price: 30.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_hz_to_sz)
end

Flight.insert_all(all_flights) if all_flights.any?
puts "   ✓ 杭州→深圳: #{all_flights.count} 个航班"

# ==================== Phase 2字段更新 (flights_phase2_fields_update) ====================
puts "\n[Phase 2] 更新航班字段..."

flights = Flight.where(data_version: 0).to_a
puts "   找到 #{flights.count} 个航班需要更新"

flights.each_slice(100) do |batch|
  updates = batch.map do |flight|
    is_major_airline = ['国航', '东航', '南航', '海航'].any? { |name| flight.airline&.include?(name) }
    is_premium = flight.price.to_f >= 1500
    is_low_price = flight.price.to_f < 800  # V246: 低价票（<800元）无行李
    
    {
      id: flight.id,
      baggage_allowance: is_low_price ? '' : (is_premium ? '托运行李2件(每件23kg)' : '托运行李1件(23kg)'),
      refund_policy: is_premium ? '可免费改签，退票收5%手续费' : '改签收50元，退票收10%手续费',
      meal_service: is_premium ? '含飞机餐+饮料' : '含简餐',
      mileage_accrual: is_major_airline ? '可累积里程' : '不可累积',
      is_direct: flight.stops.nil? ? true : (flight.stops == 0),
      stops: flight.stops || 0
    }
  end
  
  Flight.upsert_all(updates, unique_by: :id)
end

puts "   ✓ 已更新 #{flights.count} 个航班的Phase 2字段"

# ==================== Phase 2 缺失航班数据 ====================

puts "\n添加 Phase 2 缺失航班数据..."

# 重用start_date/end_date和timestamp
phase2_start = Date.today - 1.day
phase2_end = Date.today + 10.days

# ========== 短途航班 (V207：飞行时长≤2小时) ==========
short_flights = []

[
  { number: 'CZ3401', airline: '南航', dep_city: '深圳', dest_city: '上海', dep_airport: '宝安T3', arr_airport: '虹桥T2', dep_time: '08:00', arr_time: '10:00', price: 680, date_offset: 2 },
  { number: 'MU5401', airline: '东航', dep_city: '广州', dest_city: '上海', dep_airport: '白云T2', arr_airport: '虹桥T2', dep_time: '09:00', arr_time: '11:00', price: 720, date_offset: 2 },
  { number: 'CA1401', airline: '国航', dep_city: '北京', dest_city: '天津', dep_airport: '首都T3', arr_airport: '滨海T2', dep_time: '07:30', arr_time: '08:30', price: 380, date_offset: 2 }
].each do |route|
  flight_date = Date.today + route[:date_offset].days
  
  # 处理跨日到达时间（如果时间包含+1后缀）
  arr_time = route[:arr_time]
  arr_date = flight_date
  if arr_time.include?('+1')
    arr_time = arr_time.gsub('+1', '')
    arr_date = flight_date + 1.day
  end
  
  short_flights << {
    flight_number: route[:number],
    airline: route[:airline],
    departure_city: route[:dep_city],
    destination_city: route[:dest_city],
    departure_airport: route[:dep_airport],
    arrival_airport: route[:arr_airport],
    departure_time: Time.zone.parse("#{flight_date} #{route[:dep_time]}"),
    arrival_time: Time.zone.parse("#{arr_date} #{arr_time}"),
    price: route[:price],
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李1件(23kg)',
    flight_date: flight_date,
    meal_service: '含飞机餐',
    mileage_accrual: '可累积里程',
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Flight.insert_all(short_flights) if short_flights.any?
puts "  ✓ 创建了 #{short_flights.size} 个短途航班"

# ========== 上海→杭州深夜航班 (V211：5-8小时中转时间) ==========
shanghai_hangzhou_flights = []

[
  { number: 'MU5511', airline: '东航', dep_time: '23:30', arr_time: '00:20', price: 420, date_offset: 2, crosses_midnight: true },
  { number: 'FM9201', airline: '上航', dep_time: '00:30', arr_time: '01:20', price: 450, date_offset: 3, crosses_midnight: false },
  { number: 'HO1205', airline: '吉祥', dep_time: '01:00', arr_time: '01:50', price: 480, date_offset: 3, crosses_midnight: false }
].each do |route|
  flight_date = Date.today + route[:date_offset].days
  dep_hour, dep_min = route[:dep_time].split(':').map(&:to_i)
  arr_hour, arr_min = route[:arr_time].split(':').map(&:to_i)
  
  dep_datetime = Time.zone.parse("#{flight_date} #{route[:dep_time]}")
  arr_datetime = route[:crosses_midnight] ? Time.zone.parse("#{flight_date + 1.day} #{route[:arr_time]}") : Time.zone.parse("#{flight_date} #{route[:arr_time]}")
  
  shanghai_hangzhou_flights << {
    flight_number: route[:number],
    airline: route[:airline],
    departure_city: '上海',
    destination_city: '杭州',
    departure_airport: '虹桥T2',
    arrival_airport: '萧山T3',
    departure_time: dep_datetime,
    arrival_time: arr_datetime,
    price: route[:price],
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李1件(23kg)',
    flight_date: flight_date,
    meal_service: '无餐食',
    mileage_accrual: '可累积里程',
    aircraft_type: '空客320(中)',
    available_seats: 80,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Flight.insert_all(shanghai_hangzhou_flights) if shanghai_hangzhou_flights.any?
puts "  ✓ 创建了 #{shanghai_hangzhou_flights.size} 个上海→杭州深夜航班"

# ========== 国际商务舱航班 (V223：价格≥2000元) ==========
international_business_flights = []

# 国际航班路线配置
international_routes = [
  { number: 'MU587', airline: '东航', dep_city: '上海', dep_airport: '浦东T2', dest_city: '纽约', dest_airport: 'JFK', dep_time: '12:30', arr_time: '14:00', price: 8500 },
  { number: 'CA981', airline: '国航', dep_city: '北京', dep_airport: '首都T3', dest_city: '纽约', dest_airport: 'JFK', dep_time: '13:00', arr_time: '15:30', price: 8800 }
]

# 生成覆盖足够日期范围的国际航班（Date.current-1 到 Date.current+10）
international_start_date = Date.today - 1.day
international_end_date = Date.today + 10.days

(international_start_date..international_end_date).each do |flight_date|
  international_routes.each do |route|
    # 处理跨日到达时间（如果时间包含+1后缀）
    arr_time = route[:arr_time]
    arr_date = flight_date
    if arr_time.include?('+1')
      arr_time = arr_time.gsub('+1', '')
      arr_date = flight_date + 1.day
    end
    
    international_business_flights << {
      flight_number: route[:number],
      airline: route[:airline],
      departure_city: route[:dep_city],
      destination_city: route[:dest_city],
      departure_airport: route[:dep_airport],
      arrival_airport: route[:dest_airport],
      departure_time: Time.zone.parse("#{flight_date} #{route[:dep_time]}"),
      arrival_time: Time.zone.parse("#{arr_date} #{arr_time}"),
      price: route[:price],
      seat_class: 'business_class',  # V223要求：商务舱
      is_direct: true,
      stops: 0,
      baggage_allowance: '托运行李3件(每件32kg)',
      flight_date: flight_date,
      meal_service: '含高级飞机餐+酒水',
      mileage_accrual: '可累积里程（150%）',
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

Flight.insert_all(international_business_flights) if international_business_flights.any?
puts "  ✓ 创建了 #{international_business_flights.size} 个国际商务舱航班"

# ========== 支持改签的航班 (V247) ==========
rebookable_flights = []

[
  { number: 'CA1101', airline: '国航', dep_city: '北京', dep_airport: '首都T3', dest_city: '上海', dest_airport: '虹桥T2', dep_time: '14:00', arr_time: '16:30', price: 980, refund: '免费改签', date_offset: 4 },
  { number: 'MU5201', airline: '东航', dep_city: '上海', dep_airport: '虹桥T2', dest_city: '广州', dest_airport: '白云T2', dep_time: '15:00', arr_time: '17:30', price: 1080, refund: '免费改签，退票扣10%', date_offset: 4 },
  { number: 'CZ8101', airline: '南航', dep_city: '广州', dep_airport: '白云T2', dest_city: '杭州', dest_airport: '萧山T3', dep_time: '09:00', arr_time: '11:00', price: 780, refund: '免费改签', date_offset: 5 },
  { number: 'MU5301', airline: '东航', dep_city: '广州', dep_airport: '白云T2', dest_city: '杭州', dest_airport: '萧山T3', dep_time: '14:30', arr_time: '16:30', price: 850, refund: '改签免手续费', date_offset: 5 }
].each do |route|
  flight_date = Date.today + route[:date_offset].days
  
  # 处理跨日到达时间（如果时间包含+1后缀）
  arr_time = route[:arr_time]
  arr_date = flight_date
  if arr_time.include?('+1')
    arr_time = arr_time.gsub('+1', '')
    arr_date = flight_date + 1.day
  end
  
  rebookable_flights << {
    flight_number: route[:number],
    airline: route[:airline],
    departure_city: route[:dep_city],
    destination_city: route[:dest_city],
    departure_airport: route[:dep_airport],
    arrival_airport: route[:dest_airport],
    departure_time: Time.zone.parse("#{flight_date} #{route[:dep_time]}"),
    arrival_time: Time.zone.parse("#{arr_date} #{arr_time}"),
    price: route[:price],
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李1件(23kg)',
    flight_date: flight_date,
    meal_service: '含飞机餐',
    mileage_accrual: '可累积里程',
    refund_policy: route[:refund],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Flight.insert_all(rebookable_flights) if rebookable_flights.any?
puts "  ✓ 创建了 #{rebookable_flights.size} 个支持改签的航班"

# ========== 宽体机航班 (V245：北京→洛杉矶) ==========
widebody_flights = []

[
  { number: 'CA987', airline: '国航', dep_city: '北京', dep_airport: '首都T3', dest_city: '洛杉矶', dest_airport: 'LAX', dep_time: '12:00', arr_time: '09:00+1', price: 7800, aircraft: '波音787', date_offset: 7 },
  { number: 'CA8801', airline: '国航', dep_city: '北京', dep_airport: '首都T3', dest_city: '上海', dest_airport: '虹桥T2', dep_time: '15:00', arr_time: '17:30', price: 1680, aircraft: '宽体机', date_offset: 1 },
  { number: 'CZ8801', airline: '南航', dep_city: '广州', dep_airport: '白云T2', dest_city: '上海', dest_airport: '虹桥T2', dep_time: '16:00', arr_time: '18:30', price: 1580, aircraft: '宽体机', date_offset: 2 }
].each do |route|
  flight_date = Date.today + route[:date_offset].days
  
  # 处理跨日到达时间（如果时间包含+1后缀）
  arr_time = route[:arr_time]
  arr_date = flight_date
  if arr_time.include?('+1')
    arr_time = arr_time.gsub('+1', '')
    arr_date = flight_date + 1.day
  end
  
  widebody_flights << {
    flight_number: route[:number],
    airline: route[:airline],
    departure_city: route[:dep_city],
    destination_city: route[:dest_city],
    departure_airport: route[:dep_airport],
    arrival_airport: route[:dest_airport],
    departure_time: Time.zone.parse("#{flight_date} #{route[:dep_time]}"),
    arrival_time: Time.zone.parse("#{arr_date} #{arr_time}"),
    price: route[:price],
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李2件(每件23kg)',
    flight_date: flight_date,
    meal_service: '含飞机餐',
    mileage_accrual: '可累积里程',
    aircraft_type: route[:aircraft],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Flight.insert_all(widebody_flights) if widebody_flights.any?
puts "  ✓ 创建了 #{widebody_flights.size} 个宽体机航班"

# ==================== 商务舱和头等舱航班数据 ====================
# 为v188-v200验证器提供高端舱位选择

puts "\n=== 添加商务舱/头等舱航班 ==="

premium_flights_data = []
premium_start_date = Date.current
premium_end_date = premium_start_date + 16.days

puts "  商务舱/头等舱航班日期范围: #{premium_start_date} 至 #{premium_end_date} (共16天)"

(premium_start_date..premium_end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - premium_start_date).to_i
  
  # 北京 -> 上海商务舱/头等舱
  premium_flights_data << {
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
  
  premium_flights_data << {
    departure_city: "北京",
    destination_city: "上海",
    departure_time: base_datetime.change(hour: 14, min: 0),
    arrival_time: base_datetime.change(hour: 16, min: 30),
    departure_airport: "大兴",
    arrival_airport: "虹桥T2",
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
  
  premium_flights_data << {
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
  
  # 上海 -> 北京商务舱/头等舱
  premium_flights_data << {
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
  
  premium_flights_data << {
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
  
  # 北京 -> 广州商务舱
  premium_flights_data << {
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
  
  premium_flights_data << {
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
  
  # 广州 -> 北京商务舱
  premium_flights_data << {
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
  
  # 上海 -> 深圳商务舱
  premium_flights_data << {
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
  
  # 深圳 -> 上海商务舱
  premium_flights_data << {
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

Flight.insert_all(premium_flights_data)
puts "  ✓ 创建了 #{premium_flights_data.size} 个商务舱/头等舱航班"

# 国内高端商务舱航班（特定日期）
high_end_domestic = []
[
  { number: 'CA1001', airline: '国航', dep_city: '北京', dep_airport: '首都T3', dest_city: '上海', dest_airport: '虹桥T2', dep_time: '09:00', arr_time: '11:30', price: 2200 },
  { number: 'MU5001', airline: '东航', dep_city: '上海', dep_airport: '虹桥T2', dest_city: '深圳', dest_airport: '宝安T3', dep_time: '10:00', arr_time: '13:00', price: 2400 },
  { number: 'CZ3001', airline: '南航', dep_city: '广州', dep_airport: '白云T2', dest_city: '北京', dest_airport: '首都T3', dep_time: '08:30', arr_time: '11:30', price: 2500 }
].each do |route|
  flight_date = Date.today + 3.days
  high_end_domestic << {
    flight_number: route[:number],
    airline: route[:airline],
    departure_city: route[:dep_city],
    destination_city: route[:dest_city],
    departure_airport: route[:dep_airport],
    arrival_airport: route[:dest_airport],
    departure_time: Time.zone.parse("#{flight_date} #{route[:dep_time]}"),
    arrival_time: Time.zone.parse("#{flight_date} #{route[:arr_time]}"),
    price: route[:price],
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李2件(每件32kg)',
    flight_date: flight_date,
    meal_service: '含高级飞机餐',
    mileage_accrual: '可累积里程（120%）',
    seat_class: 'business',
    available_seats: 20,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

Flight.insert_all(high_end_domestic) if high_end_domestic.any?
puts "  ✓ 创建了 #{high_end_domestic.size} 个国内高端商务舱航班"

# ==================== 航班套餐产品（次卡） ====================
puts "\n=== 创建航班套餐产品 ==="

flight_packages_data = [
  {
    title: "AG超玩会联名",
    subtitle: "国内·单人单程",
    price: 298,
    original_price: 498,
    discount_label: "超低价",
    badge_text: "1次卡",
    badge_color: "#FF9800",
    destination: "全国",
    image_url: "/images/packages/1540959733332-eab4deabeeaf.jpg",
    valid_days: 365,
    description: "AG超玩会联名机票次卡，全国航线任选，有效期1年",
    features: ["全国航线通用", "有效期1年", "不限航司", "可退可改"],
    status: "active",
    data_version: 0
  },
  {
    title: "24节气卡小寒卡",
    subtitle: "国内·单人单程",
    price: 299,
    original_price: 599,
    discount_label: "超低价",
    badge_text: "1次卡",
    badge_color: "#03A9F4",
    destination: "全国",
    image_url: "/images/packages/1436491865332-7a61a109cc05.jpg",
    valid_days: 365,
    description: "24节气主题机票次卡，冬季出行专属优惠",
    features: ["全国航线通用", "有效期1年", "不限航司", "节日特惠"],
    status: "active",
    data_version: 0
  },
  {
    title: "国际机票盲盒",
    subtitle: "666元飞全球",
    price: 666,
    original_price: 2999,
    discount_label: "每日秒杀",
    badge_text: "盲盒",
    badge_color: "#F44336",
    destination: "全球",
    image_url: "/images/packages/1488085061387-422e29b40080.jpg",
    valid_days: 180,
    description: "国际机票盲盒，666元飞全球，16点开抢",
    features: ["全球航线", "惊喜目的地", "超值优惠", "有效期半年"],
    status: "active",
    data_version: 0
  },
  {
    title: "去昆明专线",
    subtitle: "国内热门航线",
    price: 399,
    original_price: 899,
    discount_label: "5折起",
    badge_text: "直播",
    badge_color: "#E91E63",
    destination: "昆明",
    image_url: "/images/packages/1570168007204-dfb528c6958f.jpg",
    valid_days: 365,
    description: "昆明专线机票次卡，四季如春好去处",
    features: ["昆明专线", "全年有效", "多航班可选", "旺季适用"],
    status: "active",
    data_version: 0
  },
  {
    title: "去三亚海岛游",
    subtitle: "阳光沙滩海浪",
    price: 499,
    original_price: 1299,
    discount_label: "新品情报站",
    badge_text: "2次卡",
    badge_color: "#00BCD4",
    destination: "三亚",
    image_url: "/images/packages/1559827260-dc66d52bef19.jpg",
    valid_days: 365,
    description: "三亚海岛游机票次卡，往返2次，全年无休",
    features: ["往返2次", "全年有效", "含税费", "度假首选"],
    status: "active",
    data_version: 0
  },
  {
    title: "去成都吃火锅",
    subtitle: "美食之都专线",
    price: 299,
    original_price: 799,
    discount_label: "限时特惠",
    badge_text: "1次卡",
    badge_color: "#FF5722",
    destination: "成都",
    image_url: "/images/packages/1561814053-c52db5e102e2.jpg",
    valid_days: 365,
    description: "成都美食之旅机票次卡，品尝正宗川菜",
    features: ["成都专线", "美食推荐", "有效期1年", "多航班"],
    status: "active",
    data_version: 0
  }
]

FlightPackage.insert_all(flight_packages_data) if flight_packages_data.any?
puts "  ✓ 创建了 #{flight_packages_data.size} 个航班套餐产品"

# ==================== 为所有航班统一生成 FlightOffer ====================
# 为没有FlightOffer的航班生成4种套餐类型

puts "\n=== 生成航班套餐 ==="

# 强制删除所有旧的FlightOffer以确保使用新的行李额度逻辑
old_offers_count = FlightOffer.where(data_version: 0).count
if old_offers_count > 0
  FlightOffer.where(data_version: 0).delete_all
  puts "   ✓ 已删除 #{old_offers_count} 个旧套餐，准备重新生成"
end

# 查找所有没有FlightOffer的航班
flights_without_offers = Flight.where(data_version: 0)
  .left_joins(:flight_offers)
  .where(flight_offers: { id: nil })
  .to_a

puts "   找到 #{flights_without_offers.count} 个航班需要生成套餐"

if flights_without_offers.any?
  all_offers = []
  timestamp = Time.current
  
  flights_without_offers.each do |flight|
    base_price = flight.price.to_f
    
    # Package 1: 超值精选 (Best Value) - 最低价,无行李托运
    offer1_price = base_price
    offer1_baggage = offer1_price < 800 ? '仅手提行李7KG' : '托运行李1件(23kg)'
    offer1_discount_items = offer1_price < 800 ? ['无免费托运行李'] : []
    
    all_offers << {
      flight_id: flight.id,
      provider_name: '超值精选',
      offer_type: 'featured',
      price: offer1_price,
      original_price: offer1_price + 42,
      cashback_amount: 0,
      discount_items: offer1_discount_items,
      services: ['退改¥92起', '经济舱', '仅全额电子发票'],
      tags: ['含合餐权益', offer1_baggage],
      baggage_info: offer1_baggage,
      meal_included: false,
      refund_policy: '退改¥92起',
      is_featured: true,
      display_order: 0,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    # Package 2: 选座无忧 (Seat Selection) - 标准价,含1件行李
    offer2_price = base_price + 8
    offer2_baggage = offer2_price < 800 ? '仅手提行李7KG' : (offer2_price > 900 ? '托运行李2件(每件23kg)' : '托运行李1件(23kg)')
    offer2_discount_items = offer2_price < 800 ? ['无免费托运行李'] : []
    
    all_offers << {
      flight_id: flight.id,
      provider_name: '选座无忧',
      offer_type: 'standard',
      price: offer2_price,
      original_price: offer2_price + 42,
      cashback_amount: 24,
      discount_items: offer2_discount_items,
      services: ['退改¥92起', '经济舱', '仅全额电子发票'],
      tags: ['含合餐权益', offer2_baggage],
      baggage_info: offer2_baggage,
      meal_included: false,
      refund_policy: '退改¥92起',
      is_featured: false,
      display_order: 1,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    # Package 3: 返现礼遇 (Cashback Package) - 高价,含行李+返现
    offer3_price = base_price + 120
    offer3_baggage = offer3_price > 900 ? '托运行李2件(每件23kg)' : '托运行李1件(23kg)'
    
    all_offers << {
      flight_id: flight.id,
      provider_name: '返现礼遇',
      offer_type: 'cashback',
      price: offer3_price,
      original_price: offer3_price + 100,
      cashback_amount: 90,
      discount_items: [],
      services: ['经济舱', '全额电子发票', offer3_baggage],
      tags: [
        '返¥90返现',
        offer3_baggage,
        '成人可订返现',
        '仅限预定电子票'
      ],
      baggage_info: offer3_baggage,
      meal_included: false,
      refund_policy: '退改签免手续费',
      is_featured: false,
      display_order: 2,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    # Package 4: 家庭好选 (Family Choice) - 中高价,含行李
    offer4_price = base_price + 5
    offer4_baggage = offer4_price < 800 ? '仅手提行李7KG' : '托运行李1件(23kg)'
    offer4_discount_items = offer4_price < 800 ? ['无免费托运行李'] : []
    
    all_offers << {
      flight_id: flight.id,
      provider_name: '家庭好选',
      offer_type: 'family',
      price: offer4_price,
      original_price: offer4_price + 35,
      cashback_amount: 20,
      discount_items: offer4_discount_items,
      services: ['经济舱', '家庭优惠', offer4_baggage],
      tags: [
        '家庭优惠',
        offer4_baggage
      ],
      baggage_info: offer4_baggage,
      meal_included: false,
      refund_policy: '退改¥50起',
      is_featured: false,
      display_order: 3,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
  
  FlightOffer.insert_all(all_offers)
  puts "   ✓ 已生成 #{all_offers.count} 个套餐（为 #{flights_without_offers.count} 个航班）"
else
  puts "   ℹ️  所有航班已有套餐，跳过"
end

puts "\n✅ flights_v1 数据包加载完成！"
