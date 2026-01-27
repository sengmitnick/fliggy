# 统一的旅游产品数据包 - 合并所有目的地和类型
# 使用 insert_all 批量插入提升性能

puts "🧹 清理旧数据..."
TourItineraryDay.destroy_all
TourPackage.destroy_all
TourGroupProduct.destroy_all
TravelAgency.destroy_all

timestamp = Time.current

# ==================== 批量创建旅行社 ====================
puts "\n🏢 批量创建旅行社..."

agencies_data = [
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
  { name: '厦门建发国际旅行社', rating: 4.8, sales_count: 6800, is_verified: true },
  { name: '青海卓不凡旅行社专营店', rating: 4.8, sales_count: 2800, is_verified: true },
  { name: '青海巨邦国际旅行社专营店', rating: 4.7, sales_count: 3200, is_verified: true },
  { name: '容生行旅游旗舰店', rating: 4.9, sales_count: 4500, is_verified: true },
  { name: '云南假日国际旅行社', rating: 4.8, sales_count: 5800, is_verified: true },
  { name: '四川省中国旅行社', rating: 4.9, sales_count: 7200, is_verified: true },
  { name: '西藏中国国际旅行社', rating: 4.7, sales_count: 2500, is_verified: true },
  { name: '新疆天山旅行社', rating: 4.8, sales_count: 3100, is_verified: true },
  { name: '海南椰风假期', rating: 4.9, sales_count: 6500, is_verified: true },
  { name: '桂林山水假期', rating: 4.8, sales_count: 4800, is_verified: true },
  { name: '杭州西湖国旅', rating: 4.9, sales_count: 5200, is_verified: true }
].map { |attrs| attrs.merge(created_at: timestamp, updated_at: timestamp) }

TravelAgency.insert_all(agencies_data)
agencies_map = TravelAgency.pluck(:name, :id).to_h

puts "✓ 批量创建了 #{TravelAgency.count} 家旅行社"

# ==================== 目的地配置（全国主要旅游城市） ====================
destinations_config = [
  # 原有目的地（保持不变）
  { name: '青海', cities: ['西宁', '海北', '海南州', '海西'], attractions: ['青海湖', '茶卡盐湖', '日月山', '塔尔寺'], departure_cities: ['西宁', '兰州', '西安'] },
  { name: '云南', cities: ['昆明', '大理', '丽江', '香格里拉'], attractions: ['洱海', '苍山', '玉龙雪山', '泸沽湖'], departure_cities: ['昆明', '大理', '丽江'] },
  { name: '四川', cities: ['成都', '九寨沟', '峨眉山', '乐山'], attractions: ['九寨沟', '黄龙', '峨眉山', '乐山大佛'], departure_cities: ['成都', '重庆'] },
  { name: '西藏', cities: ['拉萨', '林芝', '日喀则'], attractions: ['布达拉宫', '大昭寺', '纳木错', '羊卓雍错'], departure_cities: ['拉萨', '林芝'] },
  { name: '新疆', cities: ['乌鲁木齐', '喀什', '伊犁'], attractions: ['天山天池', '喀纳斯', '赛里木湖', '那拉提草原'], departure_cities: ['乌鲁木齐', '伊宁'] },
  { name: '海南', cities: ['三亚', '海口'], attractions: ['蜈支洲岛', '亚龙湾', '天涯海角', '南山寺'], departure_cities: ['三亚', '海口'] },
  { name: '广西', cities: ['桂林', '阳朔', '北海'], attractions: ['漓江', '象鼻山', '西街', '银子岩'], departure_cities: ['桂林', '南宁'] },
  { name: '浙江', cities: ['杭州', '千岛湖', '舟山'], attractions: ['西湖', '千岛湖', '普陀山', '乌镇'], departure_cities: ['杭州', '上海', '宁波'] },
  { name: '上海', departure_cities: ['上海', '杭州', '南京', '苏州'] },
  { name: '北京', departure_cities: ['北京', '天津', '石家庄', '太原'] },
  { name: '杭州', departure_cities: ['杭州', '上海', '宁波', '温州'] },
  { name: '广州', departure_cities: ['广州', '深圳', '珠海', '佛山'] },
  { name: '成都', departure_cities: ['成都', '重庆', '绵阳', '乐山'] },
  { name: '深圳', departure_cities: ['深圳', '广州', '珠海', '香港'] },
  { name: '西安', departure_cities: ['西安', '咸阳', '宝鸡', '渭南'] },
  { name: '三亚', departure_cities: ['三亚', '海口', '广州', '深圳'] },
  { name: '南京', departure_cities: ['南京', '上海', '杭州', '苏州'] },
  { name: '苏州', departure_cities: ['苏州', '上海', '杭州', '南京'] },
  { name: '厦门', departure_cities: ['厦门', '福州', '泉州', '广州'] },
  { name: '重庆', departure_cities: ['重庆', '成都', '贵阳', '西安'] },
  { name: '昆明', departure_cities: ['昆明', '成都', '重庆', '贵阳'] },
  { name: '青岛', departure_cities: ['青岛', '济南', '烟台', '威海'] },
  { name: '长沙', departure_cities: ['长沙', '武汉', '广州', '南昌'] },
  { name: '武汉', departure_cities: ['武汉', '长沙', '郑州', '南昌'] },
  { name: '南昌', departure_cities: ['南昌', '长沙', '武汉', '福州'] },
  { name: '贵阳', departure_cities: ['贵阳', '昆明', '成都', '重庆'] },
  { name: '兰州', departure_cities: ['兰州', '西安', '西宁', '银川'] },
  { name: '西宁', departure_cities: ['西宁', '兰州', '西安', '银川'] },
  
  # 新增热门目的地
  { name: '张家界', cities: ['张家界', '武陵源', '天门山'], attractions: ['张家界国家森林公园', '天门山', '黄龙洞', '凤凰古城'], departure_cities: ['长沙', '张家界', '武汉', '广州'] },
  { name: '黄山', cities: ['黄山', '宏村', '西递'], attractions: ['黄山风景区', '宏村', '西递', '徽州古城'], departure_cities: ['黄山', '合肥', '杭州', '上海'] },
  { name: '九寨沟', cities: ['九寨沟', '黄龙'], attractions: ['九寨沟', '黄龙', '松潘古城', '牟尼沟'], departure_cities: ['成都', '重庆', '绵阳'] },
  { name: '桂林', cities: ['桂林', '阳朔', '龙胜'], attractions: ['漓江', '象鼻山', '两江四湖', '龙脊梯田'], departure_cities: ['桂林', '南宁', '广州', '深圳'] },
  { name: '泸沽湖', cities: ['泸沽湖', '里格', '草海'], attractions: ['泸沽湖', '里格岛', '走婚桥', '格姆女神山'], departure_cities: ['丽江', '昆明', '西昌'] },
  { name: '稻城亚丁', cities: ['稻城', '亚丁', '香格里拉镇'], attractions: ['亚丁景区', '牛奶海', '五色海', '珍珠海'], departure_cities: ['成都', '康定', '丽江'] },
  { name: '呼伦贝尔', cities: ['海拉尔', '满洲里', '额尔古纳'], attractions: ['呼伦贝尔大草原', '满洲里国门', '白桦林', '莫日格勒河'], departure_cities: ['海拉尔', '哈尔滨', '北京'] },
  { name: '敦煌', cities: ['敦煌', '嘉峪关'], attractions: ['莫高窟', '鸣沙山', '月牙泉', '雅丹魔鬼城'], departure_cities: ['兰州', '敦煌', '西安', '乌鲁木齐'] },
  { name: '喀纳斯', cities: ['喀纳斯', '禾木', '白哈巴'], attractions: ['喀纳斯湖', '禾木村', '神仙湾', '观鱼台'], departure_cities: ['乌鲁木齐', '阿勒泰'] }
]

# ==================== 旅游类型配置 ====================
tour_types = [
  { category: 'free_travel', label: '一日游', travel_type: '自由出行', durations: [1], weight: 30, features: ['上门接送', '含午餐', '含门票', '纯玩无购物', '当天往返'] },
  { category: 'group_tour', label: '精品小团', travel_type: '跟团游', durations: [2, 3, 4, 5], weight: 40, group_sizes: [4, 6, 8, 10], features: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物'] },
  { category: 'private_group', label: '多日游', travel_type: '独立成团', durations: [4, 5, 6, 7, 8], weight: 30, features: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '深度游览'] }
]

# ==================== 批量生成旅游产品 ====================
puts "\n🎫 批量生成旅游产品..."

all_products_data = []
start_date = Date.today
end_date = start_date + 6.days  # 生成7天的数据

destinations_config.each do |dest_config|
  destination = dest_config[:name]
  departure_cities = dest_config[:departure_cities]
  attractions = dest_config[:attractions] || [destination]
  
  # 每个目的地选择2-3个主要出发城市
  selected_departures = departure_cities.sample([departure_cities.count, 3].min)
  
  selected_departures.each do |departure_city|
    tour_types.each do |tour_type|
      # 根据类型决定生成数量
      products_count = case tour_type[:category]
      when 'free_travel' then 3  # 一日游:每个出发地3个
      when 'group_tour' then 4   # 精品小团:每个出发地4个
      when 'private_group' then 3 # 多日游:每个出发地3个
      end
      
      products_count.times do
        duration = tour_type[:durations].sample
        nights = duration - 1
        departure_date = start_date + rand(0..4).days
        
        # 选择景点
        selected_attractions = attractions.sample([attractions.count, rand(2..4)].min)
        
        # 生成价格
        base_price = case duration
        when 1 then rand(68..399)
        when 2 then rand(688..1288)
        when 3 then rand(1288..2088)
        when 4 then rand(1888..3088)
        when 5 then rand(2488..4088)
        when 6 then rand(3288..5088)
        when 7 then rand(3888..6088)
        else rand(4288..7088)
        end
        
        # 精品小团价格上浮
        base_price = (base_price * rand(1.1..1.2)).to_i if tour_type[:category] == 'group_tour'
        original_price = (base_price * rand(1.15..1.35)).to_i
        
        # 生成标题
        title_suffix = if duration == 1
          "一日游 当天往返"
        else
          group_size = tour_type[:group_sizes]&.sample
          group_text = group_size ? "#{group_size}人团 " : ""
          "#{duration}天#{nights}晚 #{group_text}#{tour_type[:features].sample(2).join('·')}"
        end
        
        title = "【#{tour_type[:label]}】#{destination}#{selected_attractions.join('+')} #{title_suffix}"
        title = title[0..80] if title.length > 80
        
        # 生成副标题
        subtitle = [selected_attractions.first, tour_type[:features].sample(2).join('·')].compact.join('·')
        
        # Badge
        badge = if tour_type[:category] == 'free_travel'
          '一日游'
        elsif tour_type[:category] == 'group_tour'
          "多日游·#{tour_type[:group_sizes].sample}人团"
        else
          '多日游·独立成团'
        end
        
        # 选择旅行社
        agency_name = agencies_data.sample[:name]
        agency_id = agencies_map[agency_name]
        
        all_products_data << {
          title: title,
          subtitle: subtitle,
          destination: destination,
          departure_city: departure_city,
          tour_category: tour_type[:category],
          travel_type: tour_type[:travel_type],
          duration: duration,
          badge: badge,
          price: base_price,
          original_price: original_price,
          rating: [4.7, 4.8, 4.9, 5.0].sample,
          rating_desc: "#{rand(50..500)}条评价",
          sales_count: rand(10..1000),
          highlights: tour_type[:features].sample(rand(2..3)),
          tags: tour_type[:features].sample(rand(3..5)),
          departure_label: "#{departure_city}出发",
          is_featured: rand < 0.15,  # 15%概率精选
          display_order: all_products_data.count,
          image_url: "https://images.unsplash.com/photo-#{rand(1500000000000..1700000000000)}-#{SecureRandom.hex(8)}?w=400&h=600",
          travel_agency_id: agency_id,
          created_at: timestamp,
          updated_at: timestamp
        }
      end
    end
  end
end

puts "\n💾 批量插入 #{all_products_data.count} 个旅游产品..."
TourGroupProduct.insert_all(all_products_data)

# ==================== 批量生成套餐数据 ====================
puts "\n🎟️ 批量生成套餐数据..."

all_packages_data = []
timestamp = Time.current

TourGroupProduct.find_each do |product|
  # 每个产品生成2-3个套餐
  packages_count = rand(2..3)
  
  packages_count.times do |i|
    base_price = product.price
    
    # 套餐价格逐渐递增
    package_price = case i
    when 0 then base_price  # 基础套餐
    when 1 then (base_price * rand(1.2..1.4)).to_i  # 标准套餐
    when 2 then (base_price * rand(1.5..1.8)).to_i  # 豪华套餐
    end
    
    child_price = (package_price * rand(0.6..0.8)).to_i
    
    package_names = case i
    when 0 then ['基础套餐', '经济套餐', '标准套餐', '舒适套餐']
    when 1 then ['豪华套餐', '高级套餐', '优选套餐', '精选套餐']
    when 2 then ['至尊套餐', '尊享套餐', 'VIP套餐', '奢华套餐']
    end
    
    # 根据套餐等级生成详细描述
    description = case i
    when 0
      "✓ 三星级酒店住宿 (经济实惠)\n✓ 包含早餐\n✓ 景点首道门票\n✓ 旅游大巴接送\n✓ 专业导游服务"
    when 1
      "✓ 四星级酒店住宿 (品质保障)\n✓ 包含早餐+午餐\n✓ 景点门票+特色体验项目\n✓ 豪华旅游大巴\n✓ 金牌导游服务\n✓ 赠送旅游意外险"
    when 2
      "✓ 五星级酒店住宿 (奢华尊享)\n✓ 包含三餐(含特色餐)\n✓ 景点VIP通道+深度体验\n✓ 商务车接送\n✓ 资深导游一对一服务\n✓ 赠送旅游意外险+旅拍服务\n✓ 24小时管家服务"
    end
    
    all_packages_data << {
      tour_group_product_id: product.id,
      name: package_names.sample,
      price: package_price,
      child_price: child_price,
      description: description,
      is_featured: i == 0,  # 第一个套餐为推荐套餐
      display_order: i,
      purchase_count: rand(10..500),
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

puts "  批量插入 #{all_packages_data.count} 个套餐..."
TourPackage.insert_all(all_packages_data)

# ==================== 批量生成行程数据 ====================
puts "\n📅 批量生成行程数据..."

all_itinerary_data = []
timestamp = Time.current

# 景点模板库
attractions_library = {
  '自然风光' => ['观赏日出', '山水徒步', '森林氧吧', '天然湖泊', '草原风光', '雪山远眺'],
  '人文历史' => ['古城游览', '博物馆参观', '寺庙朝拜', '民俗体验', '古镇漫步', '历史遗迹'],
  '休闲娱乐' => ['温泉体验', '特色表演', '美食街', '手工艺制作', '茶艺体验', '夜市逛街'],
  '特色体验' => ['当地美食', '摄影打卡', '互动体验', '文化讲解', '特色活动', '自由活动']
}

TourGroupProduct.find_each do |product|
  duration = product.duration
  destination = product.destination
  departure_city = product.departure_city
  
  duration.times do |i|
    day_number = i + 1
    
    if day_number == 1
      # 第一天：抵达日
      all_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: day_number,
        title: "出发日 - 抵达#{destination}",
        attractions: ["从#{departure_city}出发", "#{destination}机场/车站接站", '酒店办理入住', '欢迎晚餐(自费)'],
        assembly_point: "#{departure_city}机场/车站集合",
        disassembly_point: nil,
        transportation: '飞机/高铁',
        service_info: '专车接站,专人引导入住酒店,提供旅游咨询服务',
        duration_minutes: 480,
        created_at: timestamp,
        updated_at: timestamp
      }
    elsif day_number == duration
      # 最后一天：返程日
      morning_activity = duration > 2 ? '早餐后酒店周边自由活动' : '早餐后退房'
      all_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: day_number,
        title: "返程日 - 返回#{departure_city}",
        attractions: [morning_activity, '专车送站服务', "返回#{departure_city}", '结束愉快旅程'],
        assembly_point: nil,
        disassembly_point: "#{destination}机场/车站",
        transportation: '飞机/高铁',
        service_info: '专车送站,协助办理登机/乘车手续,期待下次再见',
        duration_minutes: 360,
        created_at: timestamp,
        updated_at: timestamp
      }
    else
      # 中间天：精华游览日
      category = ['自然风光', '人文历史', '休闲娱乐', '特色体验'].sample
      day_attractions = attractions_library[category].sample(3) + [
        "#{destination}特色景点#{day_number - 1}",
        '当地特色午餐',
        '下午茶时光(自费)'
      ]
      
      all_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: day_number,
        title: "第#{day_number}天 - #{destination}#{category}深度游",
        attractions: day_attractions,
        assembly_point: nil,
        disassembly_point: nil,
        transportation: '旅游大巴',
        service_info: '全天游览,包含景点门票、专业导游讲解服务、午餐',
        duration_minutes: 540,
        created_at: timestamp,
        updated_at: timestamp
      }
    end
  end
end

puts "  批量插入 #{all_itinerary_data.count} 条行程..."
TourItineraryDay.insert_all(all_itinerary_data) if all_itinerary_data.any?

# ==================== 附加画廊图片 ====================
# 注意：为了加快初始化速度，跳过网络下载图片
# 如需添加真实图片，可在后台管理界面手动上传
puts "\n🖼️  跳过画廊图片附加（避免网络下载延迟）..."
puts "  提示：可在后台管理界面为产品手动上传画廊图片"

puts "\n📊 生成统计:"
puts "  总产品数: #{TourGroupProduct.count}"
puts "  - 跟团游: #{TourGroupProduct.by_category('group_tour').count}"
puts "  - 私家团: #{TourGroupProduct.by_category('private_group').count}"
puts "  - 自由行: #{TourGroupProduct.by_category('free_travel').count}"
puts "  - 推荐产品: #{TourGroupProduct.where(is_featured: true).count}"
puts "  总套餐数: #{TourPackage.count}"
puts "  - 平均每产品: #{(TourPackage.count.to_f / TourGroupProduct.count).round(1)}个套餐"
puts "  总行程数: #{TourItineraryDay.count}"
puts "  - 平均每产品: #{(TourItineraryDay.count.to_f / TourGroupProduct.count).round(1)}天行程"

puts "\n✅ 旅游产品数据包加载完成！"
