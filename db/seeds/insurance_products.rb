# Insurance Products Seed Data
# This creates insurance products that map to existing INSURANCE_OPTIONS in InsuranceService

puts "Creating insurance products..."

# Standard comprehensive insurance (for flights)
InsuranceProduct.find_or_create_by!(code: 'FLIGHT-STD-001') do |p|
  p.name = '优享保障'
  p.company = '中国人保PICC'
  p.product_type = 'domestic'
  p.coverage_details = {
    accident: 7_000_000,
    medical: 50_000,
    trip_delay: 500,
    baggage_loss: 3_000
  }
  p.price_per_day = 50
  p.min_days = 1
  p.max_days = 30
  p.scenes = ['飞机', '高铁', '自驾']
  p.highlights = ['意外身故/伤残700万', '意外医疗5万', '航班延误500元/4小时']
  p.official_select = true
  p.featured = true
  p.available_for_embedding = true
  p.embedding_code = 'standard'
  p.image_url = 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800'
  p.active = true
  p.sort_order = 1
end

# Premium comprehensive insurance (for flights)
InsuranceProduct.find_or_create_by!(code: 'FLIGHT-PRM-001') do |p|
  p.name = '至尊保障'
  p.company = '中国人保PICC'
  p.product_type = 'domestic'
  p.coverage_details = {
    accident: 10_000_000,
    medical: 100_000,
    trip_delay: 1_000,
    baggage_loss: 5_000,
    trip_cancellation: 10_000
  }
  p.price_per_day = 66
  p.min_days = 1
  p.max_days = 30
  p.scenes = ['飞机', '高铁', '自驾', '轮船']
  p.highlights = ['意外身故/伤残1000万', '意外医疗10万', '航班延误1000元/4小时', '行程取消保障1万']
  p.official_select = true
  p.featured = true
  p.available_for_embedding = true
  p.embedding_code = 'premium'
  p.image_url = 'https://images.unsplash.com/photo-1464037866556-6812c9d1c72e?w=800'
  p.active = true
  p.sort_order = 2
end

# Travel disruption insurance (for hotels)
InsuranceProduct.find_or_create_by!(code: 'HOTEL-DIS-001') do |p|
  p.name = '行程阻碍险'
  p.company = '太平洋保险'
  p.product_type = 'domestic'
  p.coverage_details = {
    hospitalization: 300,
    transportation: 600,
    weather_disruption: 1_000
  }
  p.price_per_day = 25
  p.min_days = 1
  p.max_days = 60
  p.scenes = ['酒店', '民宿']
  p.highlights = ['住院津贴300元/天', '交通补贴600元', '极端天气保障']
  p.official_select = false
  p.featured = false
  p.available_for_embedding = true
  p.embedding_code = 'travel_disruption'
  p.image_url = 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800'
  p.active = true
  p.sort_order = 3
end

# Accident and medical insurance (for hotels)
InsuranceProduct.find_or_create_by!(code: 'HOTEL-MED-001') do |p|
  p.name = '无忧保(意外+传染病)'
  p.company = '平安保险'
  p.product_type = 'domestic'
  p.coverage_details = {
    accident: 500_000,
    acute_disease: 50_000,
    hospitalization: 300,
    transportation: 600
  }
  p.price_per_day = 18
  p.min_days = 1
  p.max_days = 90
  p.scenes = ['酒店', '民宿', '度假村']
  p.highlights = ['意外保障50万', '急性病医疗5万', '住院津贴300元/天']
  p.official_select = false
  p.featured = false
  p.available_for_embedding = true
  p.embedding_code = 'accident_medical'
  p.image_url = 'https://images.unsplash.com/photo-1584820927498-cfe5211fd8bf?w=800'
  p.active = true
  p.sort_order = 4
end

# Hotel cancellation insurance
InsuranceProduct.find_or_create_by!(code: 'HOTEL-CXL-001') do |p|
  p.name = '酒店无理由取消险'
  p.company = '众安保险'
  p.product_type = 'domestic'
  p.coverage_details = {
    cancellation_refund: 100,
    max_refund: 10_000
  }
  p.price_per_day = 16
  p.min_days = 1
  p.max_days = 30
  p.scenes = ['酒店', '民宿']
  p.highlights = ['未入住可退100%房损', '最高赔付1万元']
  p.official_select = false
  p.featured = false
  p.available_for_embedding = true
  p.embedding_code = 'hotel_cancellation'
  p.image_url = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800'
  p.active = true
  p.sort_order = 5
end

# Additional standalone insurance products (not for embedding)

# International travel insurance - Premium
InsuranceProduct.find_or_create_by!(code: 'INTL-PRM-001') do |p|
  p.name = '境外旅游保险-尊享计划'
  p.company = '中国人保PICC'
  p.product_type = 'international'
  p.coverage_details = {
    accident: 50_000_000,
    medical: 500_000,
    emergency_evacuation: 1_000_000,
    trip_delay: 2_000,
    baggage_loss: 10_000,
    trip_cancellation: 50_000,
    personal_liability: 1_000_000
  }
  p.price_per_day = 88
  p.min_days = 3
  p.max_days = 90
  p.scenes = ['出境游', '商务出行', '留学']
  p.highlights = ['意外身故/伤残5000万', '医疗费用50万', '紧急救援100万', '个人责任100万']
  p.official_select = true
  p.featured = true
  p.available_for_embedding = false
  p.image_url = 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800'
  p.active = true
  p.sort_order = 10
end

# International travel insurance - Standard
InsuranceProduct.find_or_create_by!(code: 'INTL-STD-001') do |p|
  p.name = '境外旅游保险-标准计划'
  p.company = '中国人保PICC'
  p.product_type = 'international'
  p.coverage_details = {
    accident: 30_000_000,
    medical: 300_000,
    emergency_evacuation: 500_000,
    trip_delay: 1_000,
    baggage_loss: 5_000,
    trip_cancellation: 20_000
  }
  p.price_per_day = 58
  p.min_days = 3
  p.max_days = 90
  p.scenes = ['出境游', '商务出行']
  p.highlights = ['意外身故/伤残3000万', '医疗费用30万', '紧急救援50万']
  p.official_select = false
  p.featured = true
  p.available_for_embedding = false
  p.image_url = 'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?w=800'
  p.active = true
  p.sort_order = 11
end

# Transport insurance - Comprehensive
InsuranceProduct.find_or_create_by!(code: 'TRANS-COM-001') do |p|
  p.name = '交通工具综合险'
  p.company = '平安保险'
  p.product_type = 'transport'
  p.coverage_details = {
    accident: 2_000_000,
    medical: 50_000,
    trip_delay: 500,
    baggage_loss: 3_000
  }
  p.price_per_day = 35
  p.min_days = 1
  p.max_days = 180
  p.scenes = ['飞机', '高铁', '火车', '长途汽车', '轮船']
  p.highlights = ['意外身故/伤残200万', '意外医疗5万', '延误500元/4小时']
  p.official_select = false
  p.featured = true
  p.available_for_embedding = false
  p.image_url = 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=800'
  p.active = true
  p.sort_order = 20
end

# Domestic self-drive insurance
InsuranceProduct.find_or_create_by!(code: 'DRIVE-DOM-001') do |p|
  p.name = '国内自驾游保险'
  p.company = '太平洋保险'
  p.product_type = 'domestic'
  p.coverage_details = {
    accident: 1_000_000,
    medical: 100_000,
    car_damage: 50_000,
    roadside_assistance: 5
  }
  p.price_per_day = 42
  p.min_days = 1
  p.max_days = 30
  p.scenes = ['自驾', '租车']
  p.highlights = ['意外保障100万', '医疗费用10万', '车辆损失5万', '道路救援5次']
  p.official_select = false
  p.featured = false
  p.available_for_embedding = false
  p.image_url = 'https://images.unsplash.com/photo-1449965408869-eaa3f722e40d?w=800'
  p.active = true
  p.sort_order = 21
end

# Cruise travel insurance
InsuranceProduct.find_or_create_by!(code: 'CRUISE-001') do |p|
  p.name = '邮轮旅游保险'
  p.company = '众安保险'
  p.product_type = 'international'
  p.coverage_details = {
    accident: 5_000_000,
    medical: 200_000,
    trip_cancellation: 30_000,
    missed_connection: 5_000,
    baggage_delay: 2_000
  }
  p.price_per_day = 68
  p.min_days = 3
  p.max_days = 30
  p.scenes = ['邮轮', '游轮']
  p.highlights = ['意外保障500万', '医疗费用20万', '行程取消3万', '错过航班5000元']
  p.official_select = false
  p.featured = false
  p.available_for_embedding = false
  p.image_url = 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800'
  p.active = true
  p.sort_order = 22
end

puts "✅ Created #{InsuranceProduct.count} insurance products"
puts "   - Embeddable products: #{InsuranceProduct.embeddable.count}"
puts "   - Featured products: #{InsuranceProduct.featured.count}"
puts "   - Official select products: #{InsuranceProduct.official_select.count}"
