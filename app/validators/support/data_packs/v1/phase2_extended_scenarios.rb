# frozen_string_literal: true

# phase2_extended_scenarios 数据包
# 为Phase 2验证器补充扩展场景的测试数据
#
# 用途：
# - 补充过夜卧铺火车数据（V209需要 - 22:00-08:00）
# - 补充中转航班数据（V210, V211需要）
# - 补充深夜和早到酒店数据（V212, V213, V214需要）
# - 补充商务舱航班数据（V223需要）
# - 补充特定航空公司航班（V241需要）
#
# 加载方式：
# rake validator:reset_baseline

puts "正在补充Phase 2扩展场景测试数据..."

require_relative '../../../../../app/helpers/image_seed_helper'

# 1. 补充过夜卧铺火车数据（V209需要）
puts "\n=== 补充过夜卧铺火车数据 ==="
overnight_trains = [
  {
    train_number: 'K801',
    departure_city: '北京',
    arrival_city: '上海',
    departure_time: '22:30',
    arrival_time: '07:00',
    duration: 510,  # 8.5小时
    price_second_class: 180,
    price_first_class: 280,
    price_business_class: 450,
    available_seats: 50,
    data_version: '0'
  },
  {
    train_number: 'K802',
    departure_city: '广州',
    arrival_city: '长沙',
    departure_time: '23:00',
    arrival_time: '06:30',
    duration: 450,  # 7.5小时
    price_second_class: 150,
    price_first_class: 230,
    price_business_class: 380,
    available_seats: 60,
    data_version: '0'
  },
  {
    train_number: 'K803',
    departure_city: '成都',
    arrival_city: '西安',
    departure_time: '22:00',
    arrival_time: '08:00',
    duration: 600,  # 10小时
    price_second_class: 200,
    price_first_class: 320,
    price_business_class: 530,
    available_seats: 70,
    data_version: '0'
  }
]

overnight_trains.each do |train_data|
  existing = Train.find_by(train_number: train_data[:train_number], data_version: '0')
  if existing
    existing.update!(train_data)
    puts "  ✓ 更新夜班火车: #{train_data[:train_number]} (#{train_data[:departure_time]}-#{train_data[:arrival_time]})"
  else
    Train.create!(train_data)
    puts "  ✓ 创建夜班火车: #{train_data[:train_number]} (#{train_data[:departure_time]}-#{train_data[:arrival_time]})"
  end
end

# 2. 补充中转航班数据（V210, V211需要）
# 注意：当前FlightOffer模型不支持独立的city fields，需要belongs_to Flight
# 暂时跳过此部分，V210/V211验证器需要单独处理中转航班逻辑
puts "\n=== 跳过中转航班数据（模型不匹配） ==="
puts "  ⚠ FlightOffer当前模型不支持独立的departure_city/destination_city字段"
puts "  ⚠ V210/V211验证器需要在simulate方法中查询多段航班组合"

# 3. 补充深夜和早到酒店数据（V212, V213, V214需要）
puts "\n=== 补充支持特殊入住时间的酒店数据 ==="

# 确保所有酒店都有明确的check_in_time和check_out_time信息
# 创建一些明确支持深夜入住和早退房的酒店

flexible_checkin_hotels = [
  {
    name: '北京24小时全时段酒店',
    city: '北京',
    address: '朝阳区全天路24号',
    price: 380,
    rating: 4.2,
    facilities: 'WiFi, 停车场, 24小时前台, 早餐',
    cancellation_policy: '入住前24小时免费取消',
    image_url: ImageSeedHelper.random_image_from_category(:hotels),
    data_version: '0'
  },
  {
    name: '上海早鸟酒店',
    city: '上海',
    address: '浦东新区早安路10号',
    price: 420,
    rating: 4.3,
    facilities: 'WiFi, 停车场, 提前入住服务, 早餐',
    cancellation_policy: '入住前24小时免费取消',
    image_url: ImageSeedHelper.random_image_from_category(:hotels),
    data_version: '0'
  },
  {
    name: '广州延迟退房酒店',
    city: '广州',
    address: '天河区延时路18号',
    price: 400,
    rating: 4.1,
    facilities: 'WiFi, 停车场, 延迟退房服务, 餐厅',
    cancellation_policy: '入住前48小时免费取消',
    image_url: ImageSeedHelper.random_image_from_category(:hotels),
    data_version: '0'
  }
]

flexible_checkin_hotels.each do |hotel_data|
  existing = Hotel.find_by(name: hotel_data[:name], data_version: '0')
  if existing
    existing.update!(hotel_data)
    puts "  ✓ 更新酒店: #{hotel_data[:name]} (支持灵活入退房)"
  else
    Hotel.create!(hotel_data)
    puts "  ✓ 创建酒店: #{hotel_data[:name]} (支持灵活入退房)"
  end
end

# 4. 补充商务舱航班数据（V223需要 - 价格≥2000元）
puts "\n=== 补充商务舱航班数据 ==="

business_class_flights = [
  {
    flight_number: 'CA1001',
    airline: '国航',
    departure_city: '北京',
    destination_city: '上海',
    departure_time: '08:00',
    arrival_time: '10:30',
    price: 2200,  # 商务舱价格
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李3件(每件32kg)',
    flight_date: Date.today + 1.day,
    meal_service: '含高级飞机餐+酒水',
    mileage_accrual: '可累积里程（150%）',
    data_version: '0'
  },
  {
    flight_number: 'MU5001',
    airline: '东航',
    departure_city: '上海',
    destination_city: '广州',
    departure_time: '09:00',
    arrival_time: '11:45',
    price: 2500,
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李3件(每件32kg)',
    flight_date: Date.today + 1.day,
    meal_service: '含高级飞机餐+酒水',
    mileage_accrual: '可累积里程（150%）',
    data_version: '0'
  },
  {
    flight_number: 'CZ3001',
    airline: '南航',
    departure_city: '广州',
    destination_city: '北京',
    departure_time: '10:00',
    arrival_time: '13:00',
    price: 2300,
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李3件(每件32kg)',
    flight_date: Date.today + 1.day,
    meal_service: '含高级飞机餐+酒水',
    mileage_accrual: '可累积里程（150%）',
    data_version: '0'
  }
]

business_class_flights.each do |flight_data|
  existing = Flight.find_by(flight_number: flight_data[:flight_number], data_version: '0')
  if existing
    existing.update!(flight_data)
    puts "  ✓ 更新商务舱航班: #{flight_data[:flight_number]} (#{flight_data[:price]}元)"
  else
    Flight.create!(flight_data)
    puts "  ✓ 创建商务舱航班: #{flight_data[:flight_number]} (#{flight_data[:price]}元)"
  end
end

# 5. 补充特定航空公司航班（V241需要 - 东航）
puts "\n=== 补充特定航空公司航班数据 ==="

eastern_airlines_flights = [
  {
    flight_number: 'MU2101',
    airline: '东航',
    departure_city: '北京',
    destination_city: '成都',
    departure_time: '14:00',
    arrival_time: '17:00',
    price: 880,
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李1件(23kg)',
    flight_date: Date.today + 1.day,
    meal_service: '含简餐',
    mileage_accrual: '可累积里程',
    data_version: '0'
  },
  {
    flight_number: 'MU2201',
    airline: '东航',
    departure_city: '上海',
    destination_city: '西安',
    departure_time: '11:00',
    arrival_time: '13:30',
    price: 720,
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李1件(23kg)',
    flight_date: Date.today + 1.day,
    meal_service: '含简餐',
    mileage_accrual: '可累积里程',
    data_version: '0'
  },
  {
    flight_number: 'MU2301',
    airline: '东航',
    departure_city: '杭州',
    destination_city: '深圳',
    departure_time: '15:30',
    arrival_time: '18:00',
    price: 850,
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李1件(23kg)',
    flight_date: Date.today + 1.day,
    meal_service: '含简餐',
    mileage_accrual: '可累积里程',
    data_version: '0'
  }
]

eastern_airlines_flights.each do |flight_data|
  existing = Flight.find_by(flight_number: flight_data[:flight_number], data_version: '0')
  if existing
    existing.update!(flight_data)
    puts "  ✓ 更新东航航班: #{flight_data[:flight_number]}"
  else
    Flight.create!(flight_data)
    puts "  ✓ 创建东航航班: #{flight_data[:flight_number]}"
  end
end

puts "\n✓ Phase 2扩展场景数据补充完成"
