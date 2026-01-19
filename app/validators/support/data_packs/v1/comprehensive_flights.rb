# frozen_string_literal: true

# comprehensive_flights_v1 数据包
# 用于预生成热门城市之间的航班数据
#
# 数据说明：
# - 覆盖热门城市对：深圳↔北京、深圳↔上海、北京↔杭州、上海↔杭州等
# - 时间范围：未来61天（今天到今天+60天）
# - 每条航线每天：8-10个航班（由Flight.generate_for_route自动生成）
# - 每个航班：4个优惠套餐（超值精选/选座无忧/返现礼遇/家庭好选）
# - 自动往返覆盖：A→B和B→A都会生成
#
# 预计生成数据量：
# - 10条航线对（20条单向路线）× 61天 × 9个航班/天 ≈ 10,980个航班
# - 每个航班4个套餐 ≈ 43,920个FlightOffer记录

puts "正在加载 comprehensive_flights_v1 数据包..."
puts "  时间范围: #{Date.current} 到 #{Date.current + 60.days} (61天)"

# ==================== 配置 ====================
START_DATE = Date.current
END_DATE = Date.current + 60.days
DAYS_COUNT = 61

# ==================== 热门城市航线对 ====================
# 使用往返对的方式定义，确保双向覆盖
POPULAR_ROUTES = [
  # 一线城市之间
  ['深圳市', '北京市'],
  ['深圳市', '上海市'],
  ['北京市', '上海市'],
  ['北京', '杭州'],
  ['上海', '杭州'],
  ['深圳市', '杭州'],
  
  # 重要二线城市
  ['深圳市', '成都'],
  ['北京市', '成都'],
  ['上海', '成都'],
  ['杭州', '成都']
]

puts "  路线对数: #{POPULAR_ROUTES.count}"
puts "  单向路线数: #{POPULAR_ROUTES.count * 2}"

# ==================== 数据生成 ====================
generated_flights_count = 0
skipped_routes_count = 0
total_routes = POPULAR_ROUTES.count * 2 # 双向

POPULAR_ROUTES.each_with_index do |route_pair, index|
  departure_city = route_pair[0]
  destination_city = route_pair[1]
  
  # 双向生成：A→B 和 B→A
  [
    [departure_city, destination_city],
    [destination_city, departure_city]
  ].each do |departure, destination|
    puts "  正在处理: #{departure} → #{destination}"
    
    # 检查是否已有数据（避免重复生成）
    existing_count = Flight.by_route(departure, destination)
                          .where(flight_date: START_DATE..END_DATE)
                          .count
    
    if existing_count >= DAYS_COUNT * 5 # 如果已有数据（至少每天5个航班）
      puts "    ↳ 跳过（已有#{existing_count}个航班）"
      skipped_routes_count += 1
      next
    end
    
    # 为每一天生成航班
    route_flights_count = 0
    (START_DATE..END_DATE).each do |date|
      flights = Flight.generate_for_route(departure, destination, date)
      route_flights_count += flights.count
    end
    
    generated_flights_count += route_flights_count
    puts "    ↳ 生成 #{route_flights_count} 个航班"
  end
  
  # 每处理5对路线输出进度
  if (index + 1) % 5 == 0
    puts ""
    puts "  进度: #{index + 1}/#{POPULAR_ROUTES.count} 对 (#{(index + 1) * 2}/#{total_routes} 单向路线)"
    puts ""
  end
end

# ==================== 统计信息 ====================
puts ""
puts "✓ comprehensive_flights_v1 数据包加载完成"
puts ""
puts "  生成统计:"
puts "    - 新生成航班数: #{generated_flights_count}"
puts "    - 跳过路线数: #{skipped_routes_count}"
puts "    - 数据库总航班数: #{Flight.count}"
puts "    - 数据库总套餐数: #{FlightOffer.count}"
puts ""
puts "  覆盖情况:"
puts "    - 路线对数: #{POPULAR_ROUTES.count}"
puts "    - 单向路线数: #{total_routes}"
puts "    - 日期范围: #{START_DATE} ~ #{END_DATE}"
puts "    - 平均每条路线: #{generated_flights_count / [total_routes - skipped_routes_count, 1].max} 个航班" if generated_flights_count > 0
