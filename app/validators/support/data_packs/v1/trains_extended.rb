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
    departure_station: "上海虹桥站",
    arrival_station: "北京南站",
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
    departure_station: "上海虹桥站",
    arrival_station: "北京南站",
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
    departure_station: "上海虹桥站",
    arrival_station: "北京南站",
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
    departure_station: "北京南站",
    arrival_station: "上海虹桥站",
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
    departure_station: "北京南站",
    arrival_station: "上海虹桥站",
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
    departure_station: "北京南站",
    arrival_station: "上海虹桥站",
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
    departure_station: "北京西站",
    arrival_station: "广州南站",
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
    departure_station: "广州南站",
    arrival_station: "北京西站",
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

# 获取刚创建的火车ID列表（通过train_number匹配）
train_numbers = all_trains.map { |t| t[:train_number] }
extended_trains = Train.where(data_version: 0, train_number: train_numbers)

puts "\n找到 #{extended_trains.count} 趟扩展火车，开始创建座位和套餐数据..."

# ==================== 为扩展的火车创建座位类型数据 ====================
puts "\n为扩展的车次创建座位类型数据..."
all_seats = []

extended_trains.find_each do |train|
  # 为每趟车创建4种座位类型
  seat_types = [
    { 
      seat_type: 'second_class', 
      price: train.price_second_class, 
      total: rand(300..500),
      available_ratio: rand(0.3..0.9)
    },
    { 
      seat_type: 'first_class', 
      price: train.price_first_class, 
      total: rand(100..200),
      available_ratio: rand(0.3..0.9)
    },
    { 
      seat_type: 'business_class', 
      price: train.price_business_class, 
      total: rand(20..50),
      available_ratio: rand(0.3..0.9)
    },
    { 
      seat_type: 'no_seat', 
      price: (train.price_second_class * 0.5).round(1), 
      total: 999,
      available_ratio: 0.99
    }
  ]
  
  seat_types.each do |seat_data|
    available = (seat_data[:total] * seat_data[:available_ratio]).to_i
    all_seats << {
      train_id: train.id,
      seat_type: seat_data[:seat_type],
      price: seat_data[:price],
      total_count: seat_data[:total],
      available_count: available,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

TrainSeat.insert_all(all_seats) if all_seats.any?
puts "   ✓ 已为扩展的 #{extended_trains.count} 趟火车创建 #{all_seats.size} 个座位类型记录"

# ==================== 为扩展的火车创建订票套餐 ====================
puts "\n为扩展的车次创建订票套餐..."
all_options = []

extended_trains.find_each do |train|
  booking_options = [
    {
      train_id: train.id,
      title: '超值7大权益',
      description: '含送站、预约座位、延误退改、分享红包等',
      extra_fee: 59,
      benefits: ['送站服务', '预约座位', '延误退改', '退票无忧', '分享红包', '出行保障', '优先客服'],
      priority: 1,
      is_active: true,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      train_id: train.id,
      title: '登录12306购票',
      description: '使用12306账号直接购买，享受官方价格',
      extra_fee: 0,
      benefits: ['官方价格', '无额外费用', '账号直购'],
      priority: 2,
      is_active: true,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      train_id: train.id,
      title: '免登12306购票',
      description: '无需12306账号，快速下单',
      extra_fee: 25,
      benefits: ['无需12306', '快速下单', '支付便捷'],
      priority: 3,
      is_active: true,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_options.concat(booking_options)
end

BookingOption.insert_all(all_options) if all_options.any?
puts "   ✓ 已为扩展的 #{extended_trains.count} 趟火车创建 #{all_options.size} 个订票套餐记录"

puts "\n✓ trains_extended_v1 数据包加载完成（#{all_trains.size}条火车票记录，含座位和套餐数据）"
