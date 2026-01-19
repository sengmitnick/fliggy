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
  { name: '深圳康辉旅行社', rating: 4.8, sales_count: 7500, is_verified: true },
  { name: '成都青旅国际', rating: 4.8, sales_count: 5500, is_verified: true },
  { name: '西安世纪明德旅行社', rating: 4.7, sales_count: 4200, is_verified: true },
  { name: '苏州吴中旅行社', rating: 4.9, sales_count: 3800, is_verified: true },
  { name: '厦门建发国际旅行社', rating: 4.8, sales_count: 6800, is_verified: true }
]

travel_agencies = agencies.map { |attrs| TravelAgency.create!(attrs) }

puts "✓ 创建了 #{TravelAgency.count} 家旅行社"

puts "\n🎫 批量创建多地旅游产品（精品小团、多日游、一日游）..."

# 扩展的目的地配置 - 涵盖更多城市
destinations_config = [
  { name: '上海', departure_cities: ['上海', '杭州', '南京', '苏州', '无锡'] },
  { name: '北京', departure_cities: ['北京', '天津', '石家庄', '保定'] },
  { name: '杭州', departure_cities: ['杭州', '上海', '宁波', '温州', '嘉兴'] },
  { name: '广州', departure_cities: ['广州', '深圳', '珠海', '佛山', '东莞'] },
  { name: '成都', departure_cities: ['成都', '重庆', '绵阳', '乐山'] },
  { name: '深圳', departure_cities: ['深圳', '广州', '香港', '珠海'] },
  { name: '西安', departure_cities: ['西安', '咸阳', '宝鸡', '渭南'] },
  { name: '三亚', departure_cities: ['三亚', '海口', '广州', '深圳', '上海'] },
  { name: '苏州', departure_cities: ['苏州', '上海', '杭州', '南京', '无锡'] },
  { name: '南京', departure_cities: ['南京', '上海', '杭州', '苏州', '合肥'] },
  { name: '厦门', departure_cities: ['厦门', '福州', '泉州', '广州', '深圳'] },
  { name: '青岛', departure_cities: ['青岛', '济南', '烟台', '威海'] },
  { name: '武汉', departure_cities: ['武汉', '长沙', '南昌', '合肥'] },
  { name: '重庆', departure_cities: ['重庆', '成都', '贵阳', '西安'] },
  { name: '长沙', departure_cities: ['长沙', '武汉', '南昌', '广州'] }
]

# 主题配置 - 更丰富的主题选择
themes_library = [
  { 
    name: '古镇漫游', 
    highlights: ['古镇风情', '人文历史', '美食体验', '古建筑群'], 
    tags: ['历史文化', '美食', '摄影'],
    images: [
      'https://images.unsplash.com/photo-1548919973-5cef591cdbc9?w=800',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800',
      'https://images.unsplash.com/photo-1542051841857-5f90071e7989?w=800'
    ]
  },
  { 
    name: '山水之旅', 
    highlights: ['自然风光', '登山涉水', '生态体验', '清新空气'], 
    tags: ['自然风光', '户外探险', '亲近自然'],
    images: [
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
      'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
      'https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=800'
    ]
  },
  { 
    name: '都市休闲', 
    highlights: ['城市观光', '购物天堂', '美食打卡', '网红景点'], 
    tags: ['城市漫步', '美食', '购物'],
    images: [
      'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=800',
      'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=800',
      'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800'
    ]
  },
  { 
    name: '海岛度假', 
    highlights: ['海滨度假', '水上项目', '阳光沙滩', '海鲜美食'], 
    tags: ['海滨度假', '亲子游', '度假休闲'],
    images: [
      'https://images.unsplash.com/photo-1559827260-dc66d52bef19?w=800',
      'https://images.unsplash.com/photo-1473496169904-658ba7c44d8a?w=800',
      'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800'
    ]
  },
  { 
    name: '文化探索', 
    highlights: ['博物馆参观', '文化遗产', '艺术体验', '非遗传承'], 
    tags: ['文化艺术', '深度体验', '教育意义'],
    images: [
      'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      'https://images.unsplash.com/photo-1533929736458-ca588d08c8be?w=800',
      'https://images.unsplash.com/photo-1520760693108-c8bb8944290a?w=800'
    ]
  },
  { 
    name: '美食寻味', 
    highlights: ['地道美食', '老字号探访', '小吃街巡游', '特色餐厅'], 
    tags: ['美食', '文化体验', '地道玩法'],
    images: [
      'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
      'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
      'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800'
    ]
  },
  { 
    name: '亲子欢乐', 
    highlights: ['亲子活动', '主题乐园', '科普教育', '互动体验'], 
    tags: ['亲子游', '儿童友好', '寓教于乐'],
    images: [
      'https://images.unsplash.com/photo-1527176930608-09cb256ab504?w=800',
      'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=800',
      'https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=800'
    ]
  },
  { 
    name: '红色之旅', 
    highlights: ['革命圣地', '爱国教育', '历史见证', '精神传承'], 
    tags: ['红色旅游', '教育意义', '历史文化'],
    images: [
      'https://images.unsplash.com/photo-1548919973-5cef591cdbc9?w=800',
      'https://images.unsplash.com/photo-1555881400-74d7acaacd8b?w=800',
      'https://images.unsplash.com/photo-1508804185872-d7badad00f7d?w=800'
    ]
  }
]

# 旅游类型定义
tour_type_configs = [
  { 
    category: 'group_tour', 
    label: '精品小团',
    durations: [1, 2, 3, 4, 5],
    weight: 40,
    subtitle_options: [
      '小团慢游 品质保障',
      '精品小团 贴心服务',
      '6-12人精品团 舒适自在',
      '专业导游 全程陪同',
      '品质小团 深度体验'
    ]
  },
  { 
    category: 'private_group', 
    label: '多日游',
    durations: [3, 4, 5, 6, 7],
    weight: 35,
    subtitle_options: [
      '深度游览 行程丰富',
      '多日深度 精彩不停',
      '全景游览 一次玩透',
      '豪华行程 尊享体验',
      '含餐含住 省心省力'
    ]
  },
  { 
    category: 'free_travel', 
    label: '一日游',
    durations: [1],
    weight: 25,
    subtitle_options: [
      '当天往返 轻松出游',
      '一日精华 高效打卡',
      '含车含导 说走就走',
      '经典路线 超值体验',
      '省时省力 适合周末'
    ]
  }
]

all_products = []
start_date = Date.today
end_date = start_date + 6.days  # 生成7天的数据

destinations_config.each_with_index do |dest_config, idx|
  destination = dest_config[:name]
  departure_cities = dest_config[:departure_cities]
  
  puts "\n  [#{idx + 1}/#{destinations_config.count}] 正在为 #{destination} 生成产品..."
  
  # 为每个目的地，选择2-3个出发城市
  selected_departures = departure_cities.sample([departure_cities.count, 3].min)
  
  selected_departures.each do |departure_city|
    tour_type_configs.each do |type_config|
      category = type_config[:category]
      label = type_config[:label]
      
      # 根据类型决定生成数量
      products_count = case category
      when 'free_travel' then 3  # 一日游：每个出发地3个
      when 'group_tour' then 5   # 精品小团：每个出发地5个
      when 'private_group' then 4 # 多日游：每个出发地4个
      end
      
      products_count.times do |product_idx|
        # 选择主题
        theme = themes_library.sample
        
        # 选择天数（根据类型限制）
        duration = type_config[:durations].sample
        
        # 选择发团日期
        departure_date = start_date + rand(0..6).days
        
        # 生成价格（根据天数和类型）
        base_price = case duration
        when 1 then rand(198..588)
        when 2 then rand(688..1288)
        when 3 then rand(1288..2088)
        when 4 then rand(1888..3088)
        when 5 then rand(2488..4088)
        when 6 then rand(3288..5088)
        when 7 then rand(3888..6088)
        end
        
        # 精品小团价格上浮10-20%
        base_price = (base_price * rand(1.1..1.2)).to_i if category == 'group_tour'
        
        original_price = (base_price * rand(1.15..1.35)).to_i
        
        # 生成评分和销量
        rating = [4.5, 4.6, 4.7, 4.8, 4.9, 5.0].sample
        rating_desc = "#{rand(50..999)}条评价"
        sales_count = case category
        when 'free_travel' then rand(100..800)   # 一日游销量高
        when 'group_tour' then rand(50..400)     # 精品小团销量中等
        when 'private_group' then rand(30..200)  # 多日游销量较低
        end
        
        # 生成标题
        title_suffix = if duration == 1
          "一日游 当天往返"
        else
          "#{duration}天#{duration - 1}晚 含#{['2晚酒店', '餐食', '门票', '导游'].sample}"
        end
        
        title = "【#{label}】#{destination}#{theme[:name]} #{title_suffix}"
        
        # 创建产品
        product = TourGroupProduct.create!(
          title: title,
          subtitle: type_config[:subtitle_options].sample,
          tour_category: category,
          destination: destination,
          duration: duration,
          departure_city: departure_city,
          price: base_price,
          original_price: original_price,
          rating: rating,
          rating_desc: rating_desc,
          highlights: theme[:highlights],
          tags: theme[:tags],
          sales_count: sales_count,
          badge: label,
          departure_label: departure_date.strftime('%m月%d日'),
          image_url: theme[:images].sample,
          is_featured: rand < 0.15,  # 15%概率为推荐
          display_order: rand(1..100),
          travel_agency: travel_agencies.sample,
          reward_points: (base_price * 0.05).to_i,
          requires_merchant_confirm: category != 'free_travel',
          success_rate_high: rand < 0.7
        )
        
        # 生成套餐
        product.generate_packages
        
        # 生成行程
        product.generate_itinerary
        
        all_products << product
      end
      
      puts "    ✓ #{departure_city} -> #{destination} (#{label}): #{products_count}个产品"
    end
  end
end

puts "\n" + "="*60
puts "📊 生成统计："
puts "="*60
puts "  总产品数: #{TourGroupProduct.count}"
puts "\n按类型分类："
puts "  - 精品小团 (group_tour): #{TourGroupProduct.by_category('group_tour').count}"
puts "  - 多日游 (private_group): #{TourGroupProduct.by_category('private_group').count}"
puts "  - 一日游 (free_travel): #{TourGroupProduct.by_category('free_travel').count}"

puts "\n按天数分类："
[1, 2, 3, 4, 5, 6, 7].each do |days|
  count = TourGroupProduct.where(duration: days).count
  puts "  - #{days}天: #{count}个产品" if count > 0
end

puts "\n按目的地分类："
destinations_config.each do |dest|
  count = TourGroupProduct.where("destination LIKE ?", "%#{dest[:name]}%").count
  puts "  - #{dest[:name]}: #{count}个产品"
end

puts "\n其他统计："
puts "  - 推荐产品: #{TourGroupProduct.where(is_featured: true).count}"
puts "  - 旅行社数: #{TravelAgency.count}"
puts "  - 总套餐数: #{TourPackage.count}"
puts "  - 总行程天数: #{TourItineraryDay.count}"

puts "\n✅ 多地旅游产品数据包加载完成！"
puts "  涵盖 #{destinations_config.count} 个目的地，包含精品小团、多日游、一日游三种类型"
puts "="*60
