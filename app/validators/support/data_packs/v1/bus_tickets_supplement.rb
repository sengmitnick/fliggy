# frozen_string_literal: true

# 汽车票数据补充包 - 补充杭州→上海的晚班车
# 加载方式: rails runner "load Rails.root.join('app/validators/support/data_packs/v1/bus_tickets_supplement.rb')"


timestamp = Time.current

# 晚班车时间段（18:00之后）
evening_time_slots = [
  "18:00", "18:30", "19:00", "19:30", "20:00", "20:30", "21:00", "21:30"
]

# 杭州→上海的车站配置
stations = [
  { dep: "杭州汽车客运中心站", arr: "上海汽车客运总站", desc: "高速直达" },
  { dep: "杭州汽车南站", arr: "上海南站长途汽车站", desc: "快速班线" },
  { dep: "杭州汽车西站", arr: "上海虹桥汽车站", desc: "商务班车" },
  { dep: "杭州萧山国际机场", arr: "上海浦东机场", desc: "机场专线" }
]

# 价格范围
price_range = (55..90)

# 座位类型
seat_types = ["普通座", "商务座", "豪华座"]

# 批量准备晚班车数据
all_tickets_data = []

# 为未来7天生成晚班车
(0..6).each do |day_offset|
  date = Date.today + day_offset.days
  
  stations.each do |station|
    # 每个站点选择几个晚班时间段
    selected_times = evening_time_slots.sample(rand(4..6))
    
    selected_times.each do |dep_time|
      # 计算到达时间（随机2-3小时后）
      dep = Time.parse(dep_time)
      duration_hours = rand(2.0..3.0)
      arr = dep + duration_hours.hours
      arr_time = if arr.hour >= 24
        (arr - 1.day).strftime("%H:%M")
      else
        arr.strftime("%H:%M")
      end
      
      # 随机价格
      base_price = rand(price_range)
      # 晚班车价格稍贵5-10%
      base_price = (base_price * 1.08).round
      
      all_tickets_data << {
        origin: "杭州",
        destination: "上海",
        departure_date: date,
        departure_time: dep_time,
        arrival_time: arr_time,
        price: base_price,
        status: "available",
        seat_type: seat_types.sample,
        departure_station: station[:dep],
        arrival_station: station[:arr],
        route_description: station[:desc],
        data_version: 0,
        created_at: timestamp,
        updated_at: timestamp
      }
    end
  end
end

# 批量插入所有数据
if all_tickets_data.any?
  BusTicket.insert_all(all_tickets_data)
else
  puts "  ⚠️ 没有数据需要创建"
end

