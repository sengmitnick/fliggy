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
# rails runner "load Rails.root.join('app/validators/support/data_packs/v1/insurances.rb')"

puts "正在加载 insurances_v1 数据包..."

# ==================== 保险产品数据 ====================

insurance_products_data = [
  # 境内旅行保险
  {
    name: '境内旅游险-基础款',
    company: '平安保险',
    product_type: 'domestic',
    code: 'PA-DOM-001',
    coverage_details: {
      accident: 500000,
      medical: 50000,
      trip_cancellation: 10000
    },
    price_per_day: 5.0,
    min_days: 1,
    max_days: 30,
    scenes: ['国内游', '短途游', '周边游'],
    highlights: ['意外身故50万', '意外医疗5万', '行程取消保障'],
    official_select: true,
    featured: true,
    active: true,
    sort_order: 100,
    image_url: 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?w=800'
  },
  {
    name: '境内旅游险-尊享款',
    company: '中国人保',
    product_type: 'domestic',
    code: 'PICC-DOM-001',
    coverage_details: {
      accident: 1000000,
      medical: 100000,
      trip_cancellation: 20000
    },
    price_per_day: 10.0,
    min_days: 1,
    max_days: 60,
    scenes: ['国内游', '长途游', '自驾游'],
    highlights: ['意外身故100万', '意外医疗10万', '自驾车意外双倍赔付'],
    official_select: true,
    featured: true,
    active: true,
    sort_order: 90,
    image_url: 'https://images.unsplash.com/photo-1506929562872-bb421503ef21?w=800'
  },
  {
    name: '海岛度假保险',
    company: '太平洋保险',
    product_type: 'domestic',
    code: 'CPIC-DOM-001',
    coverage_details: {
      accident: 800000,
      medical: 80000,
      trip_cancellation: 15000
    },
    price_per_day: 12.0,
    min_days: 3,
    max_days: 15,
    scenes: ['海边度假', '亲子必去'],
    highlights: ['水上运动保障', '紧急医疗运送', '旅行延误赔偿'],
    featured: true,
    active: true,
    sort_order: 80
  },
  
  # 境外/港澳台旅行保险
  {
    name: '境外旅游险-亚洲版',
    company: '平安保险',
    product_type: 'international',
    code: 'PA-INT-001',
    coverage_details: {
      accident: 1000000,
      medical: 300000,
      trip_cancellation: 30000
    },
    price_per_day: 25.0,
    min_days: 3,
    max_days: 90,
    scenes: ['境外游', '港澳台游'],
    highlights: ['境外医疗30万', '紧急救援服务', '个人财物保障'],
    official_select: true,
    featured: true,
    active: true,
    sort_order: 70,
    image_url: 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?w=800'
  },
  {
    name: '境外旅游险-全球版',
    company: '中国人保',
    product_type: 'international',
    code: 'PICC-INT-001',
    coverage_details: {
      accident: 2000000,
      medical: 500000,
      trip_cancellation: 50000
    },
    price_per_day: 45.0,
    min_days: 3,
    max_days: 180,
    scenes: ['境外游', '欧美游', '长途游'],
    highlights: ['全球医疗50万', '24小时紧急救援', '航班延误赔偿'],
    official_select: true,
    featured: true,
    active: true,
    sort_order: 60,
    image_url: 'https://images.unsplash.com/photo-1488646953014-85cb44e25828?w=800'
  },
  
  # 交通意外保险
  {
    name: '交通意外险-综合版',
    company: '太平洋保险',
    product_type: 'transport',
    code: 'CPIC-TRA-001',
    coverage_details: {
      accident: 1000000,
      medical: 50000,
      trip_cancellation: 0
    },
    price_per_day: 3.0,
    min_days: 1,
    max_days: 365,
    scenes: ['飞机', '火车', '汽车', '轮船'],
    highlights: ['海陆空全覆盖', '意外身故100万', '意外医疗5万'],
    featured: true,
    active: true,
    sort_order: 50
  },
  {
    name: '航空意外险',
    company: '平安保险',
    product_type: 'transport',
    code: 'PA-TRA-001',
    coverage_details: {
      accident: 2000000,
      medical: 0,
      trip_cancellation: 0
    },
    price_per_day: 20.0,
    min_days: 1,
    max_days: 1,
    scenes: ['飞机'],
    highlights: ['航空意外200万', '当日有效', '全球航班通用'],
    active: true,
    sort_order: 40
  }
]

# 批量创建保险产品
created_products = []
insurance_products_data.each do |data|
  product = InsuranceProduct.find_or_create_by!(code: data[:code]) do |p|
    p.assign_attributes(data.except(:code))
  end
  created_products << product
  puts "    ✓ #{product.name} (#{product.code})"
end

# ==================== 城市关联配置 ====================

# 获取城市对象
cities = {
  beijing: City.find_by(name: '北京'),
  shanghai: City.find_by(name: '上海'),
  guangzhou: City.find_by(name: '广州'),
  shenzhen: City.find_by(name: '深圳'),
  chengdu: City.find_by(name: '成都'),
  hangzhou: City.find_by(name: '杭州'),
  xiamen: City.find_by(name: '厦门'),
  sanya: City.find_by(name: '三亚'),
  qingdao: City.find_by(name: '青岛'),
  zhuhai: City.find_by(name: '珠海'),
  tokyo: City.find_by(name: '东京'),
  osaka: City.find_by(name: '大阪'),
  bangkok: City.find_by(name: '曼谷'),
  hongkong: City.find_by(name: '香港'),
  macau: City.find_by(name: '澳门')
}

# 定义城市特定价格配置
# 格式：{ 产品code => { 城市key => 价格 } }
city_pricing = {
  'PA-DOM-001' => {
    beijing: 6.0,      # 北京价格稍高
    shanghai: 6.0,     # 上海价格稍高
    guangzhou: 5.0,    # 标准价格
    shenzhen: 5.5,     # 深圳略高
    chengdu: 4.5,      # 成都略低
    hangzhou: 5.0,
    xiamen: 5.0,
    sanya: 7.0,        # 海南旅游旺季价格高
    qingdao: 5.0,
    zhuhai: 5.0
  },
  'PICC-DOM-001' => {
    beijing: 11.0,
    shanghai: 11.0,
    guangzhou: 10.0,
    shenzhen: 10.5,
    chengdu: 9.5,
    hangzhou: 10.0,
    xiamen: 10.0,
    sanya: 12.0,
    qingdao: 10.0,
    zhuhai: 10.0
  },
  'CPIC-DOM-001' => {
    sanya: 12.0,       # 海岛险只在海滨城市提供
    xiamen: 13.0,
    qingdao: 11.0,
    zhuhai: 12.5,
    shenzhen: 13.0
  },
  'PA-INT-001' => {
    beijing: 25.0,     # 境外险在一线城市提供
    shanghai: 25.0,
    guangzhou: 24.0,
    shenzhen: 24.0,
    hangzhou: 26.0,
    chengdu: 26.0
  },
  'PICC-INT-001' => {
    beijing: 45.0,
    shanghai: 45.0,
    guangzhou: 43.0,
    shenzhen: 43.0,
    hangzhou: 46.0,
    chengdu: 46.0
  },
  'CPIC-TRA-001' => {
    # 交通险在所有主要城市提供（使用默认价格nil）
    beijing: nil,
    shanghai: nil,
    guangzhou: nil,
    shenzhen: nil,
    chengdu: nil,
    hangzhou: nil,
    xiamen: nil,
    sanya: nil,
    qingdao: nil,
    zhuhai: nil
  },
  'PA-TRA-001' => {
    # 航空险在所有城市提供
    beijing: 20.0,
    shanghai: 20.0,
    guangzhou: 20.0,
    shenzhen: 20.0,
    chengdu: 20.0,
    hangzhou: 20.0,
    xiamen: 18.0,
    sanya: 22.0,
    qingdao: 18.0,
    zhuhai: 18.0
  }
}

# 创建城市关联
city_pricing.each do |product_code, city_prices|
  product = InsuranceProduct.find_by(code: product_code)
  next unless product
  
  city_prices.each do |city_key, price|
    city = cities[city_key]
    next unless city
    
    InsuranceProductCity.find_or_create_by!(
      insurance_product_id: product.id,
      city_id: city.id
    ) do |ipc|
      ipc.price_per_day = price  # nil 会使用产品默认价格
      ipc.available = true
    end
    
    price_display = price ? "¥#{price}/天" : "默认价格"
    puts "    ✓ #{product.name} → #{city.name} (#{price_display})"
  end
end

puts "✓ 保险产品数据加载完成"
puts "  - 产品数量: #{InsuranceProduct.count}"
puts "  - 城市关联: #{InsuranceProductCity.count}"
