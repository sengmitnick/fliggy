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
    official_select: false,
    featured: true,
    active: true,
    sort_order: 80,
    image_url: nil
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
    official_select: false,
    featured: true,
    active: true,
    sort_order: 50,
    image_url: nil
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
    official_select: false,
    featured: false,
    active: true,
    sort_order: 40,
    image_url: nil
  }
]

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
    '深圳' => 13.0
  },
  'PA-INT-001' => {
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
  'PA-TRA-001' => {
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
  }
}

# 构建批量插入数据
city_associations = []
city_pricing.each do |product_code, city_prices|
  product = InsuranceProduct.find_by(code: product_code)
  next unless product
  
  city_prices.each do |city_name, price|
    city = City.find_by(name: city_name)
    next unless city
    
    city_associations << {
      insurance_product_id: product.id,
      city_id: city.id,
      price_per_day: price,
      available: true
    }
  end
end

# 批量插入城市关联（使用 insert_all 符合规范）
InsuranceProductCity.insert_all(city_associations) if city_associations.any?

puts "✓ 数据包加载完成"
puts "  - 保险产品: #{InsuranceProduct.count} 个"
puts "  - 城市关联: #{InsuranceProductCity.count} 条"
