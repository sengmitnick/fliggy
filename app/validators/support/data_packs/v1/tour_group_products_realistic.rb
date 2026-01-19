# 真实格式的旅游商品数据生成脚本
# 根据携程/美团旅游产品格式设计

# 清空现有数据
puts "清空现有数据..."
TourItineraryDay.destroy_all
TourPackage.destroy_all
TourGroupProduct.destroy_all
TravelAgency.destroy_all

# 目的地配置 - 中国主要旅游城市和地区
destinations_config = [
  { 
    name: '青海', 
    cities: ['西宁', '海北', '海南州', '海西'],
    attractions: ['青海湖', '茶卡盐湖', '日月山景区', '二郎剑景区', '岗什卡雪峰', '连心湖', '塔尔寺', '祁连山'],
    departure_cities: ['西宁', '兰州', '西安']
  },
  { 
    name: '云南', 
    cities: ['昆明', '大理', '丽江', '香格里拉'],
    attractions: ['洱海', '苍山', '玉龙雪山', '泸沽湖', '石林', '普达措', '虎跳峡', '古城'],
    departure_cities: ['昆明', '大理', '丽江']
  },
  { 
    name: '四川', 
    cities: ['成都', '九寨沟', '峨眉山', '乐山'],
    attractions: ['九寨沟', '黄龙', '峨眉山', '乐山大佛', '都江堰', '青城山', '稻城亚丁'],
    departure_cities: ['成都', '重庆']
  },
  { 
    name: '西藏', 
    cities: ['拉萨', '林芝', '日喀则'],
    attractions: ['布达拉宫', '大昭寺', '纳木错', '羊卓雍错', '雅鲁藏布江', '南迦巴瓦峰'],
    departure_cities: ['拉萨', '林芝', '成都']
  },
  { 
    name: '新疆', 
    cities: ['乌鲁木齐', '喀什', '伊犁'],
    attractions: ['天山天池', '喀纳斯', '赛里木湖', '那拉提草原', '巴音布鲁克', '禾木村'],
    departure_cities: ['乌鲁木齐', '伊宁']
  },
  { 
    name: '海南', 
    cities: ['三亚', '海口'],
    attractions: ['蜈支洲岛', '亚龙湾', '天涯海角', '南山寺', '分界洲岛', '呀诺达'],
    departure_cities: ['三亚', '海口']
  },
  { 
    name: '广西', 
    cities: ['桂林', '阳朔', '北海'],
    attractions: ['漓江', '象鼻山', '西街', '银子岩', '龙脊梯田', '涠洲岛'],
    departure_cities: ['桂林', '南宁']
  },
  { 
    name: '浙江', 
    cities: ['杭州', '千岛湖', '舟山'],
    attractions: ['西湖', '千岛湖', '普陀山', '乌镇', '西塘', '雁荡山'],
    departure_cities: ['杭州', '上海', '宁波']
  }
]

# 旅游类型配置
tour_types = [
  {
    category: 'free_travel',
    label: '一日游',
    badge_format: '一日游',
    durations: [1],
    weight: 30,
    title_templates: [
      '%{destination}%{city}%{attractions}一日游%{features}',
      '%{destination}+%{attractions}+一日游+%{features}',
      '%{city}%{attractions}一日游%{special}'
    ],
    features: ['上门接送', '含藏服体验', '含骑马', '含午餐', '含门票', '小团出行', '纯玩无购物', '当天往返'],
    special_tags: ['火爆热卖', '买到赚到', '春节特惠', '限时抢购']
  },
  {
    category: 'group_tour',
    label: '精品小团',
    badge_format: '多日游·%{group_size}人团',
    durations: [2, 3, 4, 5],
    weight: 40,
    title_templates: [
      '%{destination}%{city}%{attractions}+%{duration}天%{nights}晚+%{group_size}人小团%{features}',
      '%{city}%{multi_cities}%{attractions}%{duration}天%{features}',
      '%{destination}+%{attractions}+%{duration}天%{nights}晚+%{group_size}人团%{special}'
    ],
    group_sizes: [4, 6, 8, 10],
    features: ['含酒店', '含餐食', '含门票', '纯玩团', '含导游', '无购物', '精致小团'],
    special_tags: ['品质保障', '口碑推荐', '热卖爆款', '春节热卖']
  },
  {
    category: 'private_group',
    label: '多日游',
    badge_format: '多日游·独立成团',
    durations: [4, 5, 6, 7, 8],
    weight: 30,
    title_templates: [
      '%{destination}%{multi_cities}%{attractions}%{duration}天%{nights}晚深度游%{features}',
      '%{city}张掖%{extra_city}+%{attractions}+%{duration}天%{nights}晚%{features}',
      '%{destination}+%{attractions}+%{duration}天%{nights}晚+独立成团%{special}'
    ],
    features: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '专车专导', '行程自由', '深度游览'],
    special_tags: ['私人订制', '深度体验', '豪华团', '高端定制']
  }
]

# 创建旅行社
puts "创建旅行社..."
travel_agencies = []
agency_names = [
  '青海卓不凡旅行社专营店',
  '青海巨邦国际旅行社专营店',
  '容生行旅游旗舰店',
  '云南假日国际旅行社',
  '四川省中国旅行社',
  '西藏中国国际旅行社',
  '新疆天山旅行社',
  '海南椰风假期',
  '桂林山水假期',
  '杭州西湖国旅'
]

agency_names.each do |name|
  travel_agencies << TravelAgency.create!(
    name: name,
    description: "专业提供#{['国内游', '出境游', '周边游', '定制游'].sample}服务，#{['十年老店', '口碑商家', '金牌代理', '品质保障'].sample}",
    rating: (4.5 + rand * 0.5).round(1),
    sales_count: rand(100..5000),
    is_verified: true
  )
end

puts "创建的旅行社数量: #{travel_agencies.count}"

# 生成产品
puts "\n开始生成旅游产品..."
products_created = 0
packages_created = 0
itinerary_days_created = 0

destinations_config.each do |dest_config|
  puts "\n--- 生成 #{dest_config[:name]} 地区产品 ---"
  
  # 为每个目的地生成不同类型的产品
  tour_types.each do |tour_type|
    products_per_type = (tour_type[:weight] * 0.6).round # 每个目的地每种类型的产品数量
    
    products_per_type.times do
      duration = tour_type[:durations].sample
      nights = duration - 1
      
      # 随机选择景点（2-4个）
      attractions = dest_config[:attractions].sample(rand(2..4))
      
      # 生成标题
      template = tour_type[:title_templates].sample
      
      # 准备标题参数
      title_params = {
        destination: dest_config[:name],
        city: dest_config[:cities].sample,
        attractions: attractions.join('+'),
        duration: duration,
        nights: nights,
        features: tour_type[:features].sample(rand(1..2)).join('+')
      }
      
      # 多日游特殊参数
      if tour_type[:category] == 'group_tour' || tour_type[:category] == 'private_group'
        title_params[:multi_cities] = dest_config[:cities].sample(2).join('+')
        title_params[:extra_city] = ['海西', '海南', '张掖', '敦煌'].sample
        title_params[:group_size] = tour_type[:group_sizes]&.sample
      end
      
      title_params[:special] = tour_type[:features].sample(rand(2..3)).join('、')
      
      # 生成标题并截断（模拟真实产品标题会被省略）
      title = template % title_params
      title = title[0..50] + (title.length > 50 ? '...' : '')
      
      # 生成badge
      badge = if tour_type[:category] == 'free_travel'
        tour_type[:badge_format]
      elsif tour_type[:category] == 'group_tour'
        tour_type[:badge_format] % { group_size: tour_type[:group_sizes].sample }
      else
        tour_type[:badge_format]
      end
      
      # 生成副标题
      subtitle_parts = []
      subtitle_parts << attractions.first if attractions.any?
      subtitle_parts << (['赏雪', '观景', '纯玩', '含餐', '包车'].sample + rand(1..3).to_s + '晚') if duration > 1
      subtitle = subtitle_parts.join('·')
      
      # 选择旅行社
      agency = travel_agencies.sample
      
      # 创建产品
      product = TourGroupProduct.create!(
        title: title,
        subtitle: subtitle,
        destination: dest_config[:name],
        departure_city: dest_config[:departure_cities].sample,
        tour_category: tour_type[:category],
        duration: duration,
        
        # Badge
        badge: badge,
        
        # 价格
        price: case tour_type[:category]
               when 'free_travel'
                 rand(68..299)
               when 'group_tour'
                 duration * rand(200..400) + rand(100..500)
               when 'private_group'
                 duration * rand(300..600) + rand(200..800)
               end,
        original_price: nil, # 会自动计算
        
        # 评分和销量
        rating: [4.8, 4.9, 5.0].sample,
        rating_desc: "#{rand(50..500)}条评价",
        sales_count: rand(10..1000),
        
        # 亮点和标签
        highlights: tour_type[:features].sample(rand(2..3)),
        tags: (['提前12小时全额退', '可订明日', '无自费'] + tour_type[:features]).sample(rand(3..5)),
        
        # 其他信息
        departure_label: "#{dest_config[:departure_cities].sample}出发",
        is_featured: [true, false, false, false].sample, # 25%概率精选
        display_order: rand(1..100),
        image_url: "https://images.unsplash.com/photo-#{rand(1500000000000..1700000000000)}-#{SecureRandom.hex(8)}?w=400&h=600&fit=crop",
        
        travel_agency: agency
      )
      
      products_created += 1
      
      # 创建套餐（1-3个）
      package_types = ['标准套餐', '豪华套餐', '尊享套餐']
      rand(1..3).times do |i|
        package = product.tour_packages.create!(
          name: package_types[i],
          description: "#{package_types[i]}包含#{['酒店', '用餐', '门票', '交通'].sample(rand(2..4)).join('、')}",
          price: product.price + (i * rand(100..300)),
          display_order: i + 1
        )
        packages_created += 1
      end
      
      # 创建行程（根据天数）
      duration.times do |day_num|
        itinerary = product.tour_itinerary_days.create!(
          day_number: day_num + 1,
          title: "Day#{day_num + 1} #{attractions[day_num % attractions.length] || '自由活动'}",
          attractions: [attractions[day_num % attractions.length] || '自由活动'],
          service_info: "今日游览#{attractions[day_num % attractions.length] || '自由活动'}，体验当地特色。",
          duration_minutes: rand(240..600)
        )
        itinerary_days_created += 1
      end
      
      print "."
    end
  end
end

puts "\n\n=== 数据生成完成 ==="
puts "旅行社: #{travel_agencies.count}"
puts "产品总数: #{products_created}"
puts "  - 一日游: #{TourGroupProduct.where(tour_category: 'free_travel').count}"
puts "  - 精品小团: #{TourGroupProduct.where(tour_category: 'group_tour').count}"
puts "  - 多日游: #{TourGroupProduct.where(tour_category: 'private_group').count}"
puts "套餐总数: #{packages_created}"
puts "行程天数: #{itinerary_days_created}"
puts "\n各目的地产品分布:"
destinations_config.each do |dest|
  count = TourGroupProduct.where('destination LIKE ?', "%#{dest[:name]}%").count
  puts "  #{dest[:name]}: #{count}"
end
puts "\n各天数产品分布:"
(1..8).each do |d|
  count = TourGroupProduct.where(duration: d).count
  puts "  #{d}天: #{count}" if count > 0
end
puts "\n精选产品: #{TourGroupProduct.where(is_featured: true).count}"
