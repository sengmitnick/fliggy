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
  { name: '喀纳斯', cities: ['喀纳斯', '禾木', '白哈巴'], attractions: ['喀纳斯湖', '禾木村', '神仙湾', '观鱼台'], departure_cities: ['乌鲁木齐', '阿勒泰'] },
  { name: '婺源', cities: ['婺源', '江湾', '篁岭'], attractions: ['江湾', '篁岭', '李坑', '汪口'], departure_cities: ['上饶', '景德镇', '黄山', '南昌'] },
  { name: '凤凰古城', cities: ['凤凰', '吉首'], attractions: ['凤凰古城', '沱江', '南方长城', '奇梁洞'], departure_cities: ['长沙', '张家界', '吉首', '怀化'] },
  { name: '平遥古城', cities: ['平遥', '太原'], attractions: ['平遥古城', '日升昌票号', '城隍庙', '县衙'], departure_cities: ['太原', '西安', '北京', '郑州'] },
  { name: '西双版纳', cities: ['景洪', '勐腊', '勐海'], attractions: ['野象谷', '原始森林公园', '傣族园', '植物园'], departure_cities: ['昆明', '西双版纳', '成都'] },
  { name: '香格里拉', cities: ['香格里拉', '德钦'], attractions: ['普达措', '独克宗古城', '松赞林寺', '纳帕海'], departure_cities: ['丽江', '昆明', '大理'] },
  { name: '腾冲', cities: ['腾冲', '和顺'], attractions: ['火山地热公园', '和顺古镇', '银杏村', '北海湿地'], departure_cities: ['昆明', '保山', '大理'] },
  { name: '阿尔山', cities: ['阿尔山', '五岔沟'], attractions: ['阿尔山天池', '石塘林', '杜鹃湖', '三潭峡'], departure_cities: ['呼和浩特', '乌兰浩特', '海拉尔'] },
  { name: '长白山', cities: ['二道白河', '长白山'], attractions: ['天池', '长白山瀑布', '温泉', '地下森林'], departure_cities: ['长春', '延吉', '沈阳'] },
  { name: '峨眉山', cities: ['峨眉山', '乐山'], attractions: ['峨眉山', '金顶', '乐山大佛', '报国寺'], departure_cities: ['成都', '重庆', '乐山'] },
  { name: '青城山', cities: ['都江堰', '青城山'], attractions: ['青城山', '都江堰', '街子古镇'], departure_cities: ['成都', '重庆'] },
  { name: '大理', cities: ['大理', '洱海', '双廊'], attractions: ['洱海', '苍山', '大理古城', '崇圣寺三塔'], departure_cities: ['昆明', '丽江', '大理'] },
  { name: '丽江', cities: ['丽江', '束河', '白沙'], attractions: ['丽江古城', '玉龙雪山', '束河古镇', '拉市海'], departure_cities: ['昆明', '丽江', '大理', '香格里拉'] },
  { name: '武夷山', cities: ['武夷山', '九曲溪'], attractions: ['九曲溪', '天游峰', '大红袍景区', '一线天'], departure_cities: ['福州', '厦门', '南平', '武夷山'] },
  { name: '鼓浪屿', cities: ['厦门', '鼓浪屿'], attractions: ['日光岩', '菽庄花园', '皓月园', '厦门大学'], departure_cities: ['厦门', '福州', '泉州'] },
  { name: '华山', cities: ['华山', '西安'], attractions: ['华山', '长空栈道', '苍龙岭', '金锁关'], departure_cities: ['西安', '渭南', '郑州'] },
  { name: '泰山', cities: ['泰安', '泰山'], attractions: ['泰山', '岱庙', '天外村', '红门'], departure_cities: ['济南', '泰安', '北京', '青岛'] },
  { name: '蓬莱', cities: ['蓬莱', '长岛'], attractions: ['蓬莱阁', '长岛', '八仙渡', '海洋极地世界'], departure_cities: ['烟台', '青岛', '济南', '威海'] },
  { name: '千岛湖', cities: ['千岛湖', '淳安'], attractions: ['千岛湖', '森林氧吧', '梅峰岛', '龙川湾'], departure_cities: ['杭州', '上海', '南京', '千岛湖'] },
  { name: '乌镇', cities: ['乌镇', '西塘'], attractions: ['乌镇东栅', '乌镇西栅', '西塘古镇'], departure_cities: ['杭州', '上海', '嘉兴', '苏州'] },
  { name: '普陀山', cities: ['普陀山', '舟山'], attractions: ['普陀山', '南海观音', '紫竹林', '不肯去观音院'], departure_cities: ['杭州', '上海', '宁波', '舟山'] },
  { name: '三清山', cities: ['上饶', '三清山'], attractions: ['三清山', '巨蟒出山', '东方女神', '玉京峰'], departure_cities: ['上饶', '南昌', '景德镇', '杭州'] },
  { name: '龙门石窟', cities: ['洛阳', '龙门'], attractions: ['龙门石窟', '白马寺', '关林', '老君山'], departure_cities: ['郑州', '洛阳', '西安'] },
  { name: '嵩山少林', cities: ['郑州', '登封'], attractions: ['少林寺', '嵩山', '中岳庙', '塔林'], departure_cities: ['郑州', '洛阳', '开封'] },
  { name: '承德', cities: ['承德', '围场'], attractions: ['避暑山庄', '外八庙', '木兰围场', '塞罕坝'], departure_cities: ['北京', '承德', '天津'] },
  { name: '秦皇岛', cities: ['秦皇岛', '北戴河', '南戴河'], attractions: ['山海关', '老龙头', '北戴河', '鸽子窝公园'], departure_cities: ['北京', '秦皇岛', '天津', '石家庄'] },
  { name: '威海', cities: ['威海', '荣成'], attractions: ['刘公岛', '成山头', '威海国际海水浴场', '天鹅湖'], departure_cities: ['烟台', '威海', '济南', '青岛'] },
  { name: '日照', cities: ['日照', '东港'], attractions: ['万平口', '灯塔风景区', '森林公园', '第三海水浴场'], departure_cities: ['日照', '青岛', '济南', '临沂'] }
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

destinations_config.each_with_index do |dest_config, dest_idx|
  destination = dest_config[:name]
  departure_cities = dest_config[:departure_cities]
  attractions = dest_config[:attractions] || [destination]
  
  puts "  [#{dest_idx + 1}/#{destinations_config.count}] 正在为 #{destination} 生成产品..."
  
  # 每个目的地选择2-3个主要出发城市
  selected_departures = departure_cities.sample([departure_cities.count, 3].min)
  
  selected_departures.each do |departure_city|
    tour_types.each do |tour_type|
      # 根据类型决定生成数量
      products_count = case tour_type[:category]
      when 'free_travel' then 3  # 一日游：每个出发地3个
      when 'group_tour' then 4   # 精品小团：每个出发地4个
      when 'private_group' then 3 # 多日游：每个出发地3个
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
    
    all_packages_data << {
      tour_group_product_id: product.id,
      name: package_names.sample,
      price: package_price,
      child_price: child_price,
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

puts "📊 生成统计："
puts "  总产品数: #{TourGroupProduct.count}"
puts "  - 跟团游: #{TourGroupProduct.by_category('group_tour').count}"
puts "  - 私家团: #{TourGroupProduct.by_category('private_group').count}"
puts "  - 自由行: #{TourGroupProduct.by_category('free_travel').count}"
puts "  - 推荐产品: #{TourGroupProduct.where(is_featured: true).count}"
puts "  总套餐数: #{TourPackage.count}"
puts "  - 平均每产品: #{(TourPackage.count.to_f / TourGroupProduct.count).round(1)}个套餐"

puts "\n✅ 旅游产品数据包加载完成！"
