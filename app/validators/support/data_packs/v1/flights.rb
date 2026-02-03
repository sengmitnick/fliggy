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
# 生成未来16天的航班数据（从今天开始）
start_date = Date.current
end_date = start_date + 15.days

puts "  航班日期范围: #{start_date} 至 #{end_date} (共16天)"

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
      arrival_airport: "浦东T2",
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
      arrival_time: base_datetime.change(hour: 10, min: 0),
      departure_airport: "首都T3",
      arrival_airport: "虹桥T2",
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
      flight_number: "MU#{5421 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 780.0,
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
      flight_number: "3U#{8921 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 820.0,
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

# ==================== 北京 -> 上海浦东T1（V114专用）====================
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  flights_bj_to_sh_t1 = [
    {
      departure_city: "北京",
      destination_city: "上海",
      departure_time: base_datetime.change(hour: 12, min: 0),
      arrival_time: base_datetime.change(hour: 14, min: 30),
      departure_airport: "首都T3",
      arrival_airport: "浦东国际机场T1航站楼",
      airline: "东方航空",
      flight_number: "MU#{5301 + day_suffix}",
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
