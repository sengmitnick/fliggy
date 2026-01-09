# 清理现有数据
BusTicket.destroy_all

puts "🚌 创建汽车票数据..."

# 热门路线数据
routes = [
  # 深圳 -> 广州
  {
    origin: "深圳", 
    destination: "广州",
    stations: [
      { dep: "大剧院地铁站E口", arr: "珠江新城地铁站", desc: "途经4站" },
      { dep: "大剧院地铁站E出口（直行20米公交站）", arr: "珠江新城地铁站", desc: "途经4站" },
      { dep: "宝安汽车站", arr: "广州燕塘地铁站", desc: "普通大巴" },
      { dep: "深圳宝安汽车站", arr: "广州(东站)", desc: "约155公里 普通大巴" },
      { dep: "宝安汽车站", arr: "广州白云火车站", desc: "约135公里 普通大巴" },
      { dep: "深圳公明汽车站", arr: "广州天河-燕塘站", desc: "直达" },
      { dep: "深圳湾口岸", arr: "海珠广场站F口左前方100米", desc: "直达" },
      { dep: "深圳市流塘招呼站", arr: "燕塘地铁站C口对面", desc: "快线" },
      { dep: "西乡路口①公交站前面20米", arr: "广州(南沙)", desc: "跨区线" },
      { dep: "深圳宝安汽车站", arr: "黄埔", desc: "直达" },
      { dep: "深圳北站", arr: "双岗地铁站（黄埔区13号线）", desc: "城际快线" },
      { dep: "福田汽车站", arr: "越秀公园地铁站", desc: "市区直达" }
    ]
  },
  # 北京 -> 天津
  {
    origin: "北京",
    destination: "天津",
    stations: [
      { dep: "北京六里桥长途汽车站", arr: "天津客运西站", desc: "直达快线" },
      { dep: "北京木樨园长途汽车站", arr: "天津客运南站", desc: "舒适大巴" },
      { dep: "北京四惠长途汽车站", arr: "天津客运东站", desc: "豪华大巴" },
      { dep: "北京赵公口长途汽车站", arr: "天津滨海国际机场", desc: "机场专线" }
    ]
  },
  # 上海 -> 杭州
  {
    origin: "上海",
    destination: "杭州",
    stations: [
      { dep: "上海汽车客运总站", arr: "杭州客运中心站", desc: "高速直达" },
      { dep: "上海南站长途汽车站", arr: "杭州汽车南站", desc: "快速班线" },
      { dep: "上海虹桥汽车站", arr: "杭州汽车西站", desc: "商务班车" },
      { dep: "上海浦东机场", arr: "杭州萧山国际机场", desc: "机场专线" }
    ]
  }
]

# 时间段
time_slots = [
  "06:00", "06:30", "07:00", "07:30", "08:00", "08:30",
  "09:00", "09:30", "10:00", "10:30", "11:00", "11:30",
  "12:00", "12:30", "13:00", "13:30", "14:00", "14:30",
  "15:00", "15:30", "16:00", "16:30", "17:00", "17:30",
  "18:00", "18:30", "19:00", "19:30", "20:00", "20:30"
]

# 价格范围
price_ranges = {
  "深圳-广州" => (33..55),
  "北京-天津" => (50..80),
  "上海-杭州" => (55..90)
}

# 座位类型
seat_types = ["普通座", "商务座", "豪华座"]

# 为每条路线生成班次
routes.each do |route|
  route_key = "#{route[:origin]}-#{route[:destination]}"
  price_range = price_ranges[route_key] || (30..60)
  
  # 为未来7天生成班次
  (0..6).each do |day_offset|
    date = Date.today + day_offset.days
    
    route[:stations].each_with_index do |station, idx|
      # 每个站点随机选择几个时间段
      selected_times = time_slots.sample(rand(5..10))
      
      selected_times.each do |dep_time|
        # 计算到达时间（随机2-4小时后）
        dep = Time.parse(dep_time)
        duration_hours = rand(2.0..4.0)
        arr = dep + duration_hours.hours
        arr_time = arr.strftime("%H:%M")
        
        # 随机价格
        base_price = rand(price_range)
        # 时间段价格调整：高峰期(7-9, 17-19)贵10%
        hour = dep.hour
        if (7..9).include?(hour) || (17..19).include?(hour)
          base_price = (base_price * 1.1).round
        end
        
        BusTicket.create!(
          origin: route[:origin],
          destination: route[:destination],
          departure_date: date,
          departure_time: dep_time,
          arrival_time: arr_time,
          price: base_price,
          status: "available",
          seat_type: seat_types.sample,
          departure_station: station[:dep],
          arrival_station: station[:arr],
          route_description: station[:desc]
        )
      end
    end
  end
  
  puts "  ✓ 创建 #{route_key} 路线班次"
end

total_count = BusTicket.count
puts "✅ 成功创建 #{total_count} 条汽车票数据"
