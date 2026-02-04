# frozen_string_literal: true

# Phase 2 (V202-V250) 缺失测试数据包
# 为所有Phase 2验证器提供必需的基准测试数据
#
# 用途：
# - 早班车：V206需要05:00-07:00的早班火车（上海→南京）
# - 过夜卧铺：V209需要22:00-次日08:00的过夜火车（北京→西安）
# - 短途航班：V207需要飞行时长≤2小时的航班（深圳→上海）
# - 国际商务舱航班：V223需要国际航线高价商务舱（上海→纽约，≥2000元）
# - 国际宽体机航班：V245需要国际航线宽体机（北京→洛杉矶）
# - 改签航班：V247需要支持改签的航班
# - 宽体机：V245需要宽体机型航班
# - 中高端酒店：多个验证器需要500-800元酒店
# - 宠物友好酒店：V239需要成都的宠物友好酒店
# - 预算酒店：多个验证器需要200-400元经济型酒店
# - 酒店房型：为酒店添加完整的房型数据
# - 预算火车：多个验证器需要100-300元经济型火车
#
# 加载方式：
# rake validator:reset_baseline

require_relative '../../../../../app/helpers/image_seed_helper'

puts "正在加载 Phase 2 缺失测试数据包..."

# ========== 1. 补充早班车数据 (V206需要：05:00-07:00出发) ==========
puts "\n=== 补充早班车数据 ==="

[
  { train_number: 'G8801', departure_city: '上海', arrival_city: '南京', departure_station: '上海虹桥站', arrival_station: '南京南站', time: '05:30', duration: 90, price: 134.5 },
  { train_number: 'G8802', departure_city: '北京', arrival_city: '天津', departure_station: '北京南站', arrival_station: '天津站', time: '06:00', duration: 60, price: 54.5 },
  { train_number: 'G8803', departure_city: '广州', arrival_city: '深圳', departure_station: '广州南站', arrival_station: '深圳北站', time: '06:30', duration: 75, price: 79.5 },
  { train_number: 'G8804', departure_city: '成都', arrival_city: '重庆', departure_station: '成都东站', arrival_station: '重庆北站', time: '05:45', duration: 90, price: 96.0 }
].each do |data|
  train = Train.find_or_initialize_by(train_number: data[:train_number], data_version: '0')
  train.assign_attributes(
    departure_city: data[:departure_city],
    arrival_city: data[:arrival_city],
    departure_station: data[:departure_station],
    arrival_station: data[:arrival_station],
    departure_time: Time.zone.parse("#{Date.today + 1.day} #{data[:time]}"),
    arrival_time: Time.zone.parse("#{Date.today + 1.day} #{data[:time]}") + data[:duration].minutes,
    duration: data[:duration],
    price_second_class: data[:price],
    price_first_class: (data[:price] * 1.6).round(1),
    price_business_class: (data[:price] * 3).round(1),
    available_seats: 100
  )
  train.save! if train.changed?
  puts "  ✓ #{train.new_record? ? '创建' : '更新'}火车: #{data[:train_number]} (#{data[:departure_city]}→#{data[:arrival_city]} #{data[:time]})"
end

# ========== 2. 补充过夜卧铺火车数据 (V209需要：22:00-06:00次日到达，北京→西安) ==========
puts "\n=== 补充过夜卧铺火车数据 ==="

[
  { train_number: 'K801', departure_city: '北京', arrival_city: '上海', departure_station: '北京站', arrival_station: '上海站', dep_time: '22:30', arr_time_next_day: '07:00', duration: 510, price: 180 },
  { train_number: 'K802', departure_city: '广州', arrival_city: '长沙', departure_station: '广州站', arrival_station: '长沙站', dep_time: '23:00', arr_time_next_day: '06:30', duration: 450, price: 150 },
  { train_number: 'K803', departure_city: '成都', arrival_city: '西安', departure_station: '成都站', arrival_station: '西安站', dep_time: '22:00', arr_time_next_day: '08:00', duration: 600, price: 200 },
  { train_number: 'K819', departure_city: '北京', arrival_city: '西安', departure_station: '北京西站', arrival_station: '西安站', dep_time: '22:45', arr_time_next_day: '06:30', duration: 465, price: 195 }
].each do |data|
  train = Train.find_or_initialize_by(train_number: data[:train_number], data_version: '0')
  
  # 出发时间是后天晚上（因为验证器查询 Date.today + 2.days）
  dep_date = Date.today + 2.days
  dep_date_time = Time.zone.parse("#{dep_date} #{data[:dep_time]}")
  # 到达时间是后天+1天早上
  arr_date_time = Time.zone.parse("#{dep_date + 1.day} #{data[:arr_time_next_day]}")
  
  train.assign_attributes(
    departure_city: data[:departure_city],
    arrival_city: data[:arrival_city],
    departure_station: data[:departure_station],
    arrival_station: data[:arrival_station],
    departure_time: dep_date_time,
    arrival_time: arr_date_time,
    duration: data[:duration],
    price_second_class: data[:price],
    price_first_class: (data[:price] * 1.5).round(1),
    price_business_class: (data[:price] * 2.5).round(1),
    available_seats: 80
  )
  train.save! if train.changed?
  puts "  ✓ #{train.new_record? ? '创建' : '更新'}火车: #{data[:train_number]} (#{data[:departure_city]}→#{data[:arrival_city]} #{data[:dep_time]}-#{data[:arr_time_next_day]}次日)"
end

# ========== 3. 补充短途航班数据（V207需要：飞行时长≤2小时，深圳→上海） ==========
puts "\n=== 补充短途航班数据 ==="

# 城市机场映射
airport_map = {
  '深圳' => '宝安T3',
  '上海' => '虹桥T2',
  '广州' => '白云T2',
  '北京' => '首都T3',
  '天津' => '滨海T2'
}

[
  { number: 'CZ3401', airline: '南航', dep: '深圳', dest: '上海', dep_time: '08:00', arr_time: '10:00', price: 680 },
  { number: 'MU5401', airline: '东航', dep: '广州', dest: '上海', dep_time: '09:00', arr_time: '11:00', price: 720 },
  { number: 'CA1401', airline: '国航', dep: '北京', dest: '天津', dep_time: '07:30', arr_time: '08:30', price: 380 }
].each do |data|
  flight = Flight.find_or_initialize_by(flight_number: data[:number], data_version: '0')
  flight.assign_attributes(
    airline: data[:airline],
    departure_city: data[:dep],
    destination_city: data[:dest],
    departure_airport: airport_map[data[:dep]] || data[:dep],
    arrival_airport: airport_map[data[:dest]] || data[:dest],
    departure_time: data[:dep_time],
    arrival_time: data[:arr_time],
    price: data[:price],
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李1件(23kg)',
    flight_date: Date.today + 2.days,
    meal_service: '含飞机餐',
    mileage_accrual: '可累积里程'
  )
  flight.save! if flight.changed?
  puts "  ✓ #{flight.new_record? ? '创建' : '更新'}航班: #{data[:number]} (#{data[:dep]}#{airport_map[data[:dep]]}→#{data[:dest]}#{airport_map[data[:dest]]})"
end

# ========== 3B. 补充上海→杭州航班数据（V211需要：5-8小时中转时间） ==========
puts "\n=== 补充上海→杭州航班数据（支持长中转城市游） ==="

# 基准：CZ8801 广州→上海 16:00-18:30 (flight_date = Date.today + 2.days)
# 到达时间：Date.today + 2.days 18:30
# 需要上海出发时间：23:30 (day+2) ~ 02:30 (day+3)，即5-8小时后
[
  { number: 'MU5511', airline: '东航', dep: '上海', dest: '杭州', dep_time: '23:30', arr_time: '00:20', price: 420, flight_date_offset: 2 },
  { number: 'FM9201', airline: '上航', dep: '上海', dest: '杭州', dep_time: '00:30', arr_time: '01:20', price: 450, flight_date_offset: 3 },
  { number: 'HO1205', airline: '吉祥', dep: '上海', dest: '杭州', dep_time: '01:00', arr_time: '01:50', price: 480, flight_date_offset: 3 }
].each do |data|
  flight = Flight.find_or_initialize_by(flight_number: data[:number], data_version: '0')
  
  # flight_date表示航班的"日期标识"（用于查询筛选）
  # 对于深夜航班（≥23:00），flight_date = 当天日期
  # 对于凌晨航班（<6:00），flight_date = 当天日期（虽然是半夜到达）
  base_date = Date.today + data[:flight_date_offset].days
  dep_hour, dep_min = data[:dep_time].split(':').map(&:to_i)
  arr_hour, arr_min = data[:arr_time].split(':').map(&:to_i)
  
  # 构建完整的departure_time和arrival_time（带日期+时间）
  dep_datetime = Time.zone.parse("#{base_date} #{data[:dep_time]}")
  
  # 如果到达时间<出发时间，说明跨天到达（如23:30出发，00:20到达）
  arr_datetime = if arr_hour < dep_hour
    Time.zone.parse("#{base_date + 1.day} #{data[:arr_time]}")
  else
    Time.zone.parse("#{base_date} #{data[:arr_time]}")
  end
  
  flight.assign_attributes(
    airline: data[:airline],
    departure_city: data[:dep],
    destination_city: data[:dest],
    departure_time: dep_datetime,
    arrival_time: arr_datetime,
    price: data[:price],
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李1件(23kg)',
    flight_date: base_date,  # 航班日期标识
    meal_service: '无餐食',
    mileage_accrual: '可累积里程',
    departure_airport: '虹桥T2',
    arrival_airport: '萧山T3',
    aircraft_type: '空客320(中)',
    available_seats: 80
  )
  flight.save! if flight.changed?
  puts "  ✓ #{flight.new_record? ? '创建' : '更新'}航班: #{data[:number]} (#{data[:dep]}→#{data[:dest]} flight_date=#{base_date} dep=#{dep_datetime.strftime('%H:%M')})"
end

# ========== 4. 补充国际商务舱航班数据（V223需要：上海→纽约，价格≥2000元） ==========
puts "\n=== 补充国际商务舱航班数据 ==="

[
  { number: 'MU587', airline: '东航', dep: '上海', dep_airport: '浦东T2', dest: '纽约', dest_airport: 'JFK', dep_time: '12:30', arr_time: '14:00', price: 8500 },
  { number: 'CA981', airline: '国航', dep: '北京', dep_airport: '首都T3', dest: '纽约', dest_airport: 'JFK', dep_time: '13:00', arr_time: '15:30', price: 8800 }
].each do |data|
  flight = Flight.find_or_initialize_by(flight_number: data[:number], data_version: '0')
  flight.assign_attributes(
    airline: data[:airline],
    departure_city: data[:dep],
    destination_city: data[:dest],
    departure_airport: data[:dep_airport],
    arrival_airport: data[:dest_airport],
    departure_time: data[:dep_time],
    arrival_time: data[:arr_time],
    price: data[:price],
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李3件(每件32kg)',
    flight_date: Date.today + 7.days,
    meal_service: '含高级飞机餐+酒水',
    mileage_accrual: '可累积里程（150%）'
  )
  flight.save! if flight.changed?
  puts "  ✓ #{flight.new_record? ? '创建' : '更新'}国际商务舱航班: #{data[:number]} (#{data[:price]}元)"
end

# ========== 5. 补充国内商务舱/高端航班数据 ==========
puts "\n=== 补充国内商务舱/高端航班数据 ==="

[
  { number: 'CA1001', airline: '国航', dep: '北京', dep_airport: '首都T3', dest: '上海', dest_airport: '虹桥T2', dep_time: '09:00', arr_time: '11:30', price: 2200 },
  { number: 'MU5001', airline: '东航', dep: '上海', dep_airport: '虹桥T2', dest: '深圳', dest_airport: '宝安T3', dep_time: '10:00', arr_time: '13:00', price: 2400 },
  { number: 'CZ3001', airline: '南航', dep: '广州', dep_airport: '白云T2', dest: '北京', dest_airport: '首都T3', dep_time: '08:30', arr_time: '11:30', price: 2500 }
].each do |data|
  flight = Flight.find_or_initialize_by(flight_number: data[:number], data_version: '0')
  flight.assign_attributes(
    airline: data[:airline],
    departure_city: data[:dep],
    destination_city: data[:dest],
    departure_airport: data[:dep_airport],
    arrival_airport: data[:dest_airport],
    departure_time: data[:dep_time],
    arrival_time: data[:arr_time],
    price: data[:price],
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李2件(每件32kg)',
    flight_date: Date.today + 3.days,
    meal_service: '含高级飞机餐',
    mileage_accrual: '可累积里程（120%）'
  )
  flight.save! if flight.changed?
  puts "  ✓ #{flight.new_record? ? '创建' : '更新'}国内商务舱航班: #{data[:number]} (#{data[:price]}元)"
end

# ========== 6. 补充支持改签的航班数据（V247需要：广州→杭州, today+5） ==========
puts "\n=== 补充支持改签的航班数据 ==="

[
  { number: 'CA1101', airline: '国航', dep: '北京', dep_airport: '首都T3', dest: '上海', dest_airport: '虹桥T2', dep_time: '14:00', arr_time: '16:30', price: 980, refund: '免费改签', days: 4 },
  { number: 'MU5201', airline: '东航', dep: '上海', dep_airport: '虹桥T2', dest: '广州', dest_airport: '白云T2', dep_time: '15:00', arr_time: '17:30', price: 1080, refund: '免费改签，退票扣10%', days: 4 },
  { number: 'CZ8101', airline: '南航', dep: '广州', dep_airport: '白云T2', dest: '杭州', dest_airport: '萧山T3', dep_time: '09:00', arr_time: '11:00', price: 780, refund: '免费改签', days: 5 },
  { number: 'MU5301', airline: '东航', dep: '广州', dep_airport: '白云T2', dest: '杭州', dest_airport: '萧山T3', dep_time: '14:30', arr_time: '16:30', price: 850, refund: '改签免手续费', days: 5 }
].each do |data|
  flight = Flight.find_or_initialize_by(flight_number: data[:number], data_version: '0')
  flight.assign_attributes(
    airline: data[:airline],
    departure_city: data[:dep],
    destination_city: data[:dest],
    departure_airport: data[:dep_airport],
    arrival_airport: data[:dest_airport],
    departure_time: data[:dep_time],
    arrival_time: data[:arr_time],
    price: data[:price],
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李1件(23kg)',
    flight_date: Date.today + data[:days].days,
    meal_service: '含飞机餐',
    mileage_accrual: '可累积里程',
    refund_policy: data[:refund]
  )
  flight.save! if flight.changed?
  puts "  ✓ #{flight.new_record? ? '创建' : '更新'}支持改签航班: #{data[:number]}"
end

# ========== 7. 补充宽体机航班数据（V245需要：北京→洛杉矶） ==========
puts "\n=== 补充宽体机航班数据 ==="

[
  { number: 'CA987', airline: '国航', dep: '北京', dep_airport: '首都T3', dest: '洛杉矶', dest_airport: 'LAX', dep_time: '12:00', arr_time: '08:00', price: 7800, aircraft: '波音787' },
  { number: 'CA8801', airline: '国航', dep: '北京', dep_airport: '首都T3', dest: '上海', dest_airport: '虹桥T2', dep_time: '15:00', arr_time: '17:30', price: 1680, aircraft: '宽体机' },
  { number: 'CZ8801', airline: '南航', dep: '广州', dep_airport: '白云T2', dest: '上海', dest_airport: '虹桥T2', dep_time: '16:00', arr_time: '18:30', price: 1580, aircraft: '宽体机' }
].each do |data|
  flight = Flight.find_or_initialize_by(flight_number: data[:number], data_version: '0')
  flight_date = data[:dest] == '洛杉矶' ? Date.today + 7.days : (data[:number] == 'CZ8801' ? Date.today + 2.days : Date.today + 1.day)
  flight.assign_attributes(
    airline: data[:airline],
    departure_city: data[:dep],
    destination_city: data[:dest],
    departure_airport: data[:dep_airport],
    arrival_airport: data[:dest_airport],
    departure_time: Time.zone.parse("#{flight_date} #{data[:dep_time]}"),
    arrival_time: Time.zone.parse("#{flight_date} #{data[:arr_time]}"),
    price: data[:price],
    is_direct: true,
    stops: 0,
    baggage_allowance: '托运行李2件(每件23kg)',
    flight_date: flight_date,
    meal_service: '含飞机餐',
    mileage_accrual: '可累积里程',
    aircraft_type: data[:aircraft]
  )
  flight.save! if flight.changed?
  puts "  ✓ #{flight.new_record? ? '创建' : '更新'}宽体机航班: #{data[:number]}"
end

# ========== 8. 补充中高端酒店数据 (多个验证器需要：价格500-800元) ==========
puts "\n=== 补充中高端酒店数据 ==="

[
  { name: '北京商务精选酒店', city: '北京', address: '朝阳区商务中心路88号', price: 580, rating: 4.3 },
  { name: '上海都市商旅酒店', city: '上海', address: '浦东新区陆家嘴环路99号', price: 650, rating: 4.4 },
  { name: '广州珠江景观酒店', city: '广州', address: '天河区珠江新城CBD核心', price: 620, rating: 4.2 },
  { name: '深圳科技园商务酒店', city: '深圳', address: '南山区科技园南区', price: 680, rating: 4.5 },
  { name: '成都春熙路精品酒店', city: '成都', address: '锦江区春熙路步行街', price: 550, rating: 4.1 },
  { name: '杭州西湖景区酒店', city: '杭州', address: '西湖区湖滨路', price: 720, rating: 4.6 },
  { name: '南京夫子庙文化酒店', city: '南京', address: '秦淮区夫子庙景区', price: 590, rating: 4.3 }
].each do |data|
  hotel = Hotel.find_or_initialize_by(name: data[:name], data_version: '0')
  hotel.assign_attributes(
    city: data[:city],
    address: data[:address],
    price: data[:price],
    rating: data[:rating],
    facilities: 'WiFi, 停车场, 早餐, 健身房, 会议室',
    image_url: ImageSeedHelper.random_image_from_category(:hotels)
  )
  hotel.save! if hotel.changed?
  puts "  ✓ #{hotel.new_record? ? '创建' : '更新'}酒店: #{data[:name]} (#{data[:price]}元)"
end

# ========== 9. 补充宠物友好酒店数据（V239需要：成都） ==========
puts "\n=== 补充宠物友好酒店数据 ==="

[
  { name: '北京宠物友好度假酒店', city: '北京', address: '朝阳区宠物路1号', price: 450, rating: 4.3, facilities: 'WiFi, 停车场, 宠物友好, 早餐' },
  { name: '上海宠物乐园酒店', city: '上海', address: '浦东新区宠物大道88号', price: 480, rating: 4.4, facilities: 'WiFi, 停车场, 宠物友好, 宠物用品, 早餐' },
  { name: '成都宠物友好酒店', city: '成都', address: '武侯区宠物街66号', price: 420, rating: 4.2, facilities: 'WiFi, 停车场, 宠物友好, 宠物用品, 早餐' }
].each do |data|
  hotel = Hotel.find_or_initialize_by(name: data[:name], data_version: '0')
  hotel.assign_attributes(
    city: data[:city],
    address: data[:address],
    price: data[:price],
    rating: data[:rating],
    facilities: data[:facilities],
    image_url: ImageSeedHelper.random_image_from_category(:hotels)
  )
  hotel.save! if hotel.changed?
  puts "  ✓ #{hotel.new_record? ? '创建' : '更新'}宠物友好酒店: #{data[:name]}"
end

# ========== 10. 补充预算型酒店数据（多个验证器需要：价格200-400元） ==========
puts "\n=== 补充预算型酒店数据 ==="

[
  { name: '北京快捷连锁酒店', city: '北京', address: '海淀区中关村大街', price: 280, rating: 3.8 },
  { name: '上海经济型商务酒店', city: '上海', address: '静安区南京西路', price: 320, rating: 3.9 },
  { name: '广州火车站快捷酒店', city: '广州', address: '越秀区环市路', price: 260, rating: 3.7 },
  { name: '深圳宝安机场酒店', city: '深圳', address: '宝安区机场路', price: 300, rating: 3.8 },
  { name: '成都春熙路经济酒店', city: '成都', address: '锦江区春熙路', price: 250, rating: 3.6 },
  { name: '杭州西湖经济酒店', city: '杭州', address: '西湖区文三路', price: 290, rating: 3.7 }
].each do |data|
  hotel = Hotel.find_or_initialize_by(name: data[:name], data_version: '0')
  hotel.assign_attributes(
    city: data[:city],
    address: data[:address],
    price: data[:price],
    rating: data[:rating],
    facilities: 'WiFi, 早餐',
    image_url: ImageSeedHelper.random_image_from_category(:hotels)
  )
  hotel.save! if hotel.changed?
  puts "  ✓ #{hotel.new_record? ? '创建' : '更新'}预算酒店: #{data[:name]} (#{data[:price]}元)"
end

# ========== 11. 为现有酒店确保房型数据（V240等需要） ==========
puts "\n=== 确保酒店房型数据存在 ==="

# 获取所有基准数据酒店（data_version = '0'）
all_hotels = Hotel.where(data_version: '0').to_a
puts "找到 #{all_hotels.size} 个基准酒店"

created_count = 0
all_hotels.each do |hotel|
  # 为每个酒店创建3种房型（如果不存在）
  [
    { type: '标准双床房', price: hotel.price, bed_type: '双床', max_guests: 2, area: 25 },
    { type: '豪华大床房', price: (hotel.price * 1.5).round, bed_type: '大床', max_guests: 2, area: 35 },
    { type: '行政套房', price: (hotel.price * 2).round, bed_type: '双床+沙发床', max_guests: 4, area: 50 }
  ].each do |room_data|
    room = HotelRoom.find_or_initialize_by(
      hotel_id: hotel.id,
      room_type: room_data[:type],
      data_version: '0'
    )
    
    if room.new_record?
      room.assign_attributes(
        price: room_data[:price],
        original_price: (room_data[:price] * 1.2).round,
        bed_type: room_data[:bed_type],
        max_guests: room_data[:max_guests],
        area: room_data[:area],
        has_window: true,
        available_rooms: 10,
        room_category: 'overnight'
      )
      room.save!
      created_count += 1
    end
  end
end

puts "  ✓ 已为酒店添加/更新 #{created_count} 个房型数据"

# ========== 12. 补充预算型火车数据（多个预算验证器需要：价格100-300元） ==========
puts "\n=== 补充预算型火车数据 ==="

[
  { train_number: 'K601', departure_city: '北京', arrival_city: '石家庄', departure_station: '北京西站', arrival_station: '石家庄站', time: '08:00', duration: 180, price: 85 },
  { train_number: 'K602', departure_city: '上海', arrival_city: '苏州', departure_station: '上海站', arrival_station: '苏州站', time: '09:00', duration: 60, price: 45 },
  { train_number: 'K603', departure_city: '广州', arrival_city: '东莞', departure_station: '广州东站', arrival_station: '东莞站', time: '10:00', duration: 90, price: 55 },
  { train_number: 'K604', departure_city: '成都', arrival_city: '绵阳', departure_station: '成都站', arrival_station: '绵阳站', time: '11:00', duration: 120, price: 65 }
].each do |data|
  train = Train.find_or_initialize_by(train_number: data[:train_number], data_version: '0')
  train.assign_attributes(
    departure_city: data[:departure_city],
    arrival_city: data[:arrival_city],
    departure_station: data[:departure_station],
    arrival_station: data[:arrival_station],
    departure_time: Time.zone.parse("#{Date.today + 1.day} #{data[:time]}"),
    arrival_time: Time.zone.parse("#{Date.today + 1.day} #{data[:time]}") + data[:duration].minutes,
    duration: data[:duration],
    price_second_class: data[:price],
    price_first_class: (data[:price] * 1.5).round(1),
    price_business_class: (data[:price] * 2.5).round(1),
    available_seats: 100
  )
  train.save! if train.changed?
  puts "  ✓ #{train.new_record? ? '创建' : '更新'}预算火车: #{data[:train_number]} (#{data[:price]}元)"
end

puts "\n✅ Phase 2 数据包加载完成！"
puts "   - 早班车: 4条线路"
puts "   - 过夜卧铺: 4条线路（含北京→西安 K819）"
puts "   - 短途航班: 3个航班"
puts "   - 国际商务舱: 2个航班（上海/北京→纽约）"
puts "   - 国内商务舱: 3个航班"
puts "   - 支持改签: 2个航班"
puts "   - 宽体机: 3个航班（含北京→洛杉矶 CA987）"
puts "   - 中高端酒店: 7家"
puts "   - 宠物友好酒店: 3家（含成都宠物友好酒店）"
puts "   - 预算酒店: 6家"
puts "   - 酒店房型: 为所有酒店补充3种房型"
puts "   - 预算火车: 4条线路"
