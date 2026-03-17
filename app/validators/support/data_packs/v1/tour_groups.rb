# 统一的旅游产品数据包 - 合并所有目的地和类型
# 使用 insert_all 批量插入提升性能


# 加载图片辅助工具
require_relative '../../../../../app/helpers/image_seed_helper'

puts "🎫 正在加载旅游产品数据包..."

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
  
  # 境外游目的地
  { name: '泰国', cities: ['曼谷', '普吉', '芭提雅', '清迈'], attractions: ['大皇宫', '玉佛寺', '四面佛', '水上市场', '芭提雅海滩', '皮皮岛'], departure_cities: ['上海', '北京', '广州', '深圳', '成都', '杭州'] },
  { name: '日本', cities: ['东京', '大阪', '京都', '北海道'], attractions: ['富士山', '浅草寺', '清水寺', '奈良公园', '心斋桥'], departure_cities: ['上海', '北京', '广州', '深圳', '成都'] },
  { name: '韩国', cities: ['首尔', '济州岛', '釜山'], attractions: ['明洞', '景福宫', '南山塔', '济州岛', '海云台'], departure_cities: ['北京', '上海', '广州', '青岛', '大连'] },
  { name: '新加坡', cities: ['新加坡'], attractions: ['鱼尾狮', '圣淘沙', '滨海湾花园', '乌节路', '牛车水'], departure_cities: ['上海', '北京', '广州', '深圳', '成都'] },
  { name: '马来西亚', cities: ['吉隆坡', '槟城', '马六甲'], attractions: ['双子塔', '云顶高原', '槟城乔治市', '马六甲古城'], departure_cities: ['广州', '深圳', '上海', '北京', '成都'] },
  { name: '越南', cities: ['河内', '芽庄', '岘港', '胡志明市'], attractions: ['下龙湾', '芽庄海滩', '会安古城', '美溪海滩'], departure_cities: ['广州', '深圳', '南宁', '昆明'] }
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
          image_url: ImageSeedHelper.random_image_from_category(:tours),
          travel_agency_id: agency_id,
          data_version: 0,
          created_at: timestamp,
          updated_at: timestamp
        }
      end
    end
  end
end

puts "\n💾 批量插入 #{all_products_data.count} 个旅游产品..."
TourGroupProduct.insert_all(all_products_data)

# 杭州4天4晚独立成团产品（支持 v101/v113 验证器）
puts "\n🎯 添加特定杭州4天私家团产品..."

hangzhou_private_group_products = [
  {
    title: "【多日游】杭州西湖+千岛湖+乌镇 4天3晚 舒适酒店·全程用餐·包含门票·独立成团",
    subtitle: "西湖·舒适酒店·独立成团",
    destination: "杭州",
    departure_city: "杭州",
    tour_category: 'private_group',
    travel_type: '独立成团',
    duration: 4,
    badge: '多日游·独立成团',
    price: 2288,
    original_price: 2888,
    rating: 4.9,
    rating_desc: "180条评价",
    sales_count: 156,
    highlights: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '深度游览'],
    tags: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '深度游览'],
    departure_label: "杭州出发",
    is_featured: true,
    display_order: all_products_data.count,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['杭州携程国际旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【多日游】杭州西湖风景区+千岛湖深度游 4天3晚 专属导游·独立成团",
    subtitle: "千岛湖·专属导游·独立成团",
    destination: "杭州",
    departure_city: "上海",
    tour_category: 'private_group',
    travel_type: '独立成团',
    duration: 4,
    badge: '多日游·独立成团',
    price: 2588,
    original_price: 3088,
    rating: 4.8,
    rating_desc: "205条评价",
    sales_count: 198,
    highlights: ['舒适酒店', '全程用餐', '包含门票', '独立成团'],
    tags: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '专属导游'],
    departure_label: "上海出发",
    is_featured: false,
    display_order: all_products_data.count + 1,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['上海春秋旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【多日游】杭州西湖+乌镇+西塘湿地 4天3晚 纯玩无购物·独立成团",
    subtitle: "西湖·纯玩无购物·独立成团",
    destination: "杭州",
    departure_city: "宁波",
    tour_category: 'private_group',
    travel_type: '独立成团',
    duration: 4,
    badge: '多日游·独立成团',
    price: 2188,
    original_price: 2688,
    rating: 4.7,
    rating_desc: "125条评价",
    sales_count: 89,
    highlights: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '纯玩无购物'],
    tags: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '深度游览'],
    departure_label: "宁波出发",
    is_featured: false,
    display_order: all_products_data.count + 2,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['杭州西湖国旅'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

TourGroupProduct.insert_all(hangzhou_private_group_products)
puts "✓ 添加了 #{hangzhou_private_group_products.count} 个杭州4天私家团产品"

# 杭州禅修静心主题产品（支持 v306 验证器）
puts "\n🎯 添加杭州禅修静心主题产品..."

hangzhou_meditation_products = [
  {
    title: "【多日游】杭州灵隐寺+法喜寺+径山禅修静心游 3天2晚 素食体验·冥想课程·文化讲座",
    subtitle: "灵隐寺·禅修静心·素食体验",
    destination: "杭州",
    departure_city: "杭州",
    tour_category: 'private_group',
    travel_type: '独立成团',
    duration: 3,
    badge: '多日游·禅修主题',
    price: 1888,
    original_price: 2388,
    rating: 4.9,
    rating_desc: "156条评价",
    sales_count: 128,
    highlights: ['灵隐寺禅修', '素食体验', '冥想课程', '文化讲座', '深度体验'],
    tags: ['灵隐寺', '法喜寺', '径山寺', '素食', '禅修', '冥想', '文化主题'],
    departure_label: "杭州出发",
    is_featured: true,
    display_order: all_products_data.count,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['杭州西湖国旅'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【多日游】杭州灵隐寺+法喜寺禅修静心游 4天3晚 素食禅茶·抄经体验·寺庙住宿",
    subtitle: "禅修静心·寺庙住宿·素食禅茶",
    destination: "杭州",
    departure_city: "上海",
    tour_category: 'private_group',
    travel_type: '独立成团',
    duration: 4,
    badge: '多日游·禅修主题',
    price: 2488,
    original_price: 2988,
    rating: 4.8,
    rating_desc: "189条评价",
    sales_count: 167,
    highlights: ['寺庙住宿', '素食禅茶', '抄经体验', '禅修冥想', '文化深度游'],
    tags: ['灵隐寺', '法喜寺', '素食', '禅修', '冥想', '抄经', '寺庙住宿', '文化主题'],
    departure_label: "上海出发",
    is_featured: true,
    display_order: all_products_data.count + 1,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['上海春秋旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【多日游】杭州灵隐寺+径山寺+法喜寺禅修静心深度游 5天4晚 禅修课程·素食养生·茶道体验",
    subtitle: "禅修深度游·素食养生·茶道体验",
    destination: "杭州",
    departure_city: "杭州",
    tour_category: 'private_group',
    travel_type: '独立成团',
    duration: 5,
    badge: '多日游·禅修主题',
    price: 3288,
    original_price: 3888,
    rating: 5.0,
    rating_desc: "203条评价",
    sales_count: 198,
    highlights: ['禅修课程', '素食养生', '茶道体验', '冥想静坐', '寺庙巡礼', '文化讲座'],
    tags: ['灵隐寺', '径山寺', '法喜寺', '素食', '禅修', '冥想', '茶道', '养生', '文化主题'],
    departure_label: "杭州出发",
    is_featured: true,
    display_order: all_products_data.count + 2,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['杭州携程国际旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【精品小团】杭州灵隐寺+法喜寺禅修静心游 3天2晚 6人团 素食体验·冥想课程·禅茶一味",
    subtitle: "禅修静心·6人小团·素食冥想",
    destination: "杭州",
    departure_city: "宁波",
    tour_category: 'group_tour',
    travel_type: '跟团游',
    duration: 3,
    badge: '多日游·6人团',
    price: 1688,
    original_price: 2088,
    rating: 4.8,
    rating_desc: "142条评价",
    sales_count: 135,
    highlights: ['灵隐寺禅修', '素食体验', '冥想课程', '禅茶体验', '6人小团'],
    tags: ['灵隐寺', '法喜寺', '素食', '禅修', '冥想', '禅茶', '文化主题', '小团出行'],
    departure_label: "宁波出发",
    is_featured: false,
    display_order: all_products_data.count + 3,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['杭州西湖国旅'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【精品小团】杭州径山寺禅修静心游 4天3晚 8人团 禅修冥想·素食养生·文化体验",
    subtitle: "径山寺禅修·8人团·养生体验",
    destination: "杭州",
    departure_city: "上海",
    tour_category: 'group_tour',
    travel_type: '跟团游',
    duration: 4,
    badge: '多日游·8人团',
    price: 2188,
    original_price: 2688,
    rating: 4.7,
    rating_desc: "178条评价",
    sales_count: 156,
    highlights: ['径山寺禅修', '冥想课程', '素食养生', '文化体验', '8人小团'],
    tags: ['径山寺', '灵隐寺', '素食', '禅修', '冥想', '养生', '文化主题', '小团出行'],
    departure_label: "上海出发",
    is_featured: false,
    display_order: all_products_data.count + 4,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['上海春秋旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

TourGroupProduct.insert_all(hangzhou_meditation_products)
puts "✓ 添加了 #{hangzhou_meditation_products.count} 个杭州禅修静心主题产品"

# 成都3日跟团游产品（支持 v156 验证器）
puts "\n🎯 添加特定成都3日跟团游产品..."

chengdu_3day_tour_products = [
  {
    title: "【精品小团】成都大熊猫基地+都江堰+青城山 3天2晚 6人团 含酒店·含餐食·含门票·纯玩团",
    subtitle: "大熊猫基地·含酒店·纯玩团",
    destination: "成都",
    departure_city: "成都",
    tour_category: 'group_tour',
    travel_type: '跟团游',
    duration: 3,
    badge: '多日游·6人团',
    price: 1488,
    original_price: 1888,
    rating: 4.9,
    rating_desc: "280条评价",
    sales_count: 356,
    highlights: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物'],
    tags: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物'],
    departure_label: "成都出发",
    is_featured: true,
    display_order: all_products_data.count,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['成都青旅国际'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【精品小团】成都九寨沟+黄龙 3天2晚 8人团 含酒店·含餐食·含门票",
    subtitle: "九寨沟·含酒店·8人团",
    destination: "成都",
    departure_city: "成都",
    tour_category: 'group_tour',
    travel_type: '跟团游',
    duration: 3,
    badge: '多日游·8人团',
    price: 1688,
    original_price: 2088,
    rating: 4.8,
    rating_desc: "195条评价",
    sales_count: 228,
    highlights: ['含酒店', '含餐食', '含门票', '纯玩团'],
    tags: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物'],
    departure_label: "成都出发",
    is_featured: false,
    display_order: all_products_data.count + 1,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['四川省中国旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【精品小团】成都峨眉山+乐山大佛 3天2晚 10人团 含酒店·含餐食·纯玩无购物",
    subtitle: "峨眉山·乐山大佛·10人团",
    destination: "成都",
    departure_city: "重庆",
    tour_category: 'group_tour',
    travel_type: '跟团游',
    duration: 3,
    badge: '多日游·10人团',
    price: 1388,
    original_price: 1688,
    rating: 4.7,
    rating_desc: "145条评价",
    sales_count: 167,
    highlights: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物'],
    tags: ['含酒店', '含餐食', '含门票', '纯玩团', '深度游览'],
    departure_label: "重庆出发",
    is_featured: false,
    display_order: all_products_data.count + 2,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['成都青旅国际'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

TourGroupProduct.insert_all(chengdu_3day_tour_products)
puts "✓ 添加了 #{chengdu_3day_tour_products.count} 个成都3日跟团游产品"

# 广州2日跟团游产品（支持 v153 验证器）
puts "\n🎯 添加广州2日跟团游产品..."

guangzhou_2day_tour_products = [
  {
    title: "【精品小团】广州市内深度游 2天1晚 6人团 含酒店·含餐食·含门票·纯玩团",
    subtitle: "广州塔·长隆·纯玩团",
    destination: "广州",
    departure_city: "广州",
    tour_category: 'group_tour',
    travel_type: '跟团游',
    duration: 2,
    badge: '多日游·6人团',
    price: 688,
    original_price: 888,
    rating: 4.8,
    rating_desc: "156条评价",
    sales_count: 189,
    highlights: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物'],
    tags: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物', '广州塔', '长隆'],
    departure_label: "广州出发",
    is_featured: true,
    display_order: all_products_data.count,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['广州青旅国际旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【精品小团】广州珠江新城+广州塔+长隆 2天1晚 8人团 含酒店·含门票",
    subtitle: "珠江新城·含酒店·8人团",
    destination: "广州",
    departure_city: "深圳",
    tour_category: 'group_tour',
    travel_type: '跟团游',
    duration: 2,
    badge: '多日游·8人团',
    price: 788,
    original_price: 988,
    rating: 4.7,
    rating_desc: "142条评价",
    sales_count: 156,
    highlights: ['含酒店', '含餐食', '含门票', '纯玩团'],
    tags: ['含酒店', '含门票', '纯玩团', '珠江新城', '广州塔'],
    departure_label: "深圳出发",
    is_featured: false,
    display_order: all_products_data.count + 1,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['深圳康辉旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【精品小团】广州市内精华游 2天1晚 6人团 含酒店·含餐食·纯玩无购物",
    subtitle: "市内精华·纯玩无购物",
    destination: "广州",
    departure_city: "珠海",
    tour_category: 'group_tour',
    travel_type: '跟团游',
    duration: 2,
    badge: '多日游·6人团',
    price: 688,
    original_price: 888,
    rating: 4.9,
    rating_desc: "178条评价",
    sales_count: 203,
    highlights: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物'],
    tags: ['含酒店', '含餐食', '纯玩团', '无购物', '市内游'],
    departure_label: "珠海出发",
    is_featured: false,
    display_order: all_products_data.count + 2,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['广州青旅国际旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【精品小团】广州长隆+珠江夜游 2天1晚 10人团 含酒店·含门票·纯玩团",
    subtitle: "长隆·珠江夜游·10人团",
    destination: "广州",
    departure_city: "佛山",
    tour_category: 'group_tour',
    travel_type: '跟团游',
    duration: 2,
    badge: '多日游·10人团',
    price: 788,
    original_price: 988,
    rating: 4.8,
    rating_desc: "198条评价",
    sales_count: 234,
    highlights: ['含酒店', '含门票', '纯玩团', '无购物'],
    tags: ['含酒店', '含门票', '纯玩团', '长隆', '珠江夜游'],
    departure_label: "佛山出发",
    is_featured: true,
    display_order: all_products_data.count + 3,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['广州青旅国际旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

TourGroupProduct.insert_all(guangzhou_2day_tour_products)
puts "✓ 添加了 #{guangzhou_2day_tour_products.count} 个广州2日跟团游产品"

# 云南7天长线游产品（支持 v285 验证器）
puts "\n🎯 添加云南7天长线游产品..."

yunnan_7day_tour_products = [
  {
    title: "【多日游】云南昆明+大理+丽江+香格里拉 7天6晚 深度游·独立成团·含酒店",
    subtitle: "昆明·大理·丽江·香格里拉·深度游",
    destination: "云南",
    departure_city: "昆明",
    tour_category: 'private_group',
    travel_type: '独立成团',
    duration: 7,
    badge: '多日游·独立成团',
    price: 4388,
    original_price: 5688,
    rating: 4.9,
    rating_desc: "268条评价",
    sales_count: 345,
    highlights: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '深度游览'],
    tags: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '深度游览', '昆明', '大理', '丽江', '香格里拉'],
    departure_label: "昆明出发",
    is_featured: true,
    display_order: all_products_data.count,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['云南假日国际旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【多日游】云南昆明+大理+丽江+泸沽湖 7天6晚 深度游·独立成团·纯玩团",
    subtitle: "泸沽湖·丽江·大理·纯玩团",
    destination: "云南",
    departure_city: "昆明",
    tour_category: 'private_group',
    travel_type: '独立成团',
    duration: 7,
    badge: '多日游·独立成团',
    price: 4588,
    original_price: 5888,
    rating: 4.8,
    rating_desc: "312条评价",
    sales_count: 412,
    highlights: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '深度游览'],
    tags: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '深度游览', '泸沽湖', '丽江', '大理'],
    departure_label: "昆明出发",
    is_featured: true,
    display_order: all_products_data.count + 1,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['云南假日国际旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    title: "【多日游】云南昆明+石林+大理+丽江+玉龙雪山 8天7晚 豪华游·独立成团",
    subtitle: "玉龙雪山·石林·豪华游",
    destination: "云南",
    departure_city: "昆明",
    tour_category: 'private_group',
    travel_type: '独立成团',
    duration: 8,
    badge: '多日游·独立成团',
    price: 5288,
    original_price: 6888,
    rating: 4.9,
    rating_desc: "198条评价",
    sales_count: 289,
    highlights: ['舒适酒店', '全程用餐', '包含门票', '独立成团', '深度游览'],
    tags: ['豪华酒店', '全程用餐', '包含门票', '独立成团', '深度游览', '玉龙雪山', '石林', '大理'],
    departure_label: "昆明出发",
    is_featured: false,
    display_order: all_products_data.count + 2,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map['云南假日国际旅行社'],
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

TourGroupProduct.insert_all(yunnan_7day_tour_products)
puts "✓ 添加了 #{yunnan_7day_tour_products.count} 个云南7天以上长线游产品"

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
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
end

puts "  批量插入 #{all_packages_data.count} 个套餐..."
TourPackage.insert_all(all_packages_data)

# ==================== 批量生成行程数据 ====================
puts "\n📅 批量生成行程数据（智能识别景点和主题）..."

all_itinerary_data = []
timestamp = Time.current

# 景点模板库
attractions_library = {
  '自然风光' => ['观赏日出', '山水徒步', '森林氧吧', '天然湖泊', '草原风光', '雪山远眺'],
  '人文历史' => ['古城游览', '博物馆参观', '寺庙朝拜', '民俗体验', '古镇漫步', '历史遗迹'],
  '休闲娱乐' => ['温泉体验', '特色表演', '美食街', '手工艺制作', '茶艺体验', '夜市逛街'],
  '特色体验' => ['当地美食', '摄影打卡', '互动体验', '文化讲解', '特色活动', '自由活动']
}

# 主题关键词配置
theme_keywords = {
  '禅修' => ['禅修', '冥想', '静心', '灵隐寺', '法喜寺', '径山寺', '素食', '禅茶', '抄经', '养生'],
  '亲子' => ['亲子', '儿童', '科技馆', '动物园', '海洋馆', '乐园', '互动课程', '家庭'],
  '海岛' => ['海岛', '海滩', '潜水', '海鲜', '温泉', '游船', '海上运动'],
  '文化' => ['文化', '博物馆', '古镇', '历史', '遗迹', '古迹', '传统']
}

TourGroupProduct.find_each do |product|
  duration = product.duration
  destination = product.destination
  departure_city = product.departure_city
  title = product.title
  
  # 从标题中提取景点名称（以+分隔的部分）
  title_attractions = title.scan(/([\u4e00-\u9fa5]{2,8}(?:寺|山|湖|岛|海|湾|古镇|公园|景区|馆|洞|寺庙|城|村|谷|港))[+·\s]/).flatten
  title_attractions += title.scan(/(西湖|千岛湖|乌镇|灵隐寺|法喜寺|径山寺|普陀山|蓬莱阁|天坛|故宫|长城|颐和园|天安门)/).flatten
  title_attractions = title_attractions.uniq.first(6)
  
  # 识别主题
  detected_theme = nil
  theme_keywords.each do |theme, keywords|
    if keywords.any? { |kw| title.include?(kw) }
      detected_theme = theme
      break
    end
  end
  
  duration.times do |i|
    day_number = i + 1
    
    if day_number == 1
      # 第一天：抵达日
      first_day_attractions = ["从#{departure_city}出发", "#{destination}机场/车站接站", '酒店办理入住']
      
      # 根据主题调整第一天行程
      case detected_theme
      when '禅修'
        first_day_attractions += ['素食欢迎晚餐', '禅茶体验', '晚间冥想课程(可选)']
      when '亲子'
        first_day_attractions += ['欢迎晚餐', '酒店周边自由活动', '儿童活动室']
      when '海岛'
        first_day_attractions += ['海鲜欢迎晚餐', '海滩漫步', '自由活动']
      else
        first_day_attractions += ['欢迎晚餐(自费)', '酒店周边自由活动']
      end
      
      all_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: day_number,
        title: "出发日 - 抵达#{destination}",
        attractions: first_day_attractions,
        assembly_point: "#{departure_city}机场/车站集合",
        disassembly_point: nil,
        transportation: '飞机/高铁',
        service_info: '专车接站,专人引导入住酒店,提供旅游咨询服务',
        duration_minutes: 480,
        data_version: 0,
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
        data_version: 0,
        created_at: timestamp,
        updated_at: timestamp
      }
    else
      # 中间天：根据主题和景点生成行程
      day_index = day_number - 2  # 从第2天开始的索引
      
      # 选择当天的主景点
      main_attraction = title_attractions[day_index] || "#{destination}特色景点"
      
      # 根据主题生成不同风格的行程
      case detected_theme
      when '禅修'
        day_title = "第#{day_number}天 - #{main_attraction}禅修体验"
        day_attractions = [
          '酒店素食早餐',
          "前往#{main_attraction}",
          "参观#{main_attraction}",
          '禅宗文化讲座',
          '素斋午餐',
          ['冥想课程', '抄经体验', '禅茶一味', '茶道体验'].sample,
          '返回酒店休息'
        ]
        service_info = "含素食早午餐，#{main_attraction}门票，禅修导师讲解，禅修课程指导"
      when '亲子'
        day_title = "第#{day_number}天 - #{main_attraction}亲子游"
        day_attractions = [
          '酒店早餐',
          "前往#{main_attraction}",
          "游览#{main_attraction}",
          ['亲子互动活动', '科普讲解', '手工DIY体验', '儿童游乐设施'].sample,
          '特色午餐',
          ['家庭摄影时间', '互动游戏', '自由活动'].sample,
          '返回酒店'
        ]
        service_info = "含早午餐，#{main_attraction}门票，亲子导游服务，互动体验活动"
      when '海岛'
        day_title = "第#{day_number}天 - #{main_attraction}海岛之旅"
        day_attractions = [
          '酒店早餐',
          "前往#{main_attraction}",
          "游览#{main_attraction}",
          ['海滩自由活动', '海上运动体验(自费)', '潜水体验(自费)'].sample,
          '海鲜自助午餐',
          ['海滩漫步', '日落观赏', '海边摄影'].sample,
          '返回酒店'
        ]
        service_info = "含早午餐，#{main_attraction}门票+往返船票(如需)，专业导游讲解"
      when '文化'
        day_title = "第#{day_number}天 - #{main_attraction}文化之旅"
        day_attractions = [
          '酒店早餐',
          "前往#{main_attraction}",
          "参观#{main_attraction}",
          '文化讲解服务',
          '特色午餐',
          ['博物馆参观', '古迹探索', '民俗体验', '传统手工艺'].sample,
          '返回酒店休息'
        ]
        service_info = "含早午餐，#{main_attraction}门票，文化讲解服务，深度体验"
      else
        # 默认通用行程
        category = ['自然风光', '人文历史', '休闲娱乐', '特色体验'].sample
        day_title = "第#{day_number}天 - #{main_attraction}#{category}游"
        day_attractions = [
          '酒店早餐',
          "前往#{main_attraction}",
          "游览#{main_attraction}"
        ] + attractions_library[category].sample(2) + [
          '当地特色午餐',
          '返回酒店休息'
        ]
        service_info = "含早午餐，#{main_attraction}门票，专业导游讲解服务"
      end
      
      all_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: day_number,
        title: day_title,
        attractions: day_attractions,
        assembly_point: nil,
        disassembly_point: nil,
        transportation: '旅游大巴',
        service_info: service_info,
        duration_minutes: 540,
        data_version: 0,
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

# ==================== 补充：三亚6天5晚跟团游 (tour_groups_supplement) ====================
puts "\n🏖️ 补充三亚6天5晚跟团游产品..."

timestamp_supplement = Time.current

# 查找或创建海南椰风假期旅行社（如果不存在）
agency_hainan = TravelAgency.find_or_create_by(name: "海南椰风假期") do |a|
  a.rating = 4.9
  a.sales_count = 6500
  a.is_verified = true
  a.created_at = timestamp_supplement
  a.updated_at = timestamp_supplement
end

# 补充三亚6天5晚跟团游产品
sanya_6day_products_data = []

['三亚', '海口', '广州', '深圳'].each do |departure_city|
  3.times do |i|
    base_price = rand(3288..5088)
    original_price = (base_price * rand(1.15..1.35)).to_i
    
    attractions = ['蜈支洲岛', '亚龙湾', '天涯海角', '南山寺', '呀诺达雨林', '大小洞天'].sample(4)
    
    title = "【精品小团】三亚#{attractions.join('+')} 6天5晚 #{rand(6..10)}人团 含酒店·含餐食·含门票"
    subtitle = [attractions.first, '纯玩团', '无购物'].join('·')
    
    sanya_6day_products_data << {
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
      image_url: ImageSeedHelper.random_image_from_category(:tours),
      travel_agency_id: agency_hainan.id,
      data_version: 0,
      created_at: timestamp_supplement,
      updated_at: timestamp_supplement
    }
  end
end

TourGroupProduct.insert_all(sanya_6day_products_data) if sanya_6day_products_data.any?
puts "✓ 添加了 #{sanya_6day_products_data.count} 个三亚6天5晚跟团游产品"

# ====================  补充：亲子主题跟团游产品 (family_tour_supplement) ====================
puts "\n👶 补充亲子主题跟团游产品..."

timestamp_family = Time.current

# 亲子主题跟团游产品（支持 v281 验证器）
family_tour_products_data = []

# 每个目的地生成 1-2 个亲子产品
['三亚', '杭州', '北京', '上海', '成都', '广州', '深圳', '厦门', '大连', '青岛'].each_with_index do |destination, idx|
  departure_cities = case destination
  when '三亚' then ['三亚', '海口', '广州', '深圳']
  when '杭州' then ['杭州', '上海', '宁波']
  when '北京' then ['北京', '天津', '石家庄']
  when '上海' then ['上海', '杭州', '南京']
  when '成都' then ['成都', '重庆']
  when '广州' then ['广州', '深圳']
  when '深圳' then ['深圳', '广州', '珠海']
  when '厦门' then ['厦门', '福州']
  when '大连' then ['大连', '沈阳']
  when '青岛' then ['青岛', '济南']
  else [destination]
  end
  
  selected_departure = departure_cities.sample
  
  # 亲子主题景点
  attractions = case destination
  when '三亚' then ['亚龙湾', '蜜月湾', '蒸号湾', '三亚亚龙湾热带天堂森林公园', '三亚海洋馆']
  when '杭州' then ['杭州动物园', '杭州植物园', '西溪湿地', '千岛湖', '乌镇']
  when '北京' then ['北京动物园', '北京欢乐谷', '科技馆', '颐和园', '故宫']
  when '上海' then ['上海迪士尼', '上海海洋水族馆', '上海科技馆', '东方明珠', '世纪公园']
  when '成都' then ['成都大熊猫繁育基地', '成都海昌极地海洋公园', '成都动物园', '锦里', '宽窄巷']
  when '广州' then ['长隆欢乐世界', '广州长隆野生动物世界', '广州海洋馆', '广州科学中心', '广州塔']
  when '深圳' then ['深圳欢乐谷', '世界之窗', '深圳野生动物园', '小梅沙海滨公园', '海上世界']
  when '厦门' then ['厦门科技馆', '厦门海底世界', '胡里山炮台', '曾厝垵', '鼓浪屿']
  when '大连' then ['大连老虎滩海洋公园', '大连森林动物园', '星海广场', '金石滩', '大连发现王国']
  when '青岛' then ['青岛海洋公园', '青岛野生动物世界', '崂木老人村', '金沙滩', '青岛啤酒博物馆']
  else [destination]
  end
  
  selected_attractions = attractions.sample([attractions.count, 4].min)
  
  # 生成 3-5 天的亲子产品
  duration = [3, 4, 5].sample
  nights = duration - 1
  
  base_price = case duration
  when 3 then rand(1588..2588)
  when 4 then rand(2288..3588)
  when 5 then rand(3088..4588)
  end
  
  original_price = (base_price * rand(1.2..1.4)).to_i
  group_size = [4, 6, 8].sample
  
  title = "【精品小团】#{destination}#{selected_attractions.first(2).join('+')} #{duration}天#{nights}晚 #{group_size}人团 亲子游·家庭游·含酒店·含餐食"
  subtitle = "亲子游·#{selected_attractions.first}·适合儿童"
  
  family_tour_products_data << {
    title: title,
    subtitle: subtitle,
    destination: destination,
    departure_city: selected_departure,
    tour_category: 'group_tour',
    travel_type: '跟团游',
    duration: duration,
    badge: "多日游·#{group_size}人团",
    price: base_price,
    original_price: original_price,
    rating: [4.7, 4.8, 4.9].sample,
    rating_desc: "#{rand(50..300)}条评价",
    sales_count: rand(50..500),
    highlights: ['亲子活动', '家庭游', '儿童设施', '含酒店', '含餐食'],
    tags: ['亲子', '家庭', '儿童', '互动体验', '含酒店', '含餐食', '含门票'],
    departure_label: "#{selected_departure}出发",
    is_featured: idx < 3,  # 前3个设置为精选
    display_order: 0,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: agencies_map.values.sample,
    data_version: 0,
    created_at: timestamp_family,
    updated_at: timestamp_family
  }
end

# 补充：特定亲子产品 - 三亚亚龙湾+蜜月湾 4天3晚（支持 v281）
# 确保这个特定产品始终存在，供验证器v281使用
agencies_map = TravelAgency.where(data_version: 0).pluck(:name, :id).to_h
family_tour_products_data << {
  title: '【精品小团】三亚亚龙湾+蜜月湾 4天3晚 6人团 亲子游·家庭游·含酒店·含餐食',
  subtitle: '亲子游·亚龙湾·适合儿童',
  destination: '三亚',
  departure_city: '三亚',
  tour_category: 'group_tour',
  travel_type: '跟团游',
  duration: 4,
  badge: '多日游·6人团',
  price: 2888,
  original_price: 3588,
  rating: 4.9,
  rating_desc: '158条评价',
  sales_count: 256,
  highlights: ['亲子活动', '家庭游', '儿童设施', '含酒店', '含餐食'],
  tags: ['亲子', '家庭', '儿童', '互动体验', '含酒店', '含餐食', '含门票'],
  departure_label: '三亚出发',
  is_featured: true,
  display_order: 0,
  image_url: ImageSeedHelper.random_image_from_category(:tours),
  travel_agency_id: agencies_map.values.sample,
  data_version: 0,
  created_at: timestamp_family,
  updated_at: timestamp_family
}

TourGroupProduct.insert_all(family_tour_products_data) if family_tour_products_data.any?
puts "✓ 添加了 #{family_tour_products_data.count} 个亲子主题跟团游产品"

# 为亲子产品生成套餐
family_packages_data = []

# 查询刚创建的亲子产品
TourGroupProduct.where("tags LIKE ?", "%亲子%")
  .where(data_version: 0)
  .where("created_at >= ?", timestamp_family - 1.minute)
  .find_each do |product|
  # 每个产品生成 2-3 个套餐
  packages_count = rand(2..3)
  
  packages_count.times do |i|
    base_price = product.price
    
    package_price = case i
    when 0 then base_price
    when 1 then (base_price * rand(1.2..1.4)).to_i
    when 2 then (base_price * rand(1.5..1.8)).to_i
    end
    
    child_price = (package_price * rand(0.5..0.7)).to_i  # 亲子游儿童价更低
    
    package_names = case i
    when 0 then ['基础套餐', '经济套餐', '标准套餐']
    when 1 then ['豪华套餐', '高级套餐', '优选套餐']
    when 2 then ['至尊套餐', '尊享套餐', 'VIP套餐']
    end
    
    description = case i
    when 0
      "✓ 三星级亲子酒店住宿\n✓ 包含儿童早餐\n✓ 景点首道门票\n✓ 旅游大巴接送\n✓ 亲子导游服务\n✓ 儿童礼品"
    when 1
      "✓ 四星级亲子主题酒店\n✓ 包含儿童三餐\n✓ 景点门票+互动体验\n✓ 豪华旅游大巴\n✓ 金牌亲子导游\n✓ 赠送亲子意外险\n✓ 儿童专属礼包"
    when 2
      "✓ 五星级亲子度假酒店\n✓ 包含亲子全程餐食\n✓ 景点VIP通道+互动体验\n✓ 商务车接送\n✓ 资深亲子导游一对一\n✓ 赠送亲子意外险+家庭旅拍\n✓ 24小时管家服务\n✓ 儿童超值礼包"
    end
    
    family_packages_data << {
      tour_group_product_id: product.id,
      name: package_names.sample,
      price: package_price,
      child_price: child_price,
      description: description,
      is_featured: i == 0,
      display_order: i,
      purchase_count: rand(10..200),
      data_version: 0,
      created_at: timestamp_family,
      updated_at: timestamp_family
    }
  end
end

TourPackage.insert_all(family_packages_data) if family_packages_data.any?
puts "✓ 为亲子产品添加了 #{family_packages_data.count} 个套餐"

# 为新产品创建套餐
sanya_packages_data = []

TourGroupProduct.where(destination: "三亚", duration: 6, data_version: 0)
  .where("created_at >= ?", timestamp_supplement - 1.minute)
  .find_each do |product|
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
    
    sanya_packages_data << {
      tour_group_product_id: product.id,
      name: package_names.sample,
      price: package_price,
      child_price: child_price,
      description: description,
      is_featured: i == 0,
      data_version: 0,
      created_at: timestamp_supplement,
      updated_at: timestamp_supplement
    }
  end
end

TourPackage.insert_all(sanya_packages_data) if sanya_packages_data.any?
puts "✓ 为三亚产品添加了 #{sanya_packages_data.count} 个套餐"

puts "\n✅ 三亚6天5晚补充数据加载完成！"

# ==================== 补充：北京2日游产品（支持 v154 验证器）====================
puts "\n🏯 补充北京2天1晚跟团游产品..."

timestamp_beijing = Time.current
beijing_agencies = TravelAgency.where("name LIKE ?", '%北京%').or(TravelAgency.where("name LIKE ?", '%天津%')).pluck(:id)
beijing_agency_id = beijing_agencies.first || TravelAgency.first.id

beijing_2day_products_data = []

# 生成4个北京2日游产品
beijing_titles = [
  "【精品小团】北京故宫+天坛+颐和园 2天1晚 含酒店·含餐食·含门票·纯玩团",
  "【精品小团】北京八达岭长城+明十三陵 2天1晚 4人团 纯玩无购物",
  "【精品小团】北京天安门+故宫+长城 2天1晚 6人团 深度游览",
  "【精品小团】北京环球影城+故宫博物院 2天1晚 含门票·纯玩团"
]

beijing_subtitles = [
  "故宫·含酒店·纯玩团",
  "八达岭长城·4人团·无购物",
  "天安门故宫长城·6人团·深度游",
  "环球影城·故宫·纯玩"
]

beijing_titles.each_with_index do |title, idx|
  beijing_2day_products_data << {
    title: title,
    subtitle: beijing_subtitles[idx],
    destination: "北京",
    departure_city: ["北京", "天津"].sample,
    tour_category: 'group_tour',
    travel_type: '跟团游',
    duration: 2,
    badge: "多日游·#{[4, 6].sample}人团",
    price: 688 + rand(0..400),
    original_price: 1088 + rand(0..200),
    rating: [4.7, 4.8, 4.9].sample,
    rating_desc: "#{rand(50..300)}条评价",
    sales_count: rand(50..500),
    highlights: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物'].sample(3),
    tags: ['含酒店', '含餐食', '含门票', '纯玩团', '无购物'],
    departure_label: "北京出发",
    is_featured: idx == 0,
    display_order: 10000 + idx,
    image_url: ImageSeedHelper.random_image_from_category(:tours),
    travel_agency_id: beijing_agency_id,
    data_version: 0,
    created_at: timestamp_beijing,
    updated_at: timestamp_beijing
  }
end

TourGroupProduct.insert_all(beijing_2day_products_data) if beijing_2day_products_data.any?
puts "✓ 添加了 #{beijing_2day_products_data.count} 个北京2天1晚跟团游产品"

# 为新产品创建套餐
beijing_packages_data = []

TourGroupProduct.where(destination: "北京", duration: 2, data_version: 0)
  .where("created_at >= ?", timestamp_beijing - 1.minute)
  .find_each do |product|
  # 每个产品生成2-3个套餐
  packages_count = rand(2..3)
  
  packages_count.times do |i|
    base_price = product.price
    
    package_price = case i
    when 0 then base_price
    when 1 then (base_price * rand(1.2..1.4)).to_i
    when 2 then (base_price * rand(1.5..1.7)).to_i
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
      "✓ 五星级酒店住宿\n✓ 包含三餐(含特色餐)\n✓ 景点VIP通道+深度体验\n✓ 商务车接送\n✓ 资深导游一对一服务\n✓ 赠送旅游意外险"
    end
    
    beijing_packages_data << {
      tour_group_product_id: product.id,
      name: package_names.sample,
      price: package_price,
      child_price: child_price,
      description: description,
      is_featured: i == 0,
      data_version: 0,
      created_at: timestamp_beijing,
      updated_at: timestamp_beijing
    }
  end
end

TourPackage.insert_all(beijing_packages_data) if beijing_packages_data.any?
puts "✓ 为北京产品添加了 #{beijing_packages_data.count} 个套餐"

puts "\n✅ 北京2天1晚补充数据加载完成！"

# ==================== 补充：北京2日游产品行程安排 ====================
puts "\n📅 添加北京2天1晚行程安排..."

timestamp_itinerary = Time.current
beijing_itinerary_data = []

# 查询刚创建的4个北京产品
beijing_products = TourGroupProduct.where(destination: "北京", duration: 2, data_version: 0)
  .where("created_at >= ?", timestamp_beijing - 1.minute)
  .order(:id)
  .to_a

if beijing_products.any?
  beijing_products.each do |product|
    # 根据产品标题判断类型，生成对应行程
    if product.title.include?("故宫+天坛+颐和园")
      # 产品1：故宫+天坛+颐和园 2天1晚
      beijing_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: 1,
        title: "第1天 - 抵达北京·故宫+天坛",
        attractions: ["#{product.departure_city}出发", "北京机场/车站接站", "前往酒店办理入住", "午餐后游览故宫博物院", "参观天坛公园", "王府井步行街自由活动"],
        assembly_point: "#{product.departure_city}机场/车站集合",
        disassembly_point: nil,
        transportation: "飞机/高铁+旅游大巴",
        service_info: "专车接站，含午餐晚餐，故宫讲解服务，天坛门票",
        duration_minutes: 540,
        data_version: 0,
        created_at: timestamp_itinerary,
        updated_at: timestamp_itinerary
      }
      beijing_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: 2,
        title: "第2天 - 颐和园·返程",
        attractions: ["酒店早餐", "游览颐和园", "昆明湖游船体验", "特色午餐", "专车送站", "返回#{product.departure_city}"],
        assembly_point: nil,
        disassembly_point: "北京机场/车站",
        transportation: "旅游大巴+飞机/高铁",
        service_info: "含早餐午餐，颐和园门票+游船，专车送站",
        duration_minutes: 420,
        data_version: 0,
        created_at: timestamp_itinerary,
        updated_at: timestamp_itinerary
      }
    elsif product.title.include?("八达岭长城+明十三陵")
      # 产品2：八达岭长城+明十三陵 2天1晚
      beijing_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: 1,
        title: "第1天 - 抵达北京·八达岭长城",
        attractions: ["#{product.departure_city}出发", "北京机场/车站接站", "前往八达岭长城", "登长城观景", "长城脚下农家菜午餐", "入住酒店", "晚餐自由安排"],
        assembly_point: "#{product.departure_city}机场/车站集合",
        disassembly_point: nil,
        transportation: "飞机/高铁+旅游大巴",
        service_info: "专车接站，含午餐，长城门票+缆车，4人精品小团",
        duration_minutes: 540,
        data_version: 0,
        created_at: timestamp_itinerary,
        updated_at: timestamp_itinerary
      }
      beijing_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: 2,
        title: "第2天 - 明十三陵·返程",
        attractions: ["酒店早餐", "游览明十三陵-长陵", "神道参观", "特色午餐", "专车送站", "返回#{product.departure_city}"],
        assembly_point: nil,
        disassembly_point: "北京机场/车站",
        transportation: "旅游大巴+飞机/高铁",
        service_info: "含早餐午餐，明十三陵门票，纯玩无购物",
        duration_minutes: 420,
        data_version: 0,
        created_at: timestamp_itinerary,
        updated_at: timestamp_itinerary
      }
    elsif product.title.include?("天安门+故宫+长城")
      # 产品3：天安门+故宫+长城 2天1晚
      beijing_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: 1,
        title: "第1天 - 抵达北京·天安门+故宫",
        attractions: ["#{product.departure_city}出发", "北京机场/车站接站", "天安门广场升旗仪式(如时间允许)", "游览故宫博物院", "景山公园俯瞰紫禁城", "入住酒店"],
        assembly_point: "#{product.departure_city}机场/车站集合",
        disassembly_point: nil,
        transportation: "飞机/高铁+旅游大巴",
        service_info: "专车接站，含午餐晚餐，故宫深度讲解，6人精品团",
        duration_minutes: 540,
        data_version: 0,
        created_at: timestamp_itinerary,
        updated_at: timestamp_itinerary
      }
      beijing_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: 2,
        title: "第2天 - 八达岭长城·返程",
        attractions: ["酒店早餐", "前往八达岭长城", "登长城体验", "长城脚下午餐", "专车送站", "返回#{product.departure_city}"],
        assembly_point: nil,
        disassembly_point: "北京机场/车站",
        transportation: "旅游大巴+飞机/高铁",
        service_info: "含早餐午餐，长城门票+缆车，深度游览",
        duration_minutes: 420,
        data_version: 0,
        created_at: timestamp_itinerary,
        updated_at: timestamp_itinerary
      }
    elsif product.title.include?("环球影城+故宫博物院")
      # 产品4：环球影城+故宫博物院 2天1晚
      beijing_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: 1,
        title: "第1天 - 抵达北京·北京环球影城",
        attractions: ["#{product.departure_city}出发", "北京机场/车站接站", "前往北京环球影城", "全天畅玩环球影城", "哈利波特魔法世界", "变形金刚基地", "入住酒店"],
        assembly_point: "#{product.departure_city}机场/车站集合",
        disassembly_point: nil,
        transportation: "飞机/高铁+旅游大巴",
        service_info: "专车接站，环球影城门票，快速通行证(可选)",
        duration_minutes: 600,
        data_version: 0,
        created_at: timestamp_itinerary,
        updated_at: timestamp_itinerary
      }
      beijing_itinerary_data << {
        tour_group_product_id: product.id,
        day_number: 2,
        title: "第2天 - 故宫博物院·返程",
        attractions: ["酒店早餐", "游览故宫博物院", "珍宝馆参观", "御花园漫步", "特色午餐", "专车送站", "返回#{product.departure_city}"],
        assembly_point: nil,
        disassembly_point: "北京机场/车站",
        transportation: "旅游大巴+飞机/高铁",
        service_info: "含早餐午餐，故宫门票+讲解，纯玩团",
        duration_minutes: 420,
        data_version: 0,
        created_at: timestamp_itinerary,
        updated_at: timestamp_itinerary
      }
    end
  end
end

TourItineraryDay.insert_all(beijing_itinerary_data) if beijing_itinerary_data.any?
puts "✓ 为 #{beijing_products.count} 个北京产品添加了 #{beijing_itinerary_data.count} 天行程"

# ==================== 补充：三亚6日游产品行程安排 ====================
puts "\n📅 添加三亚6天5晚行程安排..."

sanya_itinerary_data = []

# 查询所有三亚6天产品（包括之前创建的12个缺少行程的产品）
sanya_products = TourGroupProduct.where(destination: "三亚", duration: 6, data_version: 0)
  .where("created_at >= ?", timestamp_supplement - 1.minute)
  .order(:id)
  .to_a

if sanya_products.any?
  sanya_products.each do |product|
    # 从标题中提取景点信息
    attractions_in_title = product.title.scan(/(蜈支洲岛|亚龙湾|天涯海角|南山寺|呀诺达雨林|大小洞天)/).flatten
    
    # 第1天：抵达三亚
    sanya_itinerary_data << {
      tour_group_product_id: product.id,
      day_number: 1,
      title: "第1天 - 抵达三亚·欢迎晚宴",
      attractions: ["#{product.departure_city}出发", "三亚凤凰机场接机", "前往酒店办理入住", "自由活动", "三亚海鲜欢迎晚宴"],
      assembly_point: "#{product.departure_city}机场集合",
      disassembly_point: nil,
      transportation: "飞机+旅游大巴",
      service_info: "专车接机，入住海景酒店，含欢迎晚宴",
      duration_minutes: 300,
      data_version: 0,
      created_at: timestamp_itinerary,
      updated_at: timestamp_itinerary
    }
    
    # 第2天：根据景点组合动态生成
    day2_attraction = attractions_in_title[0] || "亚龙湾"
    sanya_itinerary_data << {
      tour_group_product_id: product.id,
      day_number: 2,
      title: "第2天 - #{day2_attraction}一日游",
      attractions: ["酒店早餐", "前往#{day2_attraction}", "#{day2_attraction}深度游览", "海滩自由活动", "特色海鲜午餐", "返回酒店休息"],
      assembly_point: nil,
      disassembly_point: nil,
      transportation: "旅游大巴",
      service_info: "含早午餐，#{day2_attraction}门票，专业导游讲解",
      duration_minutes: 480,
      data_version: 0,
      created_at: timestamp_itinerary,
      updated_at: timestamp_itinerary
    }
    
    # 第3天
    day3_attraction = attractions_in_title[1] || "蜈支洲岛"
    sanya_itinerary_data << {
      tour_group_product_id: product.id,
      day_number: 3,
      title: "第3天 - #{day3_attraction}精华游",
      attractions: ["酒店早餐", "前往#{day3_attraction}", "#{day3_attraction}游览", "水上项目体验(自费)", "海鲜自助午餐", "下午茶时光", "返回酒店"],
      assembly_point: nil,
      disassembly_point: nil,
      transportation: "旅游大巴",
      service_info: "含早午餐，#{day3_attraction}门票+往返船票(如需)",
      duration_minutes: 540,
      data_version: 0,
      created_at: timestamp_itinerary,
      updated_at: timestamp_itinerary
    }
    
    # 第4天
    day4_attraction = attractions_in_title[2] || "南山寺"
    sanya_itinerary_data << {
      tour_group_product_id: product.id,
      day_number: 4,
      title: "第4天 - #{day4_attraction}文化之旅",
      attractions: ["酒店早餐", "前往#{day4_attraction}", "#{day4_attraction}参观", "素斋午餐", "祈福体验", "返回酒店自由活动"],
      assembly_point: nil,
      disassembly_point: nil,
      transportation: "旅游大巴",
      service_info: "含早午餐，#{day4_attraction}门票，文化讲解服务",
      duration_minutes: 480,
      data_version: 0,
      created_at: timestamp_itinerary,
      updated_at: timestamp_itinerary
    }
    
    # 第5天
    day5_attraction = attractions_in_title[3] || "大小洞天"
    sanya_itinerary_data << {
      tour_group_product_id: product.id,
      day_number: 5,
      title: "第5天 - #{day5_attraction}探秘",
      attractions: ["酒店早餐", "前往#{day5_attraction}", "#{day5_attraction}游览", "自然风光摄影", "特色午餐", "三亚免税店购物(自由安排)", "海滩漫步"],
      assembly_point: nil,
      disassembly_point: nil,
      transportation: "旅游大巴",
      service_info: "含早午餐，#{day5_attraction}门票，摄影指导",
      duration_minutes: 540,
      data_version: 0,
      created_at: timestamp_itinerary,
      updated_at: timestamp_itinerary
    }
    
    # 第6天：返程
    sanya_itinerary_data << {
      tour_group_product_id: product.id,
      day_number: 6,
      title: "第6天 - 自由活动·返程",
      attractions: ["酒店早餐", "酒店周边自由活动", "退房", "专车送机", "返回#{product.departure_city}", "结束愉快旅程"],
      assembly_point: nil,
      disassembly_point: "三亚凤凰机场",
      transportation: "旅游大巴+飞机",
      service_info: "含早餐，专车送机，协助办理登机手续",
      duration_minutes: 360,
      data_version: 0,
      created_at: timestamp_itinerary,
      updated_at: timestamp_itinerary
    }
  end
end

TourItineraryDay.insert_all(sanya_itinerary_data) if sanya_itinerary_data.any?
puts "✓ 为 #{sanya_products.count} 个三亚产品添加了 #{sanya_itinerary_data.count} 天行程"

puts "\n✅ 所有补充行程数据加载完成！"
