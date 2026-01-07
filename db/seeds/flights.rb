puts "正在初始化机票数据..."

# 清理现有机票数据
Flight.destroy_all
FlightOffer.destroy_all

# 热门航线（双向）
popular_routes = [
  ['北京', '上海'],
  ['上海', '北京'],
  ['北京', '深圳'],
  ['深圳', '北京'],
  ['上海', '深圳'],
  ['深圳', '上海'],
  ['北京', '广州'],
  ['广州', '北京'],
  ['上海', '广州'],
  ['广州', '上海'],
  ['北京', '成都'],
  ['成都', '北京'],
  ['上海', '成都'],
  ['成都', '上海'],
  ['北京', '杭州'],
  ['杭州', '北京'],
  ['上海', '杭州'],
  ['杭州', '上海'],
  ['北京', '西安'],
  ['西安', '北京'],
  ['上海', '西安'],
  ['西安', '上海'],
  ['深圳', '成都'],
  ['成都', '深圳'],
  ['广州', '成都'],
  ['成都', '广州']
]

flights_created = 0

# 为每条热门航线生成未来7天的航班
(0..6).each do |day_offset|
  target_date = Date.today + day_offset.days
  
  popular_routes.each do |departure, arrival|
    generated = Flight.generate_for_route(departure, arrival, target_date)
    flights_created += generated.count
    print "."
  end
end

puts "\n✅ 预生成了 #{flights_created} 个航班 (#{popular_routes.count} 条热门航线，未来7天)"
puts "其他航线和日期将在管理后台手动生成或通过 Flight.generate_for_route 创建"
puts "机票数据初始化完成！"
