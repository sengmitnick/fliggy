# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# IMPORTANT: Do NOT add Administrator data here!
# Administrator accounts should be created manually by user.
# This seeds file is only for application data (products, categories, etc.)
#
require 'open-uri'

# Write your seed data here

# ==================== 国家和签证数据 ====================
puts "正在初始化签证国家和产品数据..."

# 国家数据（按地区分组）
visa_countries_data = [
  # 亚洲
  { name: '日本', code: 'JP', region: '亚洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400', description: '富士山、樱花、寺庙', statistics: { success_rate: '98%', processing_time: '8工作日', travelers: '50万+' }},
  { name: '韩国', code: 'KR', region: '亚洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1517154421773-0529f29ea451?w=400', description: '首尔塔、济州岛、韩剧', statistics: { success_rate: '99%', processing_time: '7工作日', travelers: '40万+' }},
  { name: '泰国', code: 'TH', region: '亚洲', visa_free: true, image_url: 'https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=400', description: '曼谷、普吉岛、清迈', statistics: { success_rate: '100%', processing_time: '落地签', travelers: '80万+' }},
  { name: '新加坡', code: 'SG', region: '亚洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=400', description: '鱼尾狮、圣淘沙、环球影城', statistics: { success_rate: '97%', processing_time: '5工作日', travelers: '30万+' }},
  { name: '马来西亚', code: 'MY', region: '亚洲', visa_free: true, image_url: 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=400', description: '双子塔、兰卡威、槟城', statistics: { success_rate: '100%', processing_time: '免签', travelers: '35万+' }},
  { name: '越南', code: 'VN', region: '亚洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1528127269322-539801943592?w=400', description: '胡志明、下龙湾、芽庄', statistics: { success_rate: '99%', processing_time: '6工作日', travelers: '25万+' }},
  { name: '印度', code: 'IN', region: '亚洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=400', description: '泰姬陵、恒河、孟买', statistics: { success_rate: '95%', processing_time: '10工作日', travelers: '15万+' }},
  { name: '印度尼西亚', code: 'ID', region: '亚洲', visa_free: true, image_url: 'https://images.unsplash.com/photo-1555400038-63f5ba517a47?w=400', description: '巴厘岛、雅加达、婆罗浮屠', statistics: { success_rate: '100%', processing_time: '落地签', travelers: '28万+' }},
  
  # 欧洲
  { name: '法国', code: 'FR', region: '欧洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400', description: '埃菲尔铁塔、卢浮宫、普罗旺斯', statistics: { success_rate: '96%', processing_time: '12工作日', travelers: '20万+' }},
  { name: '德国', code: 'DE', region: '欧洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=400', description: '柏林、慕尼黑、新天鹅堡', statistics: { success_rate: '97%', processing_time: '10工作日', travelers: '18万+' }},
  { name: '意大利', code: 'IT', region: '欧洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1515542622106-78bda8ba0e5b?w=400', description: '罗马、威尼斯、佛罗伦萨', statistics: { success_rate: '96%', processing_time: '12工作日', travelers: '22万+' }},
  { name: '英国', code: 'GB', region: '欧洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400', description: '大本钟、伦敦眼、剑桥', statistics: { success_rate: '95%', processing_time: '15工作日', travelers: '16万+' }},
  { name: '西班牙', code: 'ES', region: '欧洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=400', description: '巴塞罗那、马德里、塞维利亚', statistics: { success_rate: '97%', processing_time: '12工作日', travelers: '19万+' }},
  { name: '瑞士', code: 'CH', region: '欧洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400', description: '少女峰、日内瓦湖、苏黎世', statistics: { success_rate: '98%', processing_time: '10工作日', travelers: '12万+' }},
  
  # 美洲
  { name: '美国', code: 'US', region: '美洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1485738422979-f5c462d49f74?w=400', description: '自由女神、大峡谷、黄石公园', statistics: { success_rate: '92%', processing_time: '20工作日', travelers: '30万+' }},
  { name: '加拿大', code: 'CA', region: '美洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1517935706615-2717063c2225?w=400', description: '落基山脉、尼亚加拉瀑布、温哥华', statistics: { success_rate: '94%', processing_time: '18工作日', travelers: '15万+' }},
  { name: '巴西', code: 'BR', region: '美洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=400', description: '里约热内卢、亚马逊雨林、伊瓜苏瀑布', statistics: { success_rate: '96%', processing_time: '15工作日', travelers: '8万+' }},
  
  # 大洋洲
  { name: '澳大利亚', code: 'AU', region: '大洋洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1523482580672-f109ba8cb9be?w=400', description: '悉尼歌剧院、大堡礁、墨尔本', statistics: { success_rate: '95%', processing_time: '14工作日', travelers: '20万+' }},
  { name: '新西兰', code: 'NZ', region: '大洋洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1469521669194-babb72ee7e55?w=400', description: '皇后镇、霍比特村、米尔福德峡湾', statistics: { success_rate: '96%', processing_time: '12工作日', travelers: '12万+' }},
  
  # 非洲
  { name: '南非', code: 'ZA', region: '非洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1484318571209-661cf29a69c3?w=400', description: '开普敦、桌山、克鲁格国家公园', statistics: { success_rate: '97%', processing_time: '10工作日', travelers: '6万+' }},
  { name: '埃及', code: 'EG', region: '非洲', visa_free: false, image_url: 'https://images.unsplash.com/photo-1572252009286-268acec5ca0a?w=400', description: '金字塔、尼罗河、红海', statistics: { success_rate: '98%', processing_time: '8工作日', travelers: '10万+' }},
]

Country.find_or_create_by!(name: '日本', code: 'JP') do |country|
  country.region = '亚洲'
  country.visa_free = false
  country.image_url = 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400'
  country.description = '富士山、樱花、寺庙'
  country.statistics = { success_rate: '98%', processing_time: '8工作日', travelers: '50万+' }
end

visa_countries_data.each do |data|
  country = Country.find_or_create_by!(name: data[:name], code: data[:code]) do |c|
    c.region = data[:region]
    c.visa_free = data[:visa_free]
    c.image_url = data[:image_url]
    c.description = data[:description]
    c.statistics = data[:statistics]
  end
  puts "✓ 国家: #{country.name}"
end

# 为日本创建签证产品（作为示例）
japan = Country.find_by(name: '日本')
if japan
  visa_products_data = [
    {
      name: '日本单次旅游签证',
      product_type: 'single',
      price: 299,
      processing_days: 8,
      material_count: 6,
      required_materials: {
        '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '户口本'],
        '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '户口本'],
        '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资产证明', '户口本'],
        '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '户口本']
      },
      can_simplify: true,
      home_pickup: true,
      supports_family: true,
      merchant_name: '携程签证',
      success_rate: 99,
      features: ['拒签全退', '上门取件', '材料简化', '加急办理']
    },
    {
      name: '日本三年多次往返签证',
      product_type: 'multiple_3year',
      price: 699,
      processing_days: 10,
      material_count: 8,
      required_materials: {
        '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '户口本', '资产证明', '纳税证明'],
        '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '户口本', '房产证', '车辆行驶证'],
        '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资产证明', '户口本', '父母在职证明', '家庭资产'],
        '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '户口本', '资产证明', '房产证']
      },
      can_simplify: false,
      home_pickup: true,
      supports_family: true,
      merchant_name: '携程签证',
      success_rate: 98,
      features: ['三年多次', '上门取件', '专业服务']
    },
    {
      name: '日本五年多次往返签证',
      product_type: 'multiple_5year',
      price: 999,
      processing_days: 12,
      material_count: 10,
      required_materials: {
        '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '户口本', '资产证明', '纳税证明', '房产证', '车辆行驶证'],
        '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '户口本', '房产证', '车辆行驶证', '营业执照', '股权证明'],
        '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资产证明', '户口本', '父母在职证明', '家庭资产', '房产证', '学习成绩'],
        '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '户口本', '资产证明', '房产证', '养老金证明', '医疗保险']
      },
      can_simplify: false,
      home_pickup: true,
      supports_family: true,
      merchant_name: '携程签证',
      success_rate: 97,
      features: ['五年多次', '上门取件', '专家指导', 'VIP服务']
    }
  ]
  
  visa_products_data.each do |data|
    product = japan.visa_products.find_or_create_by!(name: data[:name]) do |p|
      p.product_type = data[:product_type]
      p.price = data[:price]
      p.processing_days = data[:processing_days]
      p.material_count = data[:material_count]
      p.required_materials = data[:required_materials]
      p.can_simplify = data[:can_simplify]
      p.home_pickup = data[:home_pickup]
      p.supports_family = data[:supports_family]
      p.merchant_name = data[:merchant_name]
      p.success_rate = data[:success_rate]
      p.features = data[:features]
    end
    puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
  end
end

# 为韩国创建签证产品
korea = Country.find_by(name: '韩国')
if korea
  visa_products_data = [
    {
      name: '韩国单次旅游签证',
      product_type: 'single',
      price: 259,
      processing_days: 7,
      material_count: 5,
      required_materials: {
        '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水'],
        '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水'],
        '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资产证明'],
        '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水']
      },
      can_simplify: true,
      home_pickup: true,
      supports_family: true,
      merchant_name: '途牛签证',
      success_rate: 99,
      features: ['拒签全退', '上门取件', '快速办理']
    },
    {
      name: '韩国五年多次往返签证',
      product_type: 'multiple_5year',
      price: 599,
      processing_days: 9,
      material_count: 7,
      required_materials: {
        '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '资产证明', '纳税证明'],
        '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '房产证', '营业执照'],
        '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资产证明', '父母在职证明', '家庭资产'],
        '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '资产证明', '养老金证明']
      },
      can_simplify: false,
      home_pickup: true,
      supports_family: true,
      merchant_name: '途牛签证',
      success_rate: 98,
      features: ['五年多次', '上门取件', '专业服务']
    }
  ]
  
  visa_products_data.each do |data|
    product = korea.visa_products.find_or_create_by!(name: data[:name]) do |p|
      p.product_type = data[:product_type]
      p.price = data[:price]
      p.processing_days = data[:processing_days]
      p.material_count = data[:material_count]
      p.required_materials = data[:required_materials]
      p.can_simplify = data[:can_simplify]
      p.home_pickup = data[:home_pickup]
      p.supports_family = data[:supports_family]
      p.merchant_name = data[:merchant_name]
      p.success_rate = data[:success_rate]
      p.features = data[:features]
    end
    puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
  end
end

# 为新加坡创建签证产品
singapore = Country.find_by(name: '新加坡')
if singapore
  product = singapore.visa_products.find_or_create_by!(name: '新加坡电子签证') do |p|
    p.product_type = 'single'
    p.price = 299
    p.processing_days = 5
    p.material_count = 4
    p.required_materials = {
      '在职人员' => ['护照', '照片', '在职证明', '银行流水'],
      '自由职业' => ['护照', '照片', '资产证明', '银行流水'],
      '在校学生' => ['护照', '照片', '在读证明', '父母资产证明'],
      '退休人员' => ['护照', '照片', '退休证', '银行流水']
    }
    p.can_simplify = true
    p.home_pickup = false
    p.supports_family = true
    p.merchant_name = '飞猪签证'
    p.success_rate = 99
    p.features = ['电子签', '出签快', '材料简单']
  end
  puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
end

# 为泰国创建签证产品
thailand = Country.find_by(name: '泰国')
if thailand
  product = thailand.visa_products.find_or_create_by!(name: '泰国落地签证') do |p|
    p.product_type = 'single'
    p.price = 259
    p.processing_days = 3
    p.material_count = 3
    p.required_materials = {
      '所有人员' => ['护照', '照片', '往返机票']
    }
    p.can_simplify = true
    p.home_pickup = false
    p.supports_family = true
    p.merchant_name = '飞猪签证'
    p.success_rate = 100
    p.features = ['落地签', '办理快', '材料简单']
  end
  puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
end

# 为马来西亚创建签证产品
malaysia = Country.find_by(name: '马来西亚')
if malaysia
  product = malaysia.visa_products.find_or_create_by!(name: '马来西亚电子签证') do |p|
    p.product_type = 'single'
    p.price = 199
    p.processing_days = 3
    p.material_count = 3
    p.required_materials = {
      '所有人员' => ['护照', '照片', '往返机票']
    }
    p.can_simplify = true
    p.home_pickup = false
    p.supports_family = true
    p.merchant_name = '携程签证'
    p.success_rate = 100
    p.features = ['电子签', '免签待遇', '快速出签']
  end
  puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
end

# 为越南创建签证产品
vietnam = Country.find_by(name: '越南')
if vietnam
  visa_products_data = [
    {
      name: '越南单次旅游签证',
      product_type: 'single',
      price: 299,
      processing_days: 6,
      material_count: 4,
      required_materials: {
        '在职人员' => ['护照', '照片', '签证申请表', '在职证明'],
        '自由职业' => ['护照', '照片', '签证申请表', '资产证明'],
        '在校学生' => ['护照', '照片', '签证申请表', '在读证明'],
        '退休人员' => ['护照', '照片', '签证申请表', '退休证']
      },
      can_simplify: true,
      home_pickup: true,
      supports_family: true,
      merchant_name: '途牛签证',
      success_rate: 99,
      features: ['拒签全退', '上门取件', '材料简单']
    }
  ]
  
  visa_products_data.each do |data|
    product = vietnam.visa_products.find_or_create_by!(name: data[:name]) do |p|
      p.product_type = data[:product_type]
      p.price = data[:price]
      p.processing_days = data[:processing_days]
      p.material_count = data[:material_count]
      p.required_materials = data[:required_materials]
      p.can_simplify = data[:can_simplify]
      p.home_pickup = data[:home_pickup]
      p.supports_family = data[:supports_family]
      p.merchant_name = data[:merchant_name]
      p.success_rate = data[:success_rate]
      p.features = data[:features]
    end
    puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
  end
end

# 为法国创建签证产品（申根签证）
france = Country.find_by(name: '法国')
if france
  visa_products_data = [
    {
      name: '法国申根旅游签证',
      product_type: 'single',
      price: 899,
      processing_days: 12,
      material_count: 8,
      required_materials: {
        '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '行程单', '酒店预订', '机票预订'],
        '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '行程单', '酒店预订', '机票预订'],
        '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资助声明', '行程单', '酒店预订', '机票预订'],
        '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '行程单', '酒店预订', '机票预订']
      },
      can_simplify: false,
      home_pickup: true,
      supports_family: true,
      merchant_name: '携程签证',
      success_rate: 96,
      features: ['申根签证', '上门取件', '专家指导', '畅游26国']
    }
  ]
  
  visa_products_data.each do |data|
    product = france.visa_products.find_or_create_by!(name: data[:name]) do |p|
      p.product_type = data[:product_type]
      p.price = data[:price]
      p.processing_days = data[:processing_days]
      p.material_count = data[:material_count]
      p.required_materials = data[:required_materials]
      p.can_simplify = data[:can_simplify]
      p.home_pickup = data[:home_pickup]
      p.supports_family = data[:supports_family]
      p.merchant_name = data[:merchant_name]
      p.success_rate = data[:success_rate]
      p.features = data[:features]
    end
    puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
  end
end

# 为美国创建签证产品
usa = Country.find_by(name: '美国')
if usa
  visa_products_data = [
    {
      name: '美国B1/B2旅游签证',
      product_type: 'multiple_10year',
      price: 1699,
      processing_days: 20,
      material_count: 10,
      required_materials: {
        '在职人员' => ['护照', '照片', 'DS-160表', '在职证明', '银行流水', '资产证明', '行程计划', '面签预约', '户口本', '结婚证'],
        '自由职业' => ['护照', '照片', 'DS-160表', '资产证明', '银行流水', '营业执照', '行程计划', '面签预约', '户口本', '结婚证'],
        '在校学生' => ['护照', '照片', 'DS-160表', '在读证明', '父母资助声明', '父母资产', '行程计划', '面签预约', '户口本', '学习成绩'],
        '退休人员' => ['护照', '照片', 'DS-160表', '退休证', '银行流水', '资产证明', '行程计划', '面签预约', '户口本', '子女证明']
      },
      can_simplify: false,
      home_pickup: true,
      supports_family: true,
      merchant_name: '携程签证',
      success_rate: 92,
      features: ['十年多次', '面签辅导', '专家指导', '拒签重办']
    }
  ]
  
  visa_products_data.each do |data|
    product = usa.visa_products.find_or_create_by!(name: data[:name]) do |p|
      p.product_type = data[:product_type]
      p.price = data[:price]
      p.processing_days = data[:processing_days]
      p.material_count = data[:material_count]
      p.required_materials = data[:required_materials]
      p.can_simplify = data[:can_simplify]
      p.home_pickup = data[:home_pickup]
      p.supports_family = data[:supports_family]
      p.merchant_name = data[:merchant_name]
      p.success_rate = data[:success_rate]
      p.features = data[:features]
    end
    puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
  end
end

# 为澳大利亚创建签证产品
australia = Country.find_by(name: '澳大利亚')
if australia
  visa_products_data = [
    {
      name: '澳大利亚旅游签证',
      product_type: 'multiple_1year',
      price: 1299,
      processing_days: 14,
      material_count: 8,
      required_materials: {
        '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '资产证明', '行程单', '户口本'],
        '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '营业执照', '行程单', '户口本'],
        '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资助声明', '父母资产', '行程单', '户口本'],
        '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '资产证明', '行程单', '户口本']
      },
      can_simplify: false,
      home_pickup: true,
      supports_family: true,
      merchant_name: '飞猪签证',
      success_rate: 95,
      features: ['电子签', '一年多次', '专家审核', '快速出签']
    }
  ]
  
  visa_products_data.each do |data|
    product = australia.visa_products.find_or_create_by!(name: data[:name]) do |p|
      p.product_type = data[:product_type]
      p.price = data[:price]
      p.processing_days = data[:processing_days]
      p.material_count = data[:material_count]
      p.required_materials = data[:required_materials]
      p.can_simplify = data[:can_simplify]
      p.home_pickup = data[:home_pickup]
      p.supports_family = data[:supports_family]
      p.merchant_name = data[:merchant_name]
      p.success_rate = data[:success_rate]
      p.features = data[:features]
    end
    puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
  end
end

# 为英国创建签证产品
uk = Country.find_by(name: '英国')
if uk
  product = uk.visa_products.find_or_create_by!(name: '英国旅游签证') do |p|
    p.product_type = 'multiple_2year'
    p.price = 1499
    p.processing_days = 15
    p.material_count = 9
    p.required_materials = {
      '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '资产证明', '行程单', '酒店预订', '机票预订'],
      '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '营业执照', '行程单', '酒店预订', '机票预订'],
      '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资助声明', '父母资产', '行程单', '酒店预订', '机票预订'],
      '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '资产证明', '行程单', '酒店预订', '机票预订']
    }
    p.can_simplify = false
    p.home_pickup = true
    p.supports_family = true
    p.merchant_name = '途牛签证'
    p.success_rate = 95
    p.features = ['两年多次', '上门取件', '专家指导', '材料翻译']
  end
  puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
end

# 为加拿大创建签证产品
canada = Country.find_by(name: '加拿大')
if canada
  product = canada.visa_products.find_or_create_by!(name: '加拿大旅游签证') do |p|
    p.product_type = 'multiple_10year'
    p.price = 1399
    p.processing_days = 18
    p.material_count = 9
    p.required_materials = {
      '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '资产证明', '行程单', '户口本', '结婚证'],
      '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '营业执照', '行程单', '户口本', '结婚证'],
      '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资助声明', '父母资产', '行程单', '户口本', '出生证明'],
      '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '资产证明', '行程单', '户口本', '子女证明']
    }
    p.can_simplify = false
    p.home_pickup = true
    p.supports_family = true
    p.merchant_name = '携程签证'
    p.success_rate = 94
    p.features = ['十年多次', '上门取件', '专家审核', '材料指导']
  end
  puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
end

# 为新西兰创建签证产品
newzealand = Country.find_by(name: '新西兰')
if newzealand
  product = newzealand.visa_products.find_or_create_by!(name: '新西兰旅游签证') do |p|
    p.product_type = 'multiple_2year'
    p.price = 1199
    p.processing_days = 12
    p.material_count = 7
    p.required_materials = {
      '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '资产证明', '行程单'],
      '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '营业执照', '行程单'],
      '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资助声明', '父母资产', '行程单'],
      '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '资产证明', '行程单']
    }
    p.can_simplify = false
    p.home_pickup = true
    p.supports_family = true
    p.merchant_name = '飞猪签证'
    p.success_rate = 96
    p.features = ['电子签', '两年多次', '快速出签', '材料简化']
  end
  puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
end

# 为德国创建签证产品（申根签证）
germany = Country.find_by(name: '德国')
if germany
  product = germany.visa_products.find_or_create_by!(name: '德国申根旅游签证') do |p|
    p.product_type = 'single'
    p.price = 899
    p.processing_days = 10
    p.material_count = 8
    p.required_materials = {
      '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '行程单', '酒店预订', '机票预订'],
      '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '行程单', '酒店预订', '机票预订'],
      '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资助声明', '行程单', '酒店预订', '机票预订'],
      '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '行程单', '酒店预订', '机票预订']
    }
    p.can_simplify = false
    p.home_pickup = true
    p.supports_family = true
    p.merchant_name = '途牛签证'
    p.success_rate = 97
    p.features = ['申根签证', '上门取件', '专家审核', '畅游26国']
  end
  puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
end

# 为意大利创建签证产品（申根签证）
italy = Country.find_by(name: '意大利')
if italy
  product = italy.visa_products.find_or_create_by!(name: '意大利申根旅游签证') do |p|
    p.product_type = 'single'
    p.price = 899
    p.processing_days = 12
    p.material_count = 8
    p.required_materials = {
      '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '行程单', '酒店预订', '机票预订'],
      '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '行程单', '酒店预订', '机票预订'],
      '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资助声明', '行程单', '酒店预订', '机票预订'],
      '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '行程单', '酒店预订', '机票预订']
    }
    p.can_simplify = false
    p.home_pickup = true
    p.supports_family = true
    p.merchant_name = '携程签证'
    p.success_rate = 96
    p.features = ['申根签证', '上门取件', '专家指导', '畅游26国']
  end
  puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
end

# 为西班牙创建签证产品（申根签证）
spain = Country.find_by(name: '西班牙')
if spain
  product = spain.visa_products.find_or_create_by!(name: '西班牙申根旅游签证') do |p|
    p.product_type = 'single'
    p.price = 899
    p.processing_days = 12
    p.material_count = 8
    p.required_materials = {
      '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水', '行程单', '酒店预订', '机票预订'],
      '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水', '行程单', '酒店预订', '机票预订'],
      '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资助声明', '行程单', '酒店预订', '机票预订'],
      '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水', '行程单', '酒店预订', '机票预订']
    }
    p.can_simplify = false
    p.home_pickup = true
    p.supports_family = true
    p.merchant_name = '飞猪签证'
    p.success_rate = 97
    p.features = ['申根签证', '上门取件', '专家审核', '畅游26国']
  end
  puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
end

# 为印度创建签证产品
india = Country.find_by(name: '印度')
if india
  product = india.visa_products.find_or_create_by!(name: '印度电子旅游签证') do |p|
    p.product_type = 'single'
    p.price = 599
    p.processing_days = 10
    p.material_count = 5
    p.required_materials = {
      '在职人员' => ['护照', '照片', '签证申请表', '在职证明', '银行流水'],
      '自由职业' => ['护照', '照片', '签证申请表', '资产证明', '银行流水'],
      '在校学生' => ['护照', '照片', '签证申请表', '在读证明', '父母资助声明'],
      '退休人员' => ['护照', '照片', '签证申请表', '退休证', '银行流水']
    }
    p.can_simplify = false
    p.home_pickup = true
    p.supports_family = true
    p.merchant_name = '途牛签证'
    p.success_rate = 95
    p.features = ['电子签', '快速出签', '上门取件', '材料简化']
  end
  puts "  ✓ 签证产品: #{product.name} - ¥#{product.price}"
end

puts "\n签证数据初始化完成！"
puts "创建了 #{Country.count} 个国家"
puts "创建了 #{VisaProduct.count} 个签证产品"

# ==================== 城市数据 ====================
# (保留原有的城市数据代码...)
