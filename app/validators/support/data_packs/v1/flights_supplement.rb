# frozen_string_literal: true

# 航班数据补充包 - 补充缺失的航班路线
# 加载方式: rails runner "load Rails.root.join('app/validators/support/data_packs/v1/flights_supplement.rb')"

puts "🛫 补充航班数据..."

timestamp = Time.current
start_date = Date.current
end_date = start_date + 6.days

# 补充 深圳→杭州 航班（v029需要）
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  flights_sz_to_hz = [
    {
      departure_city: "深圳",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 8, min: 30),
      arrival_time: base_datetime.change(hour: 10, min: 45),
      departure_airport: "宝安T3",
      arrival_airport: "萧山T3",
      airline: "深圳航空",
      flight_number: "ZH#{9201 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 850.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 150,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "深圳",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 13, min: 0),
      arrival_time: base_datetime.change(hour: 15, min: 20),
      departure_airport: "宝安T3",
      arrival_airport: "萧山T3",
      airline: "东方航空",
      flight_number: "MU#{5701 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 920.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 120,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "深圳",
      destination_city: "杭州",
      departure_time: base_datetime.change(hour: 17, min: 30),
      arrival_time: base_datetime.change(hour: 19, min: 50),
      departure_airport: "宝安T3",
      arrival_airport: "萧山T3",
      airline: "厦门航空",
      flight_number: "MF#{8301 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 880.0,
      discount_price: 30.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_sz_to_hz)
end

Flight.insert_all(all_flights) if all_flights.any?
puts "  ✓ 已补充深圳→杭州航班: #{all_flights.count} 条"

# 补充 杭州→深圳 经济舱航班（v031需要）
all_flights = []

(start_date..end_date).each do |date|
  base_datetime = date.to_time.in_time_zone
  day_suffix = (date - Date.current).to_i
  
  flights_hz_to_sz = [
    {
      departure_city: "杭州",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 7, min: 45),
      arrival_time: base_datetime.change(hour: 10, min: 10),
      departure_airport: "萧山T3",
      arrival_airport: "宝安T3",
      airline: "春秋航空",
      flight_number: "9C#{8901 + day_suffix}",
      aircraft_type: "空客320(中)",
      price: 650.0,
      discount_price: 0.0,
      seat_class: "economy",
      available_seats: 180,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "杭州",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 11, min: 30),
      arrival_time: base_datetime.change(hour: 14, min: 0),
      departure_airport: "萧山T3",
      arrival_airport: "宝安T3",
      airline: "吉祥航空",
      flight_number: "HO#{1501 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 720.0,
      discount_price: 20.0,
      seat_class: "economy",
      available_seats: 150,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "杭州",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 15, min: 0),
      arrival_time: base_datetime.change(hour: 17, min: 30),
      departure_airport: "萧山T3",
      arrival_airport: "宝安T3",
      airline: "南方航空",
      flight_number: "CZ#{3601 + day_suffix}",
      aircraft_type: "空客321(中)",
      price: 800.0,
      discount_price: 50.0,
      seat_class: "economy",
      available_seats: 120,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    },
    {
      departure_city: "杭州",
      destination_city: "深圳",
      departure_time: base_datetime.change(hour: 19, min: 15),
      arrival_time: base_datetime.change(hour: 21, min: 45),
      departure_airport: "萧山T3",
      arrival_airport: "宝安T3",
      airline: "东方航空",
      flight_number: "MU#{5801 + day_suffix}",
      aircraft_type: "波音737(中)",
      price: 780.0,
      discount_price: 30.0,
      seat_class: "economy",
      available_seats: 100,
      flight_date: date,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  ]
  
  all_flights.concat(flights_hz_to_sz)
end

Flight.insert_all(all_flights) if all_flights.any?
puts "  ✓ 已补充杭州→深圳经济舱航班: #{all_flights.count} 条"

puts "✓ flights_supplement 数据包加载完成"
