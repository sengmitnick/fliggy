# frozen_string_literal: true


timestamp = Time.current

# ============================================
# 第一步：创建国家数据
# ============================================

countries_data = [
  # 东南亚国家
  { name: "泰国", code: "TH", region: "东南亚", visa_free: false, image_url: "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=400", description: "东南亚热门旅游目的地", created_at: timestamp, updated_at: timestamp },
  { name: "越南", code: "VN", region: "东南亚", visa_free: false, image_url: "https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400", description: "东南亚文化古国", created_at: timestamp, updated_at: timestamp },
  { name: "新加坡", code: "SG", region: "东南亚", visa_free: false, image_url: "https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=400", description: "东南亚金融中心", created_at: timestamp, updated_at: timestamp },
  { name: "马来西亚", code: "MY", region: "东南亚", visa_free: false, image_url: "https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=400", description: "多元文化国家", created_at: timestamp, updated_at: timestamp },
  { name: "菲律宾", code: "PH", region: "东南亚", visa_free: false, image_url: "https://images.unsplash.com/photo-1551244072-5d12893278ab?w=400", description: "千岛之国", created_at: timestamp, updated_at: timestamp },
  { name: "印度尼西亚", code: "ID", region: "东南亚", visa_free: false, image_url: "https://images.unsplash.com/photo-1555409290-7896f99c76b2?w=400", description: "万岛之国", created_at: timestamp, updated_at: timestamp },
  
  # 东亚国家
  { name: "日本", code: "JP", region: "东亚", visa_free: false, image_url: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400", description: "樱花之国", created_at: timestamp, updated_at: timestamp },
  { name: "韩国", code: "KR", region: "东亚", visa_free: false, image_url: "https://images.unsplash.com/photo-1517154421773-0529f29ea451?w=400", description: "韩流文化发源地", created_at: timestamp, updated_at: timestamp },
  
  # 欧洲国家
  { name: "英国", code: "GB", region: "欧洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=400", description: "大不列颠及北爱尔兰联合王国", created_at: timestamp, updated_at: timestamp },
  { name: "法国", code: "FR", region: "欧洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=400", description: "浪漫之都", created_at: timestamp, updated_at: timestamp },
  { name: "德国", code: "DE", region: "欧洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1467269204594-9661b134dd2b?w=400", description: "欧洲经济引擎", created_at: timestamp, updated_at: timestamp },
  { name: "意大利", code: "IT", region: "欧洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=400", description: "文艺复兴发源地", created_at: timestamp, updated_at: timestamp },
  { name: "西班牙", code: "ES", region: "欧洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=400", description: "激情国度", created_at: timestamp, updated_at: timestamp },
  { name: "瑞士", code: "CH", region: "欧洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400", description: "永久中立国", created_at: timestamp, updated_at: timestamp },
  { name: "希腊", code: "GR", region: "欧洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1555993539-1732b0258235?w=400", description: "西方文明发源地", created_at: timestamp, updated_at: timestamp },
  
  # 大洋洲国家
  { name: "澳大利亚", code: "AU", region: "大洋洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1523482580672-f109ba8cb9be?w=400", description: "南半球大陆", created_at: timestamp, updated_at: timestamp },
  { name: "新西兰", code: "NZ", region: "大洋洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1507699622108-4be3abd695ad?w=400", description: "长白云之乡", created_at: timestamp, updated_at: timestamp },
  
  # 北美洲国家
  { name: "美国", code: "US", region: "北美洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1485738422979-f5c462d49f74?w=400", description: "超级大国", created_at: timestamp, updated_at: timestamp },
  { name: "加拿大", code: "CA", region: "北美洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1503614472-8c93d56e92ce?w=400", description: "枫叶之国", created_at: timestamp, updated_at: timestamp },
  
  # 南美洲国家
  { name: "巴西", code: "BR", region: "南美洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=400", description: "足球王国", created_at: timestamp, updated_at: timestamp },
  { name: "阿根廷", code: "AR", region: "南美洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1589909202802-8f4aadce1849?w=400", description: "探戈之国", created_at: timestamp, updated_at: timestamp },
  
  # 非洲国家
  { name: "埃及", code: "EG", region: "非洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1572252009286-268acec5ca0a?w=400", description: "古文明古国", created_at: timestamp, updated_at: timestamp },
  { name: "南非", code: "ZA", region: "非洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1484318571209-661cf29a69c3?w=400", description: "彩虹之国", created_at: timestamp, updated_at: timestamp },
  { name: "肯尼亚", code: "KE", region: "非洲", visa_free: false, image_url: "https://images.unsplash.com/photo-1489392191049-fc10c97e64b6?w=400", description: "野生动物天堂", created_at: timestamp, updated_at: timestamp },
  
  # 南亚国家
  { name: "印度", code: "IN", region: "南亚", visa_free: false, image_url: "https://images.unsplash.com/photo-1524492412937-b28074a5d7da?w=400", description: "文明古国", created_at: timestamp, updated_at: timestamp },
  { name: "斯里兰卡", code: "LK", region: "南亚", visa_free: false, image_url: "https://images.unsplash.com/photo-1566073771259-6a8506099945?w=400", description: "印度洋上的明珠", created_at: timestamp, updated_at: timestamp },
  
  # 中东国家
  { name: "阿联酋", code: "AE", region: "中东", visa_free: false, image_url: "https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=400", description: "沙漠中的明珠", created_at: timestamp, updated_at: timestamp },
  { name: "土耳其", code: "TR", region: "中东", visa_free: false, image_url: "https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=400", description: "横跨欧亚大陆", created_at: timestamp, updated_at: timestamp }
]

Country.insert_all(countries_data)

# 重新加载国家数据以获取ID
countries = Country.all.index_by(&:code)

# ============================================
# 第二步：创建签证产品数据
# ============================================

visa_products_data = []

# 泰国签证产品
visa_products_data.concat([
  {
    country_id: countries["TH"].id,
    name: "泰国旅游签证",
    product_type: "旅游签证",
    price: 88,
    original_price: 93,
    residence_area: "全国",
    processing_days: 2,
    visa_validity: "90天",
    max_stay: "60天",
    success_rate: 100.0,
    material_count: 2,
    can_simplify: true,
    home_pickup: true,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "湖南新康辉国旅旗舰店",
    sales_count: 15000,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    country_id: countries["TH"].id,
    name: "泰国电子签证",
    product_type: "电子签证",
    price: 158,
    original_price: 163,
    residence_area: "全国",
    processing_days: 3,
    visa_validity: "90天",
    max_stay: "60天",
    success_rate: 99.8,
    material_count: 1,
    can_simplify: true,
    home_pickup: false,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "武汉碧海蓝天旅游专营店",
    sales_count: 9800,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 日本签证产品
visa_products_data.concat([
  {
    country_id: countries["JP"].id,
    name: "日本单次旅游签证",
    product_type: "单次签证",
    price: 191,
    original_price: 196,
    residence_area: "全国",
    processing_days: 18,
    visa_validity: "90天",
    max_stay: "15天",
    success_rate: 100.0,
    material_count: 5,
    can_simplify: true,
    home_pickup: true,
    refused_reapply: true,
    supports_family: true,
    merchant_name: "湖南宝中旅行社专营店",
    sales_count: 6000,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    country_id: countries["JP"].id,
    name: "日本三年多次签证",
    product_type: "多次签证",
    price: 588,
    original_price: 598,
    residence_area: "全国",
    processing_days: 15,
    visa_validity: "3年",
    max_stay: "30天",
    success_rate: 98.5,
    material_count: 6,
    can_simplify: true,
    home_pickup: true,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "湖南宝中旅行社专营店",
    sales_count: 3500,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    country_id: countries["JP"].id,
    name: "日本五年多次签证",
    product_type: "多次签证",
    price: 788,
    original_price: 798,
    residence_area: "全国",
    processing_days: 20,
    visa_validity: "5年",
    max_stay: "90天",
    success_rate: 96.2,
    material_count: 7,
    can_simplify: false,
    home_pickup: true,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "中国旅行社总社湖南专营店",
    sales_count: 2800,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 韩国签证产品
visa_products_data.concat([
  {
    country_id: countries["KR"].id,
    name: "韩国团体旅游签证",
    product_type: "团体签证",
    price: 108,
    original_price: 113,
    residence_area: "全国",
    processing_days: 5,
    visa_validity: "90天",
    max_stay: "30天",
    success_rate: 100.0,
    material_count: 1,
    can_simplify: true,
    home_pickup: true,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "湖南新康辉国旅旗舰店",
    sales_count: 7000,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    country_id: countries["KR"].id,
    name: "韩国单次签证",
    product_type: "单次签证",
    price: 433,
    original_price: 438,
    residence_area: "全国",
    processing_days: 8,
    visa_validity: "90天",
    max_stay: "30天",
    success_rate: 97.8,
    material_count: 4,
    can_simplify: true,
    home_pickup: true,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "武汉碧海蓝天旅游专营店",
    sales_count: 10000,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 美国签证产品
visa_products_data.concat([
  {
    country_id: countries["US"].id,
    name: "美国旅游商务签证（B1/B2）",
    product_type: "旅游商务签证",
    price: 1288,
    original_price: 1298,
    residence_area: "全国",
    processing_days: 30,
    visa_validity: "10年",
    max_stay: "180天",
    success_rate: 95.5,
    material_count: 8,
    can_simplify: false,
    home_pickup: true,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "湖南宝中旅行社专营店",
    sales_count: 5200,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    country_id: countries["US"].id,
    name: "美国旅游商务签证（拒签退款）",
    product_type: "旅游商务签证",
    price: 1688,
    original_price: 1698,
    residence_area: "全国",
    processing_days: 35,
    visa_validity: "10年",
    max_stay: "180天",
    success_rate: 96.8,
    material_count: 8,
    can_simplify: false,
    home_pickup: true,
    refused_reapply: true,
    supports_family: true,
    merchant_name: "中国旅行社总社湖南专营店",
    sales_count: 3800,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 澳大利亚签证产品
visa_products_data.concat([
  {
    country_id: countries["AU"].id,
    name: "澳大利亚旅游签证（电子签）",
    product_type: "旅游签证",
    price: 1088,
    original_price: 1098,
    residence_area: "全国",
    processing_days: 20,
    visa_validity: "12个月",
    max_stay: "90天",
    success_rate: 98.5,
    material_count: 3,
    can_simplify: true,
    home_pickup: true,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "武汉碧海蓝天旅游专营店",
    sales_count: 6500,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    country_id: countries["AU"].id,
    name: "澳大利亚旅游签证（简化材料）",
    product_type: "旅游签证",
    price: 1288,
    original_price: 1298,
    residence_area: "全国",
    processing_days: 18,
    visa_validity: "12个月",
    max_stay: "90天",
    success_rate: 99.2,
    material_count: 2,
    can_simplify: true,
    home_pickup: true,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "湖南宝中旅行社专营店",
    sales_count: 4800,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 法国签证产品
visa_products_data.concat([
  {
    country_id: countries["FR"].id,
    name: "法国旅游签证（申根签）",
    product_type: "旅游签证",
    price: 988,
    original_price: 998,
    residence_area: "全国",
    processing_days: 15,
    visa_validity: "90天",
    max_stay: "30天",
    success_rate: 97.5,
    material_count: 6,
    can_simplify: true,
    home_pickup: true,
    refused_reapply: true,
    supports_family: true,
    merchant_name: "湖南新康辉国旅旗舰店",
    sales_count: 7800,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    country_id: countries["FR"].id,
    name: "法国商务签证（申根签）",
    product_type: "商务签证",
    price: 1288,
    original_price: 1298,
    residence_area: "全国",
    processing_days: 12,
    visa_validity: "90天",
    max_stay: "30天",
    success_rate: 96.2,
    material_count: 7,
    can_simplify: false,
    home_pickup: true,
    refused_reapply: true,
    supports_family: true,
    merchant_name: "中国旅行社总社湖南专营店",
    sales_count: 4200,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 越南签证产品
visa_products_data.concat([
  {
    country_id: countries["VN"].id,
    name: "越南电子签证",
    product_type: "电子签证",
    price: 68,
    original_price: 73,
    residence_area: "全国",
    processing_days: 1,
    visa_validity: "90天",
    max_stay: "30天",
    success_rate: 100.0,
    material_count: 2,
    can_simplify: true,
    home_pickup: false,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "武汉碧海蓝天旅游专营店",
    sales_count: 18000,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 新加坡签证产品
visa_products_data.concat([
  {
    country_id: countries["SG"].id,
    name: "新加坡电子签证",
    product_type: "电子签证",
    price: 268,
    original_price: 278,
    residence_area: "全国",
    processing_days: 3,
    visa_validity: "63天",
    max_stay: "30天",
    success_rate: 100.0,
    material_count: 3,
    can_simplify: true,
    home_pickup: false,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "湖南宝中旅行社专营店",
    sales_count: 8500,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    country_id: countries["SG"].id,
    name: "新加坡两年多次签证",
    product_type: "多次签证",
    price: 388,
    original_price: 398,
    residence_area: "全国",
    processing_days: 5,
    visa_validity: "2年",
    max_stay: "30天",
    success_rate: 98.5,
    material_count: 4,
    can_simplify: true,
    home_pickup: false,
    refused_reapply: false,
    supports_family: true,
    merchant_name: "中国旅行社总社湖南专营店",
    sales_count: 5200,
    created_at: timestamp,
    updated_at: timestamp
  }
])

# ============================================
# 批量生成签证产品（避免文件过大）
# ============================================

merchants = ["湖南新康辉国旅旗舰店", "武汉碧海蓝天旅游专营店", "湖南宝中旅行社专营店", "中国旅行社总社湖南专营店"]

# 马来西亚签证产品（3个）
[
  { type: "电子签证", price: 128, days: 1, materials: 2, pickup: false, validity: "90天", stay: "30天", rate: 100.0 },
  { type: "旅游签证", price: 188, days: 3, materials: 3, pickup: true, validity: "90天", stay: "30天", rate: 99.5 },
  { type: "商务签证", price: 388, days: 5, materials: 5, pickup: true, validity: "90天", stay: "30天", rate: 98.0 }
].each_with_index do |config, i|
  visa_products_data << {
    country_id: countries["MY"].id,
    name: "马来西亚#{config[:type]}",
    product_type: config[:type],
    price: config[:price],
    original_price: config[:price] + 10,
    residence_area: "全国",
    processing_days: config[:days],
    visa_validity: config[:validity],
    max_stay: config[:stay],
    success_rate: config[:rate],
    material_count: config[:materials],
    can_simplify: config[:materials] <= 3,
    home_pickup: config[:pickup],
    refused_reapply: false,
    supports_family: config[:type] != "商务签证",
    merchant_name: merchants[i % merchants.size],
    sales_count: 12000 - i * 3000,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 越南签证产品（3个）
[
  { type: "电子签证", price: 68, days: 1, materials: 2, validity: "90天" },
  { type: "旅游签证", price: 118, days: 3, materials: 2, validity: "90天" },
  { type: "商务签证", price: 288, days: 5, materials: 4, validity: "90天" }
].each_with_index do |config, i|
  visa_products_data << {
    country_id: countries["VN"].id,
    name: "越南#{config[:type]}",
    product_type: config[:type],
    price: config[:price],
    original_price: config[:price] + 10,
    residence_area: "全国",
    processing_days: config[:days],
    visa_validity: config[:validity],
    max_stay: "30天",
    success_rate: 100.0 - i * 0.5,
    material_count: config[:materials],
    can_simplify: true,
    home_pickup: i > 0,
    refused_reapply: false,
    supports_family: config[:type] != "商务签证",
    merchant_name: merchants[i % merchants.size],
    sales_count: 18000 - i * 5000,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 泰国签证产品（扩充到4个）
[
  { type: "落地签证", price: 58, days: 0, materials: 1, validity: "15天", stay: "15天" },
  { type: "商务签证", price: 488, days: 5, materials: 5, validity: "90天", stay: "90天" }
].each_with_index do |config, i|
  visa_products_data << {
    country_id: countries["TH"].id,
    name: "泰国#{config[:type]}",
    product_type: config[:type],
    price: config[:price],
    original_price: config[:price] + 10,
    residence_area: "全国",
    processing_days: config[:days],
    visa_validity: config[:validity],
    max_stay: config[:stay],
    success_rate: 100.0 - i * 0.5,
    material_count: config[:materials],
    can_simplify: true,
    home_pickup: i > 0,
    refused_reapply: false,
    supports_family: config[:type] != "商务签证",
    merchant_name: merchants[i % merchants.size],
    sales_count: 22000 - i * 8000,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 美国签证产品（扩充到4个）
[
  { type: "学生签证", name: "美国学生签证（F1/M1）", price: 1888, days: 25, materials: 10, validity: "5年", stay: "按I-20表" },
  { type: "探亲访友签证", name: "美国探亲访友签证（B2）", price: 1388, days: 28, materials: 9, validity: "10年", stay: "180天" }
].each_with_index do |config, i|
  visa_products_data << {
    country_id: countries["US"].id,
    name: config[:name],
    product_type: config[:type],
    price: config[:price],
    original_price: config[:price] + 110,
    residence_area: "全国",
    processing_days: config[:days],
    visa_validity: config[:validity],
    max_stay: config[:stay],
    success_rate: 94.5 - i * 0.7,
    material_count: config[:materials],
    can_simplify: false,
    home_pickup: true,
    refused_reapply: true,
    supports_family: config[:type] == "探亲访友签证",
    merchant_name: merchants[i % merchants.size],
    sales_count: 3800 - i * 500,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 澳大利亚签证产品（扩充到4个）
[
  { type: "多次签证", name: "澳大利亚三年多次签证", price: 1488, days: 22, materials: 5, validity: "3年" },
  { type: "商务签证", name: "澳大利亚商务签证", price: 1688, days: 18, materials: 7, validity: "12个月" }
].each_with_index do |config, i|
  visa_products_data << {
    country_id: countries["AU"].id,
    name: config[:name],
    product_type: config[:type],
    price: config[:price],
    original_price: config[:price] + 110,
    residence_area: "全国",
    processing_days: config[:days],
    visa_validity: config[:validity],
    max_stay: "90天",
    success_rate: 97.2 - i * 0.7,
    material_count: config[:materials],
    can_simplify: config[:type] == "多次签证",
    home_pickup: true,
    refused_reapply: true,
    supports_family: config[:type] != "商务签证",
    merchant_name: merchants[i % merchants.size],
    sales_count: 4500 - i * 1600,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 英国签证产品（3个）
[
  { type: "旅游签证", price: 1588, days: 25, materials: 7 },
  { type: "商务签证", price: 1788, days: 20, materials: 8 },
  { type: "学生签证", name: "英国学生签证（Tier 4）", price: 1988, days: 30, materials: 10, validity: "按CAS有效期", stay: "按课程长度" }
].each_with_index do |config, i|
  visa_products_data << {
    country_id: countries["GB"].id,
    name: config[:name] || "英国#{config[:type]}",
    product_type: config[:type],
    price: config[:price],
    original_price: config[:price] + 100,
    residence_area: "全国",
    processing_days: config[:days],
    visa_validity: config[:validity] || "2年",
    max_stay: config[:stay] || "180天",
    success_rate: 95.5 - i * 1.4,
    material_count: config[:materials],
    can_simplify: false,
    home_pickup: true,
    refused_reapply: true,
    supports_family: config[:type] == "旅游签证",
    merchant_name: merchants[i % merchants.size],
    sales_count: 2800 - i * 600,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 法国签证产品（扩充到4个）
[
  { type: "探亲访友签证", name: "法国申根探亲签证", price: 1088, days: 18, materials: 7 },
  { type: "学生签证", name: "法国申根学生签证", price: 1388, days: 20, materials: 9, stay: "按录取通知书" }
].each_with_index do |config, i|
  visa_products_data << {
    country_id: countries["FR"].id,
    name: config[:name],
    product_type: config[:type],
    price: config[:price],
    original_price: config[:price] + 100,
    residence_area: "全国",
    processing_days: config[:days],
    visa_validity: "90天",
    max_stay: config[:stay] || "30天",
    success_rate: 97.2 - i * 0.4,
    material_count: config[:materials],
    can_simplify: false,
    home_pickup: true,
    refused_reapply: true,
    supports_family: config[:type] == "探亲访友签证",
    merchant_name: merchants[i % merchants.size],
    sales_count: 4500 - i * 1300,
    created_at: timestamp,
    updated_at: timestamp
  }
end

# 新西兰签证产品（3个）
[
  { type: "旅游签证", price: 1188, days: 20, materials: 6, validity: "1年" },
  { type: "多次签证", name: "新西兰两年多次签证", price: 1388, days: 18, materials: 5, validity: "2年" },
  { type: "商务签证", price: 1488, days: 22, materials: 7, validity: "1年" }
].each_with_index do |config, i|
  visa_products_data << {
    country_id: countries["NZ"].id,
    name: config[:name] || "新西兰#{config[:type]}",
    product_type: config[:type],
    price: config[:price],
    original_price: config[:price] + 100,
    residence_area: "全国",
    processing_days: config[:days],
    visa_validity: config[:validity],
    max_stay: "90天",
    success_rate: 97.5 - i * 0.8,
    material_count: config[:materials],
    can_simplify: config[:type] == "多次签证",
    home_pickup: true,
    refused_reapply: true,
    supports_family: config[:type] != "商务签证",
    merchant_name: merchants[i % merchants.size],
    sales_count: 3800 - i * 1200,
    created_at: timestamp,
    updated_at: timestamp
  }
end

VisaProduct.insert_all(visa_products_data)

# ============================================
# 第三步：创建签证服务数据（原有数据）
# ============================================

# 准备所有签证服务数据
visa_services_data = []

# 韩国签证服务
visa_services_data.concat([
  {
    title: "韩国·团体旅游签证·全国送签·官方直营·韩国自由行【只需护照】5-8工作日出签",
    country: "韩国",
    service_type: "全国送签",
    success_rate: 100.0,
    processing_days: 5,
    price: 108,
    original_price: 113,
    urgent_processing: false,
    description: "韩国团体旅游签证，全国送签，只需护照，5-8工作日出签",
    merchant_name: "湖南新康辉国旅旗舰店",
    sales_count: 700,
    image_url: "https://images.unsplash.com/photo-1517154421773-0529f29ea451?w=400",
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "韩国·单次签证·武汉送签·韩国个人旅游单次签证武汉领区河南湖南湖北江西",
    country: "韩国",
    service_type: "武汉送签",
    success_rate: 97.8,
    processing_days: 8,
    price: 433,
    original_price: 438,
    urgent_processing: false,
    description: "韩国单次签证，武汉送签，覆盖河南湖南湖北江西",
    merchant_name: "武汉碧海蓝天旅游专营店",
    sales_count: 1000,
    image_url: "https://images.unsplash.com/photo-1583474439862-d2fd6d7a19e7?w=400",
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "韩国·单次签证·武汉送签·韩国签证个人旅游单次签证五年多次简化学生商务加急",
    country: "韩国",
    service_type: "武汉送签",
    success_rate: 99.3,
    processing_days: 10,
    price: 448,
    original_price: 453,
    urgent_processing: true,
    description: "韩国签证，支持五年多次，简化流程，加急办理",
    merchant_name: "湖北倾迷旅行社专营店",
    sales_count: 1000,
    image_url: "https://images.unsplash.com/photo-1532175402170-0ce0e1d850b7?w=400",
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 日本签证服务
visa_services_data.concat([
  {
    title: "日本·单次旅游签证·北京送签·【出签简单 拒签全退】个人旅游自由行在留简化签证",
    country: "日本",
    service_type: "北京送签",
    success_rate: 100.0,
    processing_days: 18,
    price: 191,
    original_price: 196,
    urgent_processing: false,
    description: "日本单次旅游签证，出签简单，拒签全退，个人旅游自由行",
    merchant_name: "湖南宝中旅行社专营店",
    sales_count: 600,
    image_url: "https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=400",
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "日本·单次旅游签证·北京送签·【拒一赔三】加急办理电子签证简化学生商务多次往返",
    country: "日本",
    service_type: "北京送签",
    success_rate: 100.0,
    processing_days: 10,
    price: 448,
    original_price: 453,
    urgent_processing: true,
    description: "日本签证加急办理，拒一赔三，电子签证简化流程",
    merchant_name: "中国旅行社总社湖南专营店",
    sales_count: 1000,
    image_url: "https://images.unsplash.com/photo-1528164344705-47542687000d?w=400",
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "日本·三年多次签证·北京送签·冲绳/东北三县首次必访·免在留·简化材料",
    country: "日本",
    service_type: "北京送签",
    success_rate: 98.5,
    processing_days: 15,
    price: 588,
    original_price: 598,
    urgent_processing: false,
    description: "日本三年多次签证，冲绳/东北三县首次必访，免在留，简化材料",
    merchant_name: "湖南宝中旅行社专营店",
    sales_count: 350,
    image_url: "https://images.unsplash.com/photo-1542640244-7e672d6cef4e?w=400",
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "日本·五年多次签证·北京送签·简化办理·免在留·高出签率·全国受理",
    country: "日本",
    service_type: "北京送签",
    success_rate: 96.2,
    processing_days: 20,
    price: 788,
    original_price: 798,
    urgent_processing: false,
    description: "日本五年多次签证，简化办理，免在留，高出签率，全国受理",
    merchant_name: "中国旅行社总社湖南专营店",
    sales_count: 280,
    image_url: "https://images.unsplash.com/photo-1480796927426-f609979314bd?w=400",
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 泰国签证服务
visa_services_data.concat([
  {
    title: "泰国·旅游签证·全国送签·【1-2工作日极速出签】代办泰国签证个人旅游自由行",
    country: "泰国",
    service_type: "全国送签",
    success_rate: 100.0,
    processing_days: 2,
    price: 88,
    original_price: 93,
    urgent_processing: true,
    description: "泰国旅游签证，1-2工作日极速出签，代办个人旅游自由行",
    merchant_name: "湖南新康辉国旅旗舰店",
    sales_count: 1500,
    image_url: "https://images.unsplash.com/photo-1552465011-b4e21bf6e79a?w=400",
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "泰国·电子签证·全国办理·【3工作日出签】泰国电子签证在线办理eVisa",
    country: "泰国",
    service_type: "全国送签",
    success_rate: 99.8,
    processing_days: 3,
    price: 158,
    original_price: 163,
    urgent_processing: false,
    description: "泰国电子签证，3工作日出签，在线办理eVisa",
    merchant_name: "武汉碧海蓝天旅游专营店",
    sales_count: 980,
    image_url: "https://images.unsplash.com/photo-1528181304800-259b08848526?w=400",
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 新加坡签证服务
visa_services_data.concat([
  {
    title: "新加坡·电子签证·全国送签·【极速2-3工作日】新加坡签证个人旅游63天电子签",
    country: "新加坡",
    service_type: "全国送签",
    success_rate: 100.0,
    processing_days: 3,
    price: 268,
    original_price: 278,
    urgent_processing: true,
    description: "新加坡电子签证，极速2-3工作日，63天有效期",
    merchant_name: "湖南宝中旅行社专营店",
    sales_count: 850,
    image_url: "https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=400",
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "新加坡·两年多次签证·全国送签·简化材料·高出签率·商务旅游通用",
    country: "新加坡",
    service_type: "全国送签",
    success_rate: 98.5,
    processing_days: 5,
    price: 388,
    original_price: 398,
    urgent_processing: false,
    description: "新加坡两年多次签证，简化材料，高出签率，商务旅游通用",
    merchant_name: "中国旅行社总社湖南专营店",
    sales_count: 520,
    image_url: "https://images.unsplash.com/photo-1565967511849-76a60a516170?w=400",
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 马来西亚签证服务
visa_services_data.concat([
  {
    title: "马来西亚·电子签证·全国办理·【24小时极速出签】马来西亚eVISA电子签证",
    country: "马来西亚",
    service_type: "全国送签",
    success_rate: 100.0,
    processing_days: 1,
    price: 128,
    original_price: 133,
    urgent_processing: true,
    description: "马来西亚电子签证，24小时极速出签，eVISA电子签证",
    merchant_name: "湖南新康辉国旅旗舰店",
    sales_count: 1200,
    image_url: "https://images.unsplash.com/photo-1596422846543-75c6fc197f07?w=400",
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 越南签证服务
visa_services_data.concat([
  {
    title: "越南·电子签证·全国办理·【1工作日出签】越南签证个人旅游eVISA电子签",
    country: "越南",
    service_type: "全国送签",
    success_rate: 100.0,
    processing_days: 1,
    price: 68,
    original_price: 73,
    urgent_processing: true,
    description: "越南电子签证，1工作日出签，个人旅游eVISA",
    merchant_name: "武汉碧海蓝天旅游专营店",
    sales_count: 1800,
    image_url: "https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=400",
    created_at: timestamp,
    updated_at: timestamp
  }
])

# 批量插入所有签证服务
VisaService.insert_all(visa_services_data)

puts "  - 韩国签证: 3 个商品"
puts "  - 日本签证: 4 个商品"
puts "  - 泰国签证: 2 个商品"
puts "  - 新加坡签证: 2 个商品"
puts "  - 马来西亚签证: 1 个商品"
puts "  - 越南签证: 1 个商品"

# ============================================
# 最终统计
# ============================================
puts "\n" + "="*50
puts "✅ 签证数据加载完成！"
puts "="*50
puts "国家总数: #{Country.count}"
puts "签证产品总数: #{VisaProduct.count}"
puts "签证服务总数: #{VisaService.count}"
puts "="*50
