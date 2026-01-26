# frozen_string_literal: true

# trains_v1 数据包
# 用于火车票验证任务
#
# 数据说明：
# - 上海→杭州：高铁密集，每天8-10个车次（G/D/C不同类型）
# - 北京→天津：价格区间大，每天6-8个车次
# - 生成未来7天的火车票数据
# - 不使用显式 ID，让数据库自动生成

puts "正在加载 trains_v1 数据包..."

# ==================== 动态日期设置 ====================
# 生成未来7天的火车票数据（从明天开始）
start_date = Date.current + 1.day
end_date = start_date + 6.days

puts "  火车票日期范围: #{start_date} 至 #{end_date} (共7天)"

# ==================== 火车票数据 ====================
all_trains = []
timestamp = Time.current

# 路线1: 上海→杭州（高铁密集，车次多）
# 这条路线主要测试"最早"概念（时间排序）
(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i  # 用于生成唯一车次号
  
  # 生成8个车次，覆盖早中晚时段
  trains_sh_to_hz = [
    # 早班车（6:00-9:00）- 测试"最早"
    {
      departure_city: "上海",
      arrival_city: "杭州",
      departure_time: base_datetime.change(hour: 6, min: 15),
      arrival_time: base_datetime.change(hour: 7, min: 25),
      train_number: "G#{7301 + day_suffix}",
      duration: 70,
      price_second_class: 73.0,
      price_first_class: 117.0,
      price_business_class: 219.0,
      available_seats: 150,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      arrival_city: "杭州",
      departure_time: base_datetime.change(hour: 7, min: 0),
      arrival_time: base_datetime.change(hour: 8, min: 8),
      train_number: "D#{3101 + day_suffix}",
      duration: 68,
      price_second_class: 49.0,
      price_first_class: 79.0,
      price_business_class: 147.0,
      available_seats: 200,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      arrival_city: "杭州",
      departure_time: base_datetime.change(hour: 8, min: 30),
      arrival_time: base_datetime.change(hour: 9, min: 35),
      train_number: "G#{7303 + day_suffix}",
      duration: 65,
      price_second_class: 73.0,
      price_first_class: 117.0,
      price_business_class: 219.0,
      available_seats: 180,
      created_at: timestamp,
      updated_at: timestamp
    },
    # 中间车次（9:00-15:00）
    {
      departure_city: "上海",
      arrival_city: "杭州",
      departure_time: base_datetime.change(hour: 10, min: 15),
      arrival_time: base_datetime.change(hour: 11, min: 22),
      train_number: "D#{3103 + day_suffix}",
      duration: 67,
      price_second_class: 49.0,
      price_first_class: 79.0,
      price_business_class: 147.0,
      available_seats: 220,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      arrival_city: "杭州",
      departure_time: base_datetime.change(hour: 12, min: 0),
      arrival_time: base_datetime.change(hour: 13, min: 10),
      train_number: "G#{7305 + day_suffix}",
      duration: 70,
      price_second_class: 73.0,
      price_first_class: 117.0,
      price_business_class: 219.0,
      available_seats: 160,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      arrival_city: "杭州",
      departure_time: base_datetime.change(hour: 14, min: 30),
      arrival_time: base_datetime.change(hour: 15, min: 38),
      train_number: "D#{3105 + day_suffix}",
      duration: 68,
      price_second_class: 49.0,
      price_first_class: 79.0,
      price_business_class: 147.0,
      available_seats: 190,
      created_at: timestamp,
      updated_at: timestamp
    },
    # 晚班车（15:00-22:00）
    {
      departure_city: "上海",
      arrival_city: "杭州",
      departure_time: base_datetime.change(hour: 17, min: 0),
      arrival_time: base_datetime.change(hour: 18, min: 5),
      train_number: "G#{7307 + day_suffix}",
      duration: 65,
      price_second_class: 73.0,
      price_first_class: 117.0,
      price_business_class: 219.0,
      available_seats: 170,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "上海",
      arrival_city: "杭州",
      departure_time: base_datetime.change(hour: 19, min: 30),
      arrival_time: base_datetime.change(hour: 20, min: 40),
      train_number: "D#{3107 + day_suffix}",
      duration: 70,
      price_second_class: 49.0,
      price_first_class: 79.0,
      price_business_class: 147.0,
      available_seats: 210,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_trains.concat(trains_sh_to_hz)
end

# 批量插入上海→杭州火车票
Train.insert_all(all_trains)
puts "  ✓ 已插入上海→杭州车次: #{all_trains.count} 条"

# 路线2: 北京→天津（价格区间大，不同座位类型价格差异明显）
# 这条路线主要测试价格对比（商务座可能是二等座的3倍）
all_trains = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  # 生成6个车次，价格差异明显
  trains_bj_to_tj = [
    # 经济型动车
    {
      departure_city: "北京",
      arrival_city: "天津",
      departure_time: base_datetime.change(hour: 7, min: 0),
      arrival_time: base_datetime.change(hour: 7, min: 33),
      train_number: "C#{2001 + day_suffix}",
      duration: 33,
      price_second_class: 54.5,  # 最便宜的二等座
      price_first_class: 65.5,
      price_business_class: 103.0,
      available_seats: 180,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      arrival_city: "天津",
      departure_time: base_datetime.change(hour: 8, min: 30),
      arrival_time: base_datetime.change(hour: 9, min: 5),
      train_number: "C#{2003 + day_suffix}",
      duration: 35,
      price_second_class: 54.5,
      price_first_class: 65.5,
      price_business_class: 103.0,
      available_seats: 200,
      created_at: timestamp,
      updated_at: timestamp
    },
    # 高速列车（价格略高）
    {
      departure_city: "北京",
      arrival_city: "天津",
      departure_time: base_datetime.change(hour: 10, min: 0),
      arrival_time: base_datetime.change(hour: 10, min: 30),
      train_number: "G#{1 + day_suffix}",
      duration: 30,
      price_second_class: 99.0,
      price_first_class: 159.0,
      price_business_class: 309.0,  # 商务座是二等座的3倍
      available_seats: 150,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "北京",
      arrival_city: "天津",
      departure_time: base_datetime.change(hour: 12, min: 30),
      arrival_time: base_datetime.change(hour: 13, min: 0),
      train_number: "G#{3 + day_suffix}",
      duration: 30,
      price_second_class: 99.0,
      price_first_class: 159.0,
      price_business_class: 309.0,
      available_seats: 160,
      created_at: timestamp,
      updated_at: timestamp
    },
    # 下午车次
    {
      departure_city: "北京",
      arrival_city: "天津",
      departure_time: base_datetime.change(hour: 15, min: 0),
      arrival_time: base_datetime.change(hour: 15, min: 35),
      train_number: "C#{2005 + day_suffix}",
      duration: 35,
      price_second_class: 54.5,
      price_first_class: 65.5,
      price_business_class: 103.0,
      available_seats: 190,
      created_at: timestamp,
      updated_at: timestamp
    },
    # 晚班车
    {
      departure_city: "北京",
      arrival_city: "天津",
      departure_time: base_datetime.change(hour: 18, min: 0),
      arrival_time: base_datetime.change(hour: 18, min: 32),
      train_number: "C#{2007 + day_suffix}",
      duration: 32,
      price_second_class: 54.5,
      price_first_class: 65.5,
      price_business_class: 103.0,
      available_seats: 170,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_trains.concat(trains_bj_to_tj)
end

# 批量插入北京→天津火车票
Train.insert_all(all_trains)
puts "  ✓ 已插入北京→天津车次: #{all_trains.count} 条"

# 路线3: 北京→上海（测试用例 v022）
all_trains = []
(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  trains_bj_to_sh = [
    { departure_city: "北京", arrival_city: "上海", departure_time: base_datetime.change(hour: 7, min: 0), arrival_time: base_datetime.change(hour: 11, min: 30), train_number: "G#{101 + day_suffix}", duration: 270, price_second_class: 553.0, price_first_class: 933.0, price_business_class: 1748.0, available_seats: 150, data_version: 0, created_at: timestamp, updated_at: timestamp },
    { departure_city: "北京", arrival_city: "上海", departure_time: base_datetime.change(hour: 9, min: 0), arrival_time: base_datetime.change(hour: 13, min: 28), train_number: "G#{103 + day_suffix}", duration: 268, price_second_class: 553.0, price_first_class: 933.0, price_business_class: 1748.0, available_seats: 180, data_version: 0, created_at: timestamp, updated_at: timestamp },
    { departure_city: "北京", arrival_city: "上海", departure_time: base_datetime.change(hour: 14, min: 0), arrival_time: base_datetime.change(hour: 18, min: 30), train_number: "G#{107 + day_suffix}", duration: 270, price_second_class: 553.0, price_first_class: 933.0, price_business_class: 1748.0, available_seats: 170, data_version: 0, created_at: timestamp, updated_at: timestamp }
  ]
  all_trains.concat(trains_bj_to_sh)
end
Train.insert_all(all_trains)
puts "  ✓ 已插入北京→上海车次: #{all_trains.count} 条"

# 路线4: 上海→深圳（测试用例 v023）
all_trains = []
(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  trains_sh_to_sz = [
    { departure_city: "上海", arrival_city: "深圳", departure_time: base_datetime.change(hour: 8, min: 0), arrival_time: base_datetime.change(hour: 16, min: 30), train_number: "G#{1301 + day_suffix}", duration: 510, price_second_class: 595.0, price_first_class: 946.0, price_business_class: 1774.0, available_seats: 150, data_version: 0, created_at: timestamp, updated_at: timestamp },
    { departure_city: "上海", arrival_city: "深圳", departure_time: base_datetime.change(hour: 10, min: 0), arrival_time: base_datetime.change(hour: 18, min: 30), train_number: "G#{1303 + day_suffix}", duration: 510, price_second_class: 595.0, price_first_class: 946.0, price_business_class: 1774.0, available_seats: 180, data_version: 0, created_at: timestamp, updated_at: timestamp },
    { departure_city: "上海", arrival_city: "深圳", departure_time: base_datetime.change(hour: 15, min: 30), arrival_time: base_datetime.change(hour: 23, min: 59), train_number: "D#{701 + day_suffix}", duration: 509, price_second_class: 465.0, price_first_class: 743.0, price_business_class: 1395.0, available_seats: 200, data_version: 0, created_at: timestamp, updated_at: timestamp }
  ]
  all_trains.concat(trains_sh_to_sz)
end
Train.insert_all(all_trains)
puts "  ✓ 已插入上海→深圳车次: #{all_trains.count} 条"

# 路线5: 杭州→北京（测试用例 v024）
all_trains = []
(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  trains_hz_to_bj = [
    { departure_city: "杭州", arrival_city: "北京", departure_time: base_datetime.change(hour: 7, min: 0), arrival_time: base_datetime.change(hour: 11, min: 55), train_number: "G#{19 + day_suffix}", duration: 295, price_second_class: 538.0, price_first_class: 907.0, price_business_class: 1701.0, available_seats: 150, data_version: 0, created_at: timestamp, updated_at: timestamp },
    { departure_city: "杭州", arrival_city: "北京", departure_time: base_datetime.change(hour: 12, min: 0), arrival_time: base_datetime.change(hour: 17, min: 5), train_number: "G#{23 + day_suffix}", duration: 305, price_second_class: 538.0, price_first_class: 907.0, price_business_class: 1701.0, available_seats: 160, data_version: 0, created_at: timestamp, updated_at: timestamp },
    { departure_city: "杭州", arrival_city: "北京", departure_time: base_datetime.change(hour: 19, min: 30), arrival_time: base_datetime.change(hour: 23, min: 59), train_number: "G#{29 + day_suffix}", duration: 269, price_second_class: 538.0, price_first_class: 907.0, price_business_class: 1701.0, available_seats: 200, data_version: 0, created_at: timestamp, updated_at: timestamp }
  ]
  all_trains.concat(trains_hz_to_bj)
end
Train.insert_all(all_trains)
puts "  ✓ 已插入杭州→北京车次: #{all_trains.count} 条"

# 路线6: 深圳→广州（测试用例 v025）
all_trains = []
(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  trains_sz_to_gz = [
    { departure_city: "深圳", arrival_city: "广州", departure_time: base_datetime.change(hour: 7, min: 0), arrival_time: base_datetime.change(hour: 7, min: 35), train_number: "G#{6001 + day_suffix}", duration: 35, price_second_class: 75.0, price_first_class: 120.0, price_business_class: 225.0, available_seats: 150, data_version: 0, created_at: timestamp, updated_at: timestamp },
    { departure_city: "深圳", arrival_city: "广州", departure_time: base_datetime.change(hour: 10, min: 0), arrival_time: base_datetime.change(hour: 10, min: 45), train_number: "D#{2001 + day_suffix}", duration: 45, price_second_class: 60.0, price_first_class: 96.0, price_business_class: 180.0, available_seats: 200, data_version: 0, created_at: timestamp, updated_at: timestamp },
    { departure_city: "深圳", arrival_city: "广州", departure_time: base_datetime.change(hour: 14, min: 30), arrival_time: base_datetime.change(hour: 15, min: 12), train_number: "D#{2003 + day_suffix}", duration: 42, price_second_class: 60.0, price_first_class: 96.0, price_business_class: 180.0, available_seats: 190, data_version: 0, created_at: timestamp, updated_at: timestamp }
  ]
  all_trains.concat(trains_sz_to_gz)
end
Train.insert_all(all_trains)
puts "  ✓ 已插入深圳→广州车次: #{all_trains.count} 条"

# 路线7: 广州→上海（测试用例 v026）
all_trains = []
(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  trains_gz_to_sh = [
    { departure_city: "广州", arrival_city: "上海", departure_time: base_datetime.change(hour: 12, min: 30), arrival_time: base_datetime.change(hour: 20, min: 5), train_number: "D#{901 + day_suffix}", duration: 455, price_second_class: 563.0, price_first_class: 898.0, price_business_class: 1685.0, available_seats: 200, data_version: 0, created_at: timestamp, updated_at: timestamp },
    { departure_city: "广州", arrival_city: "上海", departure_time: base_datetime.change(hour: 16, min: 0), arrival_time: base_datetime.change(hour: 23, min: 35), train_number: "D#{903 + day_suffix}", duration: 455, price_second_class: 563.0, price_first_class: 898.0, price_business_class: 1685.0, available_seats: 190, data_version: 0, created_at: timestamp, updated_at: timestamp },
    { departure_city: "广州", arrival_city: "上海", departure_time: base_datetime.change(hour: 18, min: 30), arrival_time: base_datetime.change(hour: 23, min: 50), train_number: "D#{905 + day_suffix}", duration: 320, price_second_class: 563.0, price_first_class: 898.0, price_business_class: 1685.0, available_seats: 210, data_version: 0, created_at: timestamp, updated_at: timestamp }
  ]
  all_trains.concat(trains_gz_to_sh)
end
Train.insert_all(all_trains)
puts "  ✓ 已插入广州→上海车次: #{all_trains.count} 条"

# ==================== 为每趟车创建座位类型数据 ====================
puts "\n为所有车次创建座位类型数据..."
all_seats = []

Train.where(data_version: 0).find_each do |train|
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
puts "  ✓ 已创建座位类型数据: #{all_seats.count} 条"

# ==================== 为每趟车创建订票套餐 ====================
puts "\n为所有车次创建订票套餐..."
all_options = []

Train.where(data_version: 0).find_each do |train|
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
puts "  ✓ 已创建订票套餐: #{all_options.count} 条"

# 统计信息
total_trains = Train.where(data_version: 0).count
sh_to_hz_count = Train.where(data_version: 0, departure_city: "上海", arrival_city: "杭州").count
bj_to_tj_count = Train.where(data_version: 0, departure_city: "北京", arrival_city: "天津").count

puts "\n✓ trains_v1 数据包加载完成（共 #{total_trains} 个车次）"
puts "  - 上海→杭州: 每天8个车次，最低价 49元（共 #{sh_to_hz_count} 个）"
puts "  - 北京→天津: 每天6个车次，价格区间 54.5-309元（共 #{bj_to_tj_count} 个）"
