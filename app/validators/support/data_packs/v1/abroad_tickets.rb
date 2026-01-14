# Abroad Tickets Seed Data

puts "Creating abroad tickets..."

# Japan Train Tickets - Tokyo to Shin-Osaka Route
japan_routes = [
  { origin: "东京站", origin_en: "Tokyo Station", destination: "新大阪站", destination_en: "Shin-Osaka Station" },
  { origin: "东京站", origin_en: "Tokyo Station", destination: "京都站", destination_en: "Kyoto Station" },
  { origin: "大阪站", origin_en: "Osaka Station", destination: "广岛站", destination_en: "Hiroshima Station" },
  { origin: "东京站", origin_en: "Tokyo Station", destination: "名古屋站", destination_en: "Nagoya Station" },
  { origin: "札幌站", origin_en: "Sapporo Station", destination: "函馆站", destination_en: "Hakodate Station" },
  { origin: "东京站", origin_en: "Tokyo Station", destination: "仙台站", destination_en: "Sendai Station" },
  { origin: "福冈站", origin_en: "Fukuoka Station", destination: "熊本站", destination_en: "Kumamoto Station" }
]

# Time slots for trains
time_slots = [
  { start: "06:00", end: "07:00", price_multiplier: 0.9 },
  { start: "07:00", end: "08:00", price_multiplier: 1.0 },
  { start: "08:00", end: "09:00", price_multiplier: 1.0 },
  { start: "09:00", end: "10:00", price_multiplier: 1.0 },
  { start: "10:00", end: "11:00", price_multiplier: 1.0 },
  { start: "11:00", end: "12:00", price_multiplier: 1.0 },
  { start: "12:00", end: "13:00", price_multiplier: 1.0 },
  { start: "13:00", end: "14:00", price_multiplier: 1.0 },
  { start: "14:00", end: "15:00", price_multiplier: 1.0 },
  { start: "15:00", end: "16:00", price_multiplier: 1.0 },
  { start: "16:00", end: "17:00", price_multiplier: 1.1 },
  { start: "17:00", end: "18:00", price_multiplier: 1.1 },
  { start: "18:00", end: "19:00", price_multiplier: 1.2 }
]

# Generate tickets for next 30 days
base_date = Date.today
30.times do |day_offset|
  departure_date = base_date + day_offset.days
  
  japan_routes.each do |route|
    base_price = rand(500.0..1200.0).round(2)
    
    # Generate different time slots
    time_slots.sample(8).each do |slot|
      price = (base_price * slot[:price_multiplier]).round(2)
      
      AbroadTicket.create!(
        region: 'japan',
        ticket_type: 'train',
        origin: route[:origin],
        origin_en: route[:origin_en],
        destination: route[:destination],
        destination_en: route[:destination_en],
        departure_date: departure_date,
        time_slot_start: slot[:start],
        time_slot_end: slot[:end],
        price: price,
        seat_type: '新干线',
        status: 'available'
      )
    end
  end
end

# Europe Train Tickets
europe_routes = [
  { origin: "巴黎北站", origin_en: "Paris Nord", destination: "阿姆斯特丹中央车站", destination_en: "Amsterdam Centraal" },
  { origin: "慕尼黑火车总站", origin_en: "München Hbf", destination: "苏黎世火车站", destination_en: "Zürich HB" },
  { origin: "伦敦圣潘克拉斯站", origin_en: "London St Pancras", destination: "巴黎北站", destination_en: "Paris Nord" },
  { origin: "巴塞罗那桑茨车站", origin_en: "Barcelona Sants", destination: "马德里阿托查站", destination_en: "Madrid Atocha" },
  { origin: "罗马特米尼站", origin_en: "Roma Termini", destination: "米兰中央车站", destination_en: "Milano Centrale" }
]

30.times do |day_offset|
  departure_date = base_date + day_offset.days
  
  europe_routes.each do |route|
    base_price = rand(800.0..2000.0).round(2)
    
    time_slots.sample(6).each do |slot|
      price = (base_price * slot[:price_multiplier]).round(2)
      
      AbroadTicket.create!(
        region: 'europe',
        ticket_type: 'train',
        origin: route[:origin],
        origin_en: route[:origin_en],
        destination: route[:destination],
        destination_en: route[:destination_en],
        departure_date: departure_date,
        time_slot_start: slot[:start],
        time_slot_end: slot[:end],
        price: price,
        seat_type: '欧铁',
        status: 'available'
      )
    end
  end
end

puts "Created #{AbroadTicket.count} abroad tickets"
