# frozen_string_literal: true

# 旅游产品数据补充包 - 补充三亚6天5晚跟团游
# 加载方式: rails runner "load Rails.root.join('app/validators/support/data_packs/v1/tour_groups_supplement.rb')"


timestamp = Time.current
start_date = Date.today
end_date = start_date + 6.days

# 确保有demo用户和旅行社
demo_user = User.find_or_create_by(email: "demo@travel01.com") do |u|
  u.password_digest = BCrypt::Password.create("password123")
  u.data_version = 0
end

# 查找或创建海南椰风假期旅行社
agency = TravelAgency.find_or_create_by(name: "海南椰风假期") do |a|
  a.rating = 4.9
  a.sales_count = 6500
  a.is_verified = true
  a.created_at = timestamp
  a.updated_at = timestamp
end

# 补充三亚6天5晚跟团游产品
products_data = []

# 从三亚出发的6天5晚游
['三亚', '海口', '广州', '深圳'].each do |departure_city|
  3.times do |i|
    base_price = rand(3288..5088)
    original_price = (base_price * rand(1.15..1.35)).to_i
    
    attractions = ['蜈支洲岛', '亚龙湾', '天涯海角', '南山寺', '呀诺达雨林', '大小洞天'].sample(4)
    
    title = "【精品小团】三亚#{attractions.join('+')} 6天5晚 #{rand(6..10)}人团 含酒店·含餐食·含门票"
    subtitle = [attractions.first, '纯玩团', '无购物'].join('·')
    
    products_data << {
      title: title,
      subtitle: subtitle,
      destination: "三亚",
      departure_city: departure_city,
      tour_category: 'group_tour',
      travel_type: '跟团游',
      duration: 6,
      badge: "多日游·#{rand(6..10)}人团",
      price: base_price,
      original_price: original_price,
      rating: [4.7, 4.8, 4.9, 5.0].sample,
      rating_desc: "#{rand(50..500)}条评价",
      sales_count: rand(100..1000),
      highlights: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物'].sample(rand(2..3)),
      tags: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物', '深度游览'].sample(rand(3..5)),
      departure_label: "#{departure_city}出发",
      is_featured: i == 0,
      display_order: 0,
      image_url: "https://images.unsplash.com/photo-#{rand(1500000000000..1700000000000)}-#{SecureRandom.hex(8)}?w=400&h=600",
      travel_agency_id: agency.id,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

TourGroupProduct.insert_all(products_data) if products_data.any?

# 为新产品创建套餐
all_packages_data = []

TourGroupProduct.where(destination: "三亚", duration: 6, data_version: 0).where("created_at >= ?", timestamp - 1.minute).find_each do |product|
  # 每个产品生成2-3个套餐
  packages_count = rand(2..3)
  
  packages_count.times do |i|
    base_price = product.price
    
    package_price = case i
    when 0 then base_price
    when 1 then (base_price * rand(1.2..1.4)).to_i
    when 2 then (base_price * rand(1.5..1.8)).to_i
    end
    
    child_price = (package_price * rand(0.6..0.8)).to_i
    
    package_names = case i
    when 0 then ['基础套餐', '经济套餐', '标准套餐']
    when 1 then ['豪华套餐', '高级套餐', '优选套餐']
    when 2 then ['至尊套餐', '尊享套餐', 'VIP套餐']
    end
    
    description = case i
    when 0
      "✓ 三星级酒店住宿\n✓ 包含早餐\n✓ 景点首道门票\n✓ 旅游大巴接送\n✓ 专业导游服务"
    when 1
      "✓ 四星级酒店住宿\n✓ 包含早餐+午餐\n✓ 景点门票+特色体验\n✓ 豪华旅游大巴\n✓ 金牌导游服务\n✓ 赠送旅游意外险"
    when 2
      "✓ 五星级酒店住宿\n✓ 包含三餐(含特色餐)\n✓ 景点VIP通道+深度体验\n✓ 商务车接送\n✓ 资深导游一对一服务\n✓ 赠送旅游意外险+旅拍服务"
    end
    
    all_packages_data << {
      tour_group_product_id: product.id,
      name: package_names.sample,
      price: package_price,
      child_price: child_price,
      description: description,
      is_featured: i == 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

TourPackage.insert_all(all_packages_data) if all_packages_data.any?

