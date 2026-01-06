# 清理旧数据
TourGroupProduct.destroy_all
TravelAgency.destroy_all

puts "🏢 创建旅行社..."

# 创建旅行社
agencies = [
  { name: '天津梦远旅行社专营店', rating: 4.9, sales_count: 9000, is_verified: true },
  { name: '北京趣发现旅行社专营店', rating: 4.7, sales_count: 500, is_verified: true },
  { name: '江苏五方旅行社', rating: 4.8, sales_count: 3000, is_verified: true },
  { name: '上海春秋旅行社', rating: 4.9, sales_count: 15000, is_verified: true },
  { name: '携程旅行专营店', rating: 4.8, sales_count: 8000, is_verified: true },
  { name: '杭州携程国际旅行社', rating: 4.9, sales_count: 12000, is_verified: true },
  { name: '广州青旅国际旅行社', rating: 4.7, sales_count: 6000, is_verified: true },
  { name: '深圳康辉旅行社', rating: 4.8, sales_count: 7500, is_verified: true }
]

travel_agencies = agencies.map { |attrs| TravelAgency.create!(attrs) }

puts "✓ 创建了 #{TravelAgency.count} 家旅行社"

puts "🎫 创建旅游产品..."

# 上海相关产品
tour_products = [
  # 一日游产品
  {
    travel_agency: travel_agencies[0],
    title: '上海+上海天文馆+一日游+随时可定+上午下午场大咖讲解',
    tour_category: 'group_tour',
    destination: '上海',
    duration: 1,
    departure_city: '上海',
    price: 68,
    original_price: 88,
    rating: 4.9,
    rating_desc: '讲解生动，孩子爱听',
    highlights: ['上海天文馆', '研学'],
    tags: ['可订明日', '无自费', '纯玩无购物'],
    sales_count: 9000,
    badge: '一日游',
    departure_label: '上海出发',
    image_url: 'https://images.unsplash.com/photo-1464037866556-6812c9d1c72e?w=600',
    is_featured: true,
    display_order: 1
  },
  {
    travel_agency: travel_agencies[1],
    title: '上海+上海科技馆+一日游+快速出票+大咖讲解+精品小团',
    tour_category: 'group_tour',
    destination: '上海',
    duration: 1,
    departure_city: '上海',
    price: 25,
    original_price: 35,
    rating: 0,
    highlights: ['无购物', '无自费'],
    tags: ['无自费', '无购物'],
    sales_count: 7,
    badge: '一日游',
    image_url: 'https://images.unsplash.com/photo-1550592704-6c76defa9985?w=600',
    display_order: 2
  },
  {
    travel_agency: travel_agencies[2],
    title: '上海+东方明珠/城市历史发展陈列馆/外滩+一日游+观魔都美景历史...',
    tour_category: 'group_tour',
    destination: '上海',
    duration: 1,
    departure_city: '上海',
    price: 109,
    original_price: 139,
    rating: 4.9,
    rating_desc: '东方明珠美景入画来',
    highlights: ['外滩', '上海城市历史发展陈列馆', '东方明珠'],
    tags: ['可订今日', '无自费', '纯玩无购物', '支持改期'],
    sales_count: 1000,
    badge: '一日游',
    departure_label: '上海出发',
    image_url: 'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=600',
    display_order: 3
  },
  {
    travel_agency: travel_agencies[4],
    title: '上海+朱家角古镇+一日游+纯玩无购物+含午餐',
    tour_category: 'group_tour',
    destination: '上海',
    duration: 1,
    departure_city: '上海',
    price: 128,
    original_price: 158,
    rating: 4.7,
    rating_desc: '古镇风情浓郁',
    highlights: ['朱家角古镇', '江南水乡', '含午餐'],
    tags: ['纯玩无购物', '无自费', '含餐'],
    sales_count: 3000,
    badge: '一日游',
    departure_label: '上海出发',
    image_url: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600',
    display_order: 5
  },

  # 多日游产品
  {
    travel_agency: travel_agencies[3],
    title: '上海+迪士尼乐园+2日游+含门票+精选酒店+往返接送',
    tour_category: 'group_tour',
    destination: '上海',
    duration: 2,
    departure_city: '上海',
    price: 899,
    original_price: 1299,
    rating: 4.8,
    rating_desc: '迪士尼梦幻之旅',
    highlights: ['迪士尼乐园', '含门票', '接送服务'],
    tags: ['可订明日', '含酒店', '含门票'],
    sales_count: 5000,
    badge: '跟团游',
    departure_label: '上海出发',
    image_url: 'https://images.unsplash.com/photo-1548919973-5cef591cdbc9?w=600',
    is_featured: true,
    display_order: 4
  },
  {
    travel_agency: travel_agencies[5],
    title: '上海+苏州+杭州+3日游+经典江南三城+含住宿',
    tour_category: 'group_tour',
    destination: '上海',
    duration: 3,
    departure_city: '上海',
    price: 1299,
    original_price: 1699,
    rating: 4.9,
    rating_desc: '江南美景尽收眼底',
    highlights: ['苏州园林', '西湖', '乌镇'],
    tags: ['精品小团', '含酒店', '纯玩'],
    sales_count: 8000,
    badge: '跟团游',
    departure_label: '上海出发',
    image_url: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600',
    is_featured: true,
    display_order: 6
  },

  # 北京相关产品
  {
    travel_agency: travel_agencies[3],
    title: '北京+故宫+长城+颐和园+3日游+纯玩无购物',
    tour_category: 'group_tour',
    destination: '北京',
    duration: 3,
    departure_city: '北京',
    price: 1099,
    original_price: 1399,
    rating: 4.8,
    rating_desc: '经典必游线路',
    highlights: ['故宫', '长城', '颐和园'],
    tags: ['纯玩无购物', '含酒店', '无自费'],
    sales_count: 6500,
    badge: '跟团游',
    departure_label: '北京出发',
    image_url: 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=600',
    display_order: 7
  },
  {
    travel_agency: travel_agencies[1],
    title: '北京+故宫深度游+专业讲解+一日游',
    tour_category: 'group_tour',
    destination: '北京',
    duration: 1,
    departure_city: '北京',
    price: 158,
    original_price: 198,
    rating: 4.9,
    rating_desc: '讲解专业详细',
    highlights: ['故宫', '专业讲解', '深度游'],
    tags: ['可订明日', '纯玩无购物', '无自费'],
    sales_count: 4200,
    badge: '一日游',
    departure_label: '北京出发',
    image_url: 'https://images.unsplash.com/photo-1537069042836-4f8c5f2e1f2c?w=600',
    display_order: 8
  },

  # 杭州相关产品
  {
    travel_agency: travel_agencies[5],
    title: '杭州+西湖+灵隐寺+一日游+含午餐+纯玩团',
    tour_category: 'group_tour',
    destination: '杭州',
    duration: 1,
    departure_city: '杭州',
    price: 88,
    original_price: 118,
    rating: 4.7,
    rating_desc: '西湖美景如画',
    highlights: ['西湖', '灵隐寺', '含午餐'],
    tags: ['纯玩无购物', '含餐', '无自费'],
    sales_count: 5600,
    badge: '一日游',
    departure_label: '杭州出发',
    image_url: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600',
    display_order: 9
  },
  {
    travel_agency: travel_agencies[5],
    title: '杭州+乌镇+西塘+2日游+水乡古镇+含住宿',
    tour_category: 'group_tour',
    destination: '杭州',
    duration: 2,
    departure_city: '杭州',
    price: 599,
    original_price: 799,
    rating: 4.8,
    rating_desc: '水乡风情浓郁',
    highlights: ['乌镇', '西塘', '水乡古镇'],
    tags: ['精品小团', '含酒店', '纯玩'],
    sales_count: 4800,
    badge: '跟团游',
    departure_label: '杭州出发',
    image_url: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600',
    display_order: 10
  },

  # 广州相关产品
  {
    travel_agency: travel_agencies[6],
    title: '广州+长隆野生动物园+一日游+含门票+往返接送',
    tour_category: 'group_tour',
    destination: '广州',
    duration: 1,
    departure_city: '广州',
    price: 258,
    original_price: 328,
    rating: 4.9,
    rating_desc: '动物种类丰富',
    highlights: ['长隆野生动物园', '含门票', '接送服务'],
    tags: ['可订明日', '含门票', '接送服务'],
    sales_count: 7200,
    badge: '一日游',
    departure_label: '广州出发',
    image_url: 'https://images.unsplash.com/photo-1564760055775-d63b17a55c44?w=600',
    display_order: 11
  },
  {
    travel_agency: travel_agencies[6],
    title: '广州+珠海+长隆+2日游+双园联游+含住宿',
    tour_category: 'group_tour',
    destination: '广州',
    duration: 2,
    departure_city: '广州',
    price: 799,
    original_price: 999,
    rating: 4.8,
    rating_desc: '性价比超高',
    highlights: ['长隆野生动物园', '长隆海洋王国', '双园联游'],
    tags: ['精品小团', '含酒店', '含门票'],
    sales_count: 6300,
    badge: '跟团游',
    departure_label: '广州出发',
    image_url: 'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=600',
    display_order: 12
  },

  # 成都相关产品
  {
    travel_agency: travel_agencies[7],
    title: '成都+九寨沟+黄龙+4日游+纯玩团+含住宿',
    tour_category: 'group_tour',
    destination: '成都',
    duration: 4,
    departure_city: '成都',
    price: 1599,
    original_price: 1999,
    rating: 4.9,
    rating_desc: '美景令人震撼',
    highlights: ['九寨沟', '黄龙', '纯玩团'],
    tags: ['精品小团', '含酒店', '纯玩无购物'],
    sales_count: 5500,
    badge: '跟团游',
    departure_label: '成都出发',
    image_url: 'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=600',
    display_order: 13
  },
  {
    travel_agency: travel_agencies[7],
    title: '成都+熊猫基地+一日游+含门票+专业讲解',
    tour_category: 'group_tour',
    destination: '成都',
    duration: 1,
    departure_city: '成都',
    price: 138,
    original_price: 178,
    rating: 4.8,
    rating_desc: '熊猫超级可爱',
    highlights: ['熊猫基地', '含门票', '专业讲解'],
    tags: ['可订明日', '含门票', '无自费'],
    sales_count: 8900,
    badge: '一日游',
    departure_label: '成都出发',
    image_url: 'https://images.unsplash.com/photo-1564760055775-d63b17a55c44?w=600',
    display_order: 14
  },

  # 私家团/精品小团
  {
    travel_agency: travel_agencies[3],
    title: '上海+周边古镇+2日私家团+专车专导+豪华酒店',
    tour_category: 'private_group',
    destination: '上海',
    duration: 2,
    departure_city: '上海',
    price: 2999,
    original_price: 3999,
    rating: 5.0,
    rating_desc: '服务超级贴心',
    highlights: ['私家团', '专车专导', '豪华酒店'],
    tags: ['2-6人', '专车专导', '高端品质'],
    sales_count: 320,
    badge: '私家团',
    departure_label: '上海出发',
    image_url: 'https://images.unsplash.com/photo-1548919973-5cef591cdbc9?w=600',
    is_featured: true,
    display_order: 15
  },
  {
    travel_agency: travel_agencies[5],
    title: '杭州+黄山+宏村+3日私家团+专车专导',
    tour_category: 'private_group',
    destination: '杭州',
    duration: 3,
    departure_city: '杭州',
    price: 3599,
    original_price: 4599,
    rating: 4.9,
    rating_desc: '行程自由灵活',
    highlights: ['黄山', '宏村', '专车专导'],
    tags: ['2-6人', '专车专导', '纯玩无购物'],
    sales_count: 280,
    badge: '私家团',
    departure_label: '杭州出发',
    image_url: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=600',
    display_order: 16
  }
]

tour_products.each do |product_attrs|
  product = TourGroupProduct.create!(product_attrs)
  
  # 为上海天文馆产品创建合理的套餐数据
  if product.title.include?('上海天文馆')
    # 删除旧套餐
    product.tour_packages.destroy_all
    
    # 创建新套餐：同一路线的不同出发时间和配置
    product.tour_packages.create!([
      {
        name: '上午场标准套餐',
        description: '含天文馆门票+专业讲解|游玩约2.5小时|上午9:30出发|最多15人精品小团',
        price: 68,
        child_price: 48,
        is_featured: false,
        display_order: 1,
        purchase_count: 320
      },
      {
        name: '上午场豪华套餐',
        description: '含天文馆门票+球幕影院IMAX+专业讲解|游玩约3小时|上午9:30出发|赠送纪念品|最多15人精品小团',
        price: 88,
        child_price: 68,
        is_featured: true,
        display_order: 2,
        purchase_count: 450
      },
      {
        name: '下午场标准套餐',
        description: '含天文馆门票+专业讲解|游玩约2.5小时|下午14:00出发|最多15人精品小团',
        price: 68,
        child_price: 48,
        is_featured: false,
        display_order: 3,
        purchase_count: 280
      }
    ])
  end
end

puts "✓ 创建了 #{TourGroupProduct.count} 个旅游产品"
puts "  - 跟团游: #{TourGroupProduct.by_category('group_tour').count} 个"
puts "  - 私家团: #{TourGroupProduct.by_category('private_group').count} 个"
puts "  - 上海相关: #{TourGroupProduct.by_destination('上海').count} 个"
puts "  - 北京相关: #{TourGroupProduct.by_destination('北京').count} 个"
puts "  - 杭州相关: #{TourGroupProduct.by_destination('杭州').count} 个"
puts "  - 广州相关: #{TourGroupProduct.by_destination('广州').count} 个"
puts "  - 成都相关: #{TourGroupProduct.by_destination('成都').count} 个"

puts "✅ 旅游产品种子数据创建完成！"
