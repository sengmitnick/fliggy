# frozen_string_literal: true

# insurances_v1 数据包
# 保险产品数据 + 城市关联配置
#
# 用途：
# - 保险产品展示和购买
# - 支持不同城市差异化定价
# - 支持区域限制销售
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 insurances_v1 数据包..."

# ==================== 保险产品数据 ====================

companies = ['平安保险', '中国人保', '太平洋保险', '众安保险', '华泰财险', '京东安联', '美亚保险', '安盛保险']
scenes_domestic = ['亲子游', '短途旅行', '户外运动', '自驾游', '高原游', '海岛游', '潜水', '滑雪', '携宠出行', '携宠旅游']
scenes_international = ['出境游', '东南亚旅行', '商务出行', '可办申根签', '家庭保障', '可选全年计划']
scenes_transport = ['交通综合', '航空保障', '家庭保障', '航班延误保障', '航班取消保障']

insurance_products_data = []

# 境内旅行保险（domestic）- 8个产品
[
  { name: '境内旅游险-基础款', code: 'PA-DOM-001', accident: 500000, medical: 50000, cancellation: 10000, price: 5.0, scenes: ['亲子游', '短途旅行', '户外运动'] },
  { name: '境内旅游险-尊享款', code: 'PICC-DOM-001', accident: 1000000, medical: 100000, cancellation: 20000, price: 10.0, scenes: ['自驾游', '户外运动', '高原游'] },
  { name: '海岛度假保险', code: 'CPIC-DOM-001', accident: 800000, medical: 80000, cancellation: 15000, price: 12.0, scenes: ['海岛游', '亲子游', '潜水'], min_days: 3, max_days: 15 },
  { name: '携宠旅行保险', code: 'ZA-DOM-001', accident: 500000, medical: 50000, cancellation: 0, price: 15.0, scenes: ['携宠出行', '携宠旅游', '自驾游'], pet_liability: 10000 },
  { name: '滑雪运动保险', code: 'HT-DOM-001', accident: 1000000, medical: 150000, cancellation: 0, price: 25.0, scenes: ['滑雪', '户外运动', '高原游'], sports_injury: 100000, min_days: 1, max_days: 15 }
].each_with_index do |config, i|
  # 基础产品
  insurance_products_data << {
    name: config[:name],
    company: companies[i % companies.size],
    product_type: 'domestic',
    code: config[:code],
    coverage_details: {
      accident: config[:accident],
      medical: config[:medical],
      trip_cancellation: config[:cancellation],
      pet_liability: config[:pet_liability],
      sports_injury: config[:sports_injury]
    }.compact,
    price_per_day: config[:price],
    min_days: config[:min_days] || 1,
    max_days: config[:max_days] || 30,
    scenes: config[:scenes],
    highlights: ["意外身故#{config[:accident]/10000}万", "意外医疗#{config[:medical]/10000}万"],
    official_select: i < 2,
    featured: true,
    active: true,
    available_for_embedding: false,
    sort_order: 100 - i * 5,
    image_url: 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800'
  }
  
  # 额外生成3个变种产品
  if i < 3
    insurance_products_data << {
      name: "#{config[:name].split('-')[0]}-进阶款",
      company: companies[(i + 3) % companies.size],
      product_type: 'domestic',
      code: "#{config[:code].split('-')[0]}-DOM-00#{i+6}",
      coverage_details: {
        accident: config[:accident] * 1.5,
        medical: config[:medical] * 1.5,
        trip_cancellation: config[:cancellation] * 1.5
      },
      price_per_day: config[:price] * 1.5,
      min_days: config[:min_days] || 1,
      max_days: (config[:max_days] || 30) * 2,
      scenes: config[:scenes],
      highlights: ["意外身故#{(config[:accident]*1.5/10000).to_i}万", "意外医疗#{(config[:medical]*1.5/10000).to_i}万"],
      official_select: false,
      featured: true,
      active: true,
      available_for_embedding: false,
      sort_order: 65 - i * 5,
      image_url: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?w=800'
    }
  end
end

# 境外/港澳台旅行保险（international）- 8个产品
[
  { name: '境外旅游险-亚洲版', code: 'JD-INT-001', accident: 1000000, medical: 300000, price: 25.0, days: [3, 90] },
  { name: '境外旅游险-全球版', code: 'PICC-INT-001', accident: 2000000, medical: 500000, price: 45.0, days: [3, 180] },
  { name: '境外家庭保险', code: 'AIG-INT-001', accident: 1500000, medical: 400000, price: 35.0, days: [3, 60], scenes_extra: ['亲子游', '家庭保障'] },
  { name: '全年境外旅行计划', code: 'AXA-INT-001', accident: 3000000, medical: 1000000, price: 8.0, days: [365, 365], scenes_extra: ['可选全年计划'] }
].each_with_index do |config, i|
  # 基础产品
  scenes_base = ['出境游', '商务出行']
  scenes_base += config[:scenes_extra] if config[:scenes_extra]
  scenes_base += ['东南亚旅行'] if config[:code].include?('JD')
  scenes_base += ['可办申根签'] if config[:code].include?('PICC')
  
  insurance_products_data << {
    name: config[:name],
    company: companies[(i + 5) % companies.size],
    product_type: 'international',
    code: config[:code],
    coverage_details: {
      accident: config[:accident],
      medical: config[:medical],
      trip_cancellation: config[:accident] * 0.03
    },
    price_per_day: config[:price],
    min_days: config[:days][0],
    max_days: config[:days][1],
    scenes: scenes_base,
    highlights: ["境外医疗#{config[:medical]/10000}万", '24小时紧急救援'],
    official_select: i < 2,
    featured: i < 3,
    active: true,
    available_for_embedding: false,
    sort_order: 60 - i * 5,
    image_url: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=800'
  }
  
  # 额外生成4个变种产品
  if i < 4
    insurance_products_data << {
      name: "#{config[:name].gsub('境外', '境外高端')}",
      company: companies[(i + 1) % companies.size],
      product_type: 'international',
      code: "#{config[:code].split('-')[0]}-INT-00#{i+5}",
      coverage_details: {
        accident: config[:accident] * 1.5,
        medical: config[:medical] * 1.5,
        trip_cancellation: config[:accident] * 0.05
      },
      price_per_day: config[:price] * 1.8,
      min_days: config[:days][0],
      max_days: [config[:days][1] * 1.5, 365].min.to_i,
      scenes: scenes_base,
      highlights: ["境外医疗#{(config[:medical]*1.5/10000).to_i}万", 'VIP紧急救援'],
      official_select: false,
      featured: i < 2,
      active: true,
      available_for_embedding: false,
      sort_order: 40 - i * 5,
      image_url: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800'
    }
  end
end

# 交通意外保险（transport）- 6个产品
[
  { name: '交通意外险-综合版', code: 'CPIC-TRA-001', accident: 1000000, medical: 50000, price: 3.0, days: [1, 365], scenes: ['交通综合', '航空保障', '家庭保障'] },
  { name: '航空意外险', code: 'HT-TRA-001', accident: 2000000, medical: 0, price: 20.0, days: [1, 1], scenes: ['航空保障', '航班延误保障'] },
  { name: '航班取消保障险', code: 'ZA-TRA-001', accident: 500000, medical: 20000, price: 8.0, days: [1, 7], scenes: ['航空保障', '航班取消保障', '航班延误保障'] }
].each_with_index do |config, i|
  # 基础产品
  insurance_products_data << {
    name: config[:name],
    company: companies[(i + 2) % companies.size],
    product_type: 'transport',
    code: config[:code],
    coverage_details: {
      accident: config[:accident],
      medical: config[:medical],
      trip_cancellation: config[:medical] * 0.25
    }.compact,
    price_per_day: config[:price],
    min_days: config[:days][0],
    max_days: config[:days][1],
    scenes: config[:scenes],
    highlights: ["意外身故#{config[:accident]/10000}万", config[:days][0] == 1 && config[:days][1] == 1 ? '当日有效' : '灵活保障'],
    official_select: false,
    featured: i < 2,
    active: true,
    available_for_embedding: false,
    sort_order: 40 - i * 5,
    image_url: 'https://images.unsplash.com/photo-1464037866556-6812c9d1c72e?w=800'
  }
  
  # 额外生成变种
  if i < 3
    insurance_products_data << {
      name: "#{config[:name].split('-')[0]}-升级版",
      company: companies[(i + 5) % companies.size],
      product_type: 'transport',
      code: "#{config[:code].split('-')[0]}-TRA-00#{i+4}",
      coverage_details: {
        accident: config[:accident] * 1.5,
        medical: config[:medical] * 2,
        trip_cancellation: config[:medical] * 0.5
      }.compact,
      price_per_day: config[:price] * 1.5,
      min_days: config[:days][0],
      max_days: [config[:days][1] * 2, 365].min,
      scenes: config[:scenes],
      highlights: ["意外身故#{(config[:accident]*1.5/10000).to_i}万", '加强保障'],
      official_select: false,
      featured: false,
      active: true,
      available_for_embedding: false,
      sort_order: 30 - i * 5,
      image_url: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?w=800'
    }
  end
end

# 批量创建保险产品（使用 insert_all 符合规范）
InsuranceProduct.insert_all(insurance_products_data)

# ==================== 城市关联配置 ====================

# 定义城市特定价格配置
# 格式：{ 产品code => { 城市名 => 价格 } }
city_pricing = {
  'PA-DOM-001' => {
    '北京' => 6.0,
    '上海' => 6.0,
    '广州' => 5.0,
    '深圳' => 5.5,
    '成都' => 4.5,
    '杭州' => 5.0,
    '厦门' => 5.0,
    '三亚' => 7.0,
    '青岛' => 5.0,
    '珠海' => 5.0
  },
  'PICC-DOM-001' => {
    '北京' => 11.0,
    '上海' => 11.0,
    '广州' => 10.0,
    '深圳' => 10.5,
    '成都' => 9.5,
    '杭州' => 10.0,
    '厦门' => 10.0,
    '三亚' => 12.0,
    '青岛' => 10.0,
    '珠海' => 10.0
  },
  'CPIC-DOM-001' => {
    '三亚' => 12.0,
    '厦门' => 13.0,
    '青岛' => 11.0,
    '珠海' => 12.5,
    '深圳' => 13.0,
    '成都' => 11.5
  },
  'ZA-DOM-001' => {
    '北京' => 15.0,
    '上海' => 15.0,
    '成都' => 14.0,
    '杭州' => 15.5,
    '深圳' => 16.0
  },
  'HT-DOM-001' => {
    '北京' => 25.0,
    '哈尔滨' => 22.0,
    '长春' => 23.0,
    '张家口' => 24.0
  },
  'JD-INT-001' => {
    '北京' => 25.0,
    '上海' => 25.0,
    '广州' => 24.0,
    '深圳' => 24.0,
    '杭州' => 26.0,
    '成都' => 26.0
  },
  'PICC-INT-001' => {
    '北京' => 45.0,
    '上海' => 45.0,
    '广州' => 43.0,
    '深圳' => 43.0,
    '杭州' => 46.0,
    '成都' => 46.0
  },
  'AIG-INT-001' => {
    '北京' => 35.0,
    '上海' => 35.0,
    '广州' => 34.0,
    '深圳' => 34.0,
    '成都' => 36.0
  },
  'AXA-INT-001' => {
    '北京' => 8.0,
    '上海' => 8.0,
    '广州' => 7.5,
    '深圳' => 7.5,
    '成都' => 8.5
  },
  'CPIC-TRA-001' => {
    '北京' => nil,
    '上海' => nil,
    '广州' => nil,
    '深圳' => nil,
    '成都' => nil,
    '杭州' => nil,
    '厦门' => nil,
    '三亚' => nil,
    '青岛' => nil,
    '珠海' => nil
  },
  'HT-TRA-001' => {
    '北京' => 20.0,
    '上海' => 20.0,
    '广州' => 20.0,
    '深圳' => 20.0,
    '成都' => 20.0,
    '杭州' => 20.0,
    '厦门' => 18.0,
    '三亚' => 22.0,
    '青岛' => 18.0,
    '珠海' => 18.0
  },
  'ZA-TRA-001' => {
    '北京' => 8.0,
    '上海' => 8.0,
    '广州' => 7.5,
    '深圳' => 7.5,
    '成都' => 8.5,
    '杭州' => 8.0
  }
}

# 准备城市关联数据
insurance_product_cities_data = []

city_pricing.each do |product_code, cities|
  product = InsuranceProduct.find_by(code: product_code)
  next unless product

  cities.each do |city_name, price|
    city = City.find_by(name: city_name)
    next unless city

    insurance_product_cities_data << {
      insurance_product_id: product.id,
      city_id: city.id,
      price_per_day: price,
      available: true
    }
  end
end

# 批量创建城市关联配置
unless insurance_product_cities_data.empty?
  InsuranceProductCity.insert_all(insurance_product_cities_data)
end

puts "✓ 数据包加载完成"
puts "  - 已创建 #{insurance_products_data.count} 个保险产品"
puts "  - 已创建 #{insurance_product_cities_data.count} 个城市关联配置"
