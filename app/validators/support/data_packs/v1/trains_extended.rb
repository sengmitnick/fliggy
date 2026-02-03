# frozen_string_literal: true

# trains_extended_v1 数据包
# 为v192-v200验证器提供更长周期的火车票数据
#
# 用途：
# - 扩展火车票数据到未来15天
# - 支持7天以上的往返行程规划
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 trains_extended_v1 数据包（扩展未来15天）..."

# 扩展日期：从第8天到第15天
start_date = Date.today + 8.days
end_date = Date.today + 15.days

puts "  扩展火车票日期范围: #{start_date} 至 #{end_date} (共8天)"

all_trains = []
timestamp = Time.current

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.today).to_i
  
  # 上海→北京（去程）
  all_trains << {
    departure_city: "上海",
    arrival_city: "北京",
    departure_time: base_datetime.change(hour: 7, min: 0),
    arrival_time: base_datetime.change(hour: 11, min: 30),
    train_number: "G#{1 + day_suffix}",
    duration: 270,
    price_second_class: 553.0,
    price_first_class: 933.0,
    price_business_class: 1748.0,
    available_seats: 150,
    data_version: '0',
    created_at: timestamp,
    updated_at: timestamp
  }
  
  all_trains << {
    departure_city: "上海",
    arrival_city: "北京",
    departure_time: base_datetime.change(hour: 9, min: 0),
    arrival_time: base_datetime.change(hour: 13, min: 30),
    train_number: "G#{3 + day_suffix}",
    duration: 270,
    price_second_class: 553.0,
    price_first_class: 933.0,
    price_business_class: 1748.0,
    available_seats: 160,
    data_version: '0',
    created_at: timestamp,
    updated_at: timestamp
  }
  
  all_trains << {
    departure_city: "上海",
    arrival_city: "北京",
    departure_time: base_datetime.change(hour: 14, min: 0),
    arrival_time: base_datetime.change(hour: 18, min: 30),
    train_number: "G#{11 + day_suffix}",
    duration: 270,
    price_second_class: 443.0,
    price_first_class: 723.0,
    price_business_class: 1355.0,
    available_seats: 180,
    data_version: '0',
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 北京→上海（返程）
  all_trains << {
    departure_city: "北京",
    arrival_city: "上海",
    departure_time: base_datetime.change(hour: 8, min: 0),
    arrival_time: base_datetime.change(hour: 12, min: 30),
    train_number: "G#{2 + day_suffix}",
    duration: 270,
    price_second_class: 553.0,
    price_first_class: 933.0,
    price_business_class: 1748.0,
    available_seats: 150,
    data_version: '0',
    created_at: timestamp,
    updated_at: timestamp
  }
  
  all_trains << {
    departure_city: "北京",
    arrival_city: "上海",
    departure_time: base_datetime.change(hour: 10, min: 0),
    arrival_time: base_datetime.change(hour: 14, min: 30),
    train_number: "G#{4 + day_suffix}",
    duration: 270,
    price_second_class: 553.0,
    price_first_class: 933.0,
    price_business_class: 1748.0,
    available_seats: 160,
    data_version: '0',
    created_at: timestamp,
    updated_at: timestamp
  }
  
  all_trains << {
    departure_city: "北京",
    arrival_city: "上海",
    departure_time: base_datetime.change(hour: 15, min: 0),
    arrival_time: base_datetime.change(hour: 19, min: 30),
    train_number: "G#{12 + day_suffix}",
    duration: 270,
    price_second_class: 443.0,
    price_first_class: 723.0,
    price_business_class: 1355.0,
    available_seats: 180,
    data_version: '0',
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 北京→广州（去程）
  all_trains << {
    departure_city: "北京",
    arrival_city: "广州",
    departure_time: base_datetime.change(hour: 8, min: 5),
    arrival_time: base_datetime.change(hour: 16, min: 24),
    train_number: "G#{65 + day_suffix}",
    duration: 499,
    price_second_class: 862.0,
    price_first_class: 1383.0,
    price_business_class: 2727.5,
    available_seats: 140,
    data_version: '0',
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 广州→北京（返程）
  all_trains << {
    departure_city: "广州",
    arrival_city: "北京",
    departure_time: base_datetime.change(hour: 9, min: 0),
    arrival_time: base_datetime.change(hour: 17, min: 19),
    train_number: "G#{66 + day_suffix}",
    duration: 499,
    price_second_class: 862.0,
    price_first_class: 1383.0,
    price_business_class: 2727.5,
    available_seats: 140,
    data_version: '0',
    created_at: timestamp,
    updated_at: timestamp
  }
end

Train.insert_all(all_trains)

puts "✓ trains_extended_v1 数据包加载完成（#{all_trains.size}条火车票记录）"
