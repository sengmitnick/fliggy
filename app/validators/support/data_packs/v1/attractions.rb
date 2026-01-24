# frozen_string_literal: true

# 景点数据包 - 使用 insert_all 批量插入
# 包含景点、门票、园内项目、评价等数据

puts "正在加载景点数据包..."

# 清理现有数据
puts "🧹 清理现有景点数据..."
AttractionReview.destroy_all
ActivityOrder.destroy_all
TicketOrder.destroy_all
AttractionActivity.destroy_all
Ticket.destroy_all
Attraction.destroy_all

timestamp = Time.current

# ==================== 景点数据 ====================
puts "\n🎡 批量创建景点..."

attractions_data = [
  {
    name: "深圳欢乐港湾",
    slug: "shenzhen-happy-harbor",
    province: "广东省",
    city: "深圳市",
    district: "宝安区",
    address: "深圳市宝安区海天路与宝华路交汇处",
    latitude: 22.563889,
    longitude: 113.862222,
    description: "欢乐港湾是深圳西部的滨海文化旅游新地标，集主题乐园、文化演艺、购物餐饮于一体。这里拥有全球最大的海上摩天轮，以及精彩的水幕灯光秀表演。",
    opening_hours: "10:00-22:00",
    phone: "0755-88888888",
    rating: 4.5,
    review_count: 1258,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海迪士尼乐园",
    slug: "shanghai-disney",
    province: "上海市",
    city: "上海市",
    district: "浦东新区",
    address: "上海市浦东新区川沙新镇上海迪士尼度假区",
    latitude: 31.145,
    longitude: 121.666,
    description: "中国大陆首座迪士尼主题乐园，拥有七大主题园区，包括米奇大街、奇想花园、梦幻世界、探险岛、宝藏湾、明日世界和迪士尼·皮克斯玩具总动员主题园区，适合全家游玩。",
    opening_hours: "09:00-21:00",
    phone: "021-31580000",
    rating: 4.7,
    review_count: 8520,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "北京环球影城",
    slug: "beijing-universal",
    province: "北京市",
    city: "北京市",
    district: "通州区",
    address: "北京市通州区京哈高速与东六环路交汇处",
    latitude: 39.876,
    longitude: 116.704,
    description: "全球最大的环球影城主题公园，七大主题景区带你进入电影世界。包括哈利·波特的魔法世界、变形金刚基地、小黄人乐园、侏罗纪世界努布拉岛、好莱坞、未来水世界和功夫熊猫盖世之地。",
    opening_hours: "09:00-20:00",
    phone: "010-67778899",
    rating: 4.6,
    review_count: 6352,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "广州长隆欢乐世界",
    slug: "guangzhou-chimelong",
    province: "广东省",
    city: "广州市",
    district: "番禺区",
    address: "广州市番禺区汉溪大道东与长隆地铁大道交汇处",
    latitude: 23.004,
    longitude: 113.329,
    description: "华南地区最大的主题乐园，拥有70余套游乐设施，刺激与欢乐并存。园内有垂直过山车、十环过山车、摩托过山车等世界级游乐设施，还有精彩的国际大马戏表演。",
    opening_hours: "10:00-18:00",
    phone: "020-84783838",
    rating: 4.4,
    review_count: 4235,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "杭州宋城",
    slug: "hangzhou-songcheng",
    province: "浙江省",
    city: "杭州市",
    district: "西湖区",
    address: "浙江省杭州市西湖区之江路148号",
    latitude: 30.195,
    longitude: 120.100,
    description: "给我一天，还你千年。大型主题公园，再现宋代繁华。园内有宋城千古情演出、清明上河图、步步惊心鬼屋等特色项目，是体验宋代文化的绝佳去处。",
    opening_hours: "10:00-21:00",
    phone: "0571-87313101",
    rating: 4.3,
    review_count: 3128,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "成都欢乐谷",
    slug: "chengdu-happy-valley",
    province: "四川省",
    city: "成都市",
    district: "金牛区",
    address: "四川省成都市金牛区西华大道16号",
    latitude: 30.717,
    longitude: 104.006,
    description: "西南地区大型现代主题乐园，拥有阳光港、欢乐时光、加勒比旋风等八大主题区域。园内有雪域雄鹰、天地双雄、飞行岛等30余项游乐设施。",
    opening_hours: "09:30-18:00",
    phone: "028-87512666",
    rating: 4.4,
    review_count: 2856,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

Attraction.insert_all(attractions_data)
puts "✓ 已批量创建 #{Attraction.count} 个景点"

# 获取景点ID映射
attractions_map = Attraction.pluck(:slug, :id).to_h

# ==================== 门票数据 ====================
puts "\n🎫 批量创建门票..."

tickets_data = [
  # 深圳欢乐港湾门票
  {
    attraction_id: attractions_map["shenzhen-happy-harbor"],
    name: "欢乐港湾成人票",
    ticket_type: "adult",
    requirements: "适用于18-59周岁成人，含所有常规项目",
    current_price: 180,
    original_price: 220,
    stock: -1,
    validity_days: 1,
    refund_policy: "未使用可随时退款，使用后不可退",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["shenzhen-happy-harbor"],
    name: "欢乐港湾儿童票",
    ticket_type: "child",
    requirements: "适用于3-17周岁儿童，含所有常规项目",
    current_price: 120,
    original_price: 150,
    stock: -1,
    validity_days: 1,
    refund_policy: "未使用可随时退款，使用后不可退",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # 上海迪士尼门票
  {
    attraction_id: attractions_map["shanghai-disney"],
    name: "迪士尼乐园标准票",
    ticket_type: "adult",
    requirements: "一日票，畅玩所有项目",
    current_price: 499,
    original_price: 599,
    stock: -1,
    validity_days: 1,
    refund_policy: "需提前3天申请退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["shanghai-disney"],
    name: "迪士尼乐园儿童票",
    ticket_type: "child",
    requirements: "适用于3-11周岁儿童",
    current_price: 375,
    original_price: 449,
    stock: -1,
    validity_days: 1,
    refund_policy: "需提前3天申请退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["shanghai-disney"],
    name: "迪士尼两日联票",
    ticket_type: "adult",
    requirements: "连续两天畅玩，更尽兴",
    current_price: 950,
    original_price: 1198,
    stock: -1,
    validity_days: 2,
    refund_policy: "需提前7天申请退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # 北京环球影城门票
  {
    attraction_id: attractions_map["beijing-universal"],
    name: "环球影城标准门票",
    ticket_type: "adult",
    requirements: "含所有园区和项目，不含快速通行",
    current_price: 418,
    original_price: 528,
    stock: -1,
    validity_days: 1,
    refund_policy: "需提前48小时申请退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["beijing-universal"],
    name: "环球影城儿童票",
    ticket_type: "child",
    requirements: "适用于3-11周岁儿童",
    current_price: 315,
    original_price: 398,
    stock: -1,
    validity_days: 1,
    refund_policy: "需提前48小时申请退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["beijing-universal"],
    name: "环球影城学生票",
    ticket_type: "student",
    requirements: "持学生证享受优惠价",
    current_price: 375,
    original_price: 475,
    stock: -1,
    validity_days: 1,
    refund_policy: "需提前48小时申请退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # 广州长隆门票
  {
    attraction_id: attractions_map["guangzhou-chimelong"],
    name: "长隆欢乐世界全日票",
    ticket_type: "adult",
    requirements: "全天畅玩，含所有项目",
    current_price: 280,
    original_price: 350,
    stock: -1,
    validity_days: 1,
    refund_policy: "未使用可随时退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["guangzhou-chimelong"],
    name: "长隆欢乐世界儿童票",
    ticket_type: "child",
    requirements: "适用于3-17周岁儿童",
    current_price: 196,
    original_price: 245,
    stock: -1,
    validity_days: 1,
    refund_policy: "未使用可随时退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # 杭州宋城门票
  {
    attraction_id: attractions_map["hangzhou-songcheng"],
    name: "宋城景区+千古情演出",
    ticket_type: "adult",
    requirements: "含景区门票和千古情演出",
    current_price: 310,
    original_price: 390,
    stock: -1,
    validity_days: 1,
    refund_policy: "需提前24小时申请退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["hangzhou-songcheng"],
    name: "宋城儿童套票",
    ticket_type: "child",
    requirements: "适用于3-17周岁儿童",
    current_price: 217,
    original_price: 273,
    stock: -1,
    validity_days: 1,
    refund_policy: "需提前24小时申请退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # 成都欢乐谷门票
  {
    attraction_id: attractions_map["chengdu-happy-valley"],
    name: "欢乐谷成人日场票",
    ticket_type: "adult",
    requirements: "全天畅玩，含大部分项目",
    current_price: 230,
    original_price: 280,
    stock: -1,
    validity_days: 1,
    refund_policy: "未使用可随时退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["chengdu-happy-valley"],
    name: "欢乐谷儿童票",
    ticket_type: "child",
    requirements: "适用于3-17周岁儿童或1.2-1.5米儿童",
    current_price: 150,
    original_price: 180,
    stock: -1,
    validity_days: 1,
    refund_policy: "未使用可随时退款",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

Ticket.insert_all(tickets_data)
puts "✓ 已批量创建 #{Ticket.count} 张门票"

# ==================== 供应商数据 ====================
puts "\n🏢 批量创建供应商..."

suppliers_data = [
  {
    name: "飞猪景区乐园旗舰店",
    supplier_type: "official",
    rating: 4.8,
    sales_count: 3800,
    description: "7×24小时官网客服·极速响应·售后无忧",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "票圈小叮当旅游专营店",
    supplier_type: "agent",
    rating: 4.6,
    sales_count: 2200,
    description: "随时全额退 无需取票",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳木子花开旅游专营店",
    supplier_type: "agent",
    rating: 4.5,
    sales_count: 3000,
    description: "条件退 无需取票",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "重庆齐旅通旅游专营店",
    supplier_type: "agent",
    rating: 4.3,
    sales_count: 1700,
    description: "随时全额退 无需取票",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

Supplier.insert_all(suppliers_data)
puts "✓ 已批量创建 #{Supplier.count} 个供应商"

# 获取供应商ID映射
suppliers_map = Supplier.pluck(:name, :id).to_h

# 获取门票ID映射（通过名称）
tickets_map = Ticket.pluck(:name, :id).to_h

# ==================== 门票供应商关联数据 ====================
puts "\n🔗 批量创建门票供应商关联..."

ticket_suppliers_data = []

# 为每个门票创建多个供应商选项（成人票和儿童票）
[
  { ticket_name: "欢乐港湾成人票", base_price: 180 },
  { ticket_name: "欢乐港湾儿童票", base_price: 120 },
  { ticket_name: "迪士尼乐园标准票", base_price: 499 },
  { ticket_name: "迪士尼乐园儿童票", base_price: 375 },
  { ticket_name: "环球影城标准门票", base_price: 418 },
  { ticket_name: "环球影城儿童票", base_price: 320 },
  { ticket_name: "长隆欢乐世界成人票", base_price: 250 },
  { ticket_name: "长隆欢乐世界儿童票", base_price: 175 },
  { ticket_name: "宋城景区+千古情演出", base_price: 310 },
  { ticket_name: "宋城儿童套票", base_price: 217 },
  { ticket_name: "欢乐谷成人日场票", base_price: 230 },
  { ticket_name: "欢乐谷儿童票", base_price: 150 }
].each do |ticket_info|
  ticket_id = tickets_map[ticket_info[:ticket_name]]
  next unless ticket_id
  
  base_price = ticket_info[:base_price]
  
  # 供应商1：飞猪（官方旗舰店，最贵但服务最好）
  ticket_suppliers_data << {
    ticket_id: ticket_id,
    supplier_id: suppliers_map["飞猪景区乐园旗舰店"],
    current_price: base_price,
    original_price: (base_price * 1.2).round,
    stock: -1,
    discount_info: "度假优惠",
    sales_count: rand(300..500),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 供应商2：票圈（性价比高）
  ticket_suppliers_data << {
    ticket_id: ticket_id,
    supplier_id: suppliers_map["票圈小叮当旅游专营店"],
    current_price: (base_price * 0.95).round,
    original_price: (base_price * 1.1).round,
    stock: -1,
    discount_info: "1张券",
    sales_count: rand(200..300),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 供应商3：木子花开（价格适中）
  ticket_suppliers_data << {
    ticket_id: ticket_id,
    supplier_id: suppliers_map["深圳木子花开旅游专营店"],
    current_price: (base_price * 1.1).round,
    original_price: (base_price * 1.3).round,
    stock: -1,
    discount_info: nil,
    sales_count: rand(300..400),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 供应商4：齐旅通（价格最低）
  ticket_suppliers_data << {
    ticket_id: ticket_id,
    supplier_id: suppliers_map["重庆齐旅通旅游专营店"],
    current_price: (base_price * 0.88).round,
    original_price: base_price,
    stock: -1,
    discount_info: nil,
    sales_count: rand(100..200),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

TicketSupplier.insert_all(ticket_suppliers_data) if ticket_suppliers_data.any?
puts "✓ 已批量创建 #{TicketSupplier.count} 条门票供应商关联"

# ==================== 园内项目数据 ====================
puts "\n🎢 批量创建园内项目..."

activities_data = [
  # 深圳欢乐港湾项目
  {
    attraction_id: attractions_map["shenzhen-happy-harbor"],
    name: "海上摩天轮",
    activity_type: "ride",
    description: "湾区最大摩天轮，360度海景尽收眼底，高度达128米，是深圳新地标",
    current_price: 60,
    original_price: 80,
    duration: "约20分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["shenzhen-happy-harbor"],
    name: "水幕灯光秀",
    activity_type: "show",
    description: "大型水幕表演，结合音乐、灯光、喷泉，每晚8点准时开始",
    current_price: 50,
    original_price: 50,
    duration: "约30分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["shenzhen-happy-harbor"],
    name: "专业摄影服务",
    activity_type: "photo_service",
    description: "专业摄影师全程跟拍，提供精修照片10张，含电子版和实体相册",
    current_price: 299,
    original_price: 399,
    duration: "约2小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["shenzhen-happy-harbor"],
    name: "海景餐厅套餐",
    activity_type: "dining",
    description: "海景餐厅双人套餐，含主菜+甜点+饮品，享受海景美食",
    current_price: 188,
    original_price: 238,
    duration: "不限时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # 上海迪士尼项目
  {
    attraction_id: attractions_map["shanghai-disney"],
    name: "创极速光轮",
    activity_type: "ride",
    description: "全球最快过山车之一，极速飞驰体验，刺激指数五颗星",
    current_price: 0,
    original_price: 0,
    duration: "约3分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["shanghai-disney"],
    name: "冰雪奇缘欢唱盛会",
    activity_type: "show",
    description: "与艾莎、安娜一起欢唱，沉浸式互动体验",
    current_price: 0,
    original_price: 0,
    duration: "约25分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["shanghai-disney"],
    name: "迪士尼专业摄影",
    activity_type: "photo_service",
    description: "官方摄影师拍摄，含城堡全景、人物特写，提供20张精修照片",
    current_price: 599,
    original_price: 799,
    duration: "约3小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["shanghai-disney"],
    name: "米奇主题餐厅",
    activity_type: "dining",
    description: "与迪士尼明星共进晚餐，含自助餐和合影机会",
    current_price: 368,
    original_price: 428,
    duration: "约90分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # 北京环球影城项目
  {
    attraction_id: attractions_map["beijing-universal"],
    name: "哈利波特禁忌之旅",
    activity_type: "ride",
    description: "跟随哈利波特穿越霍格沃茨，4D沉浸式体验魔法世界",
    current_price: 0,
    original_price: 0,
    duration: "约5分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["beijing-universal"],
    name: "变形金刚3D骑乘",
    activity_type: "ride",
    description: "与汽车人并肩作战，对抗霸天虎，震撼的3D特效",
    current_price: 0,
    original_price: 0,
    duration: "约4分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["beijing-universal"],
    name: "魔法世界专业摄影",
    activity_type: "photo_service",
    description: "霍格沃茨城堡前专业拍摄，含魔法袍租赁和15张精修照片",
    current_price: 499,
    original_price: 699,
    duration: "约2小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["beijing-universal"],
    name: "黄油啤酒体验套餐",
    activity_type: "dining",
    description: "含黄油啤酒+英式套餐，体验哈利波特同款美食",
    current_price: 158,
    original_price: 198,
    duration: "不限时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # 广州长隆项目
  {
    attraction_id: attractions_map["guangzhou-chimelong"],
    name: "垂直过山车",
    activity_type: "ride",
    description: "垂直跌落70米，挑战心跳极限，是亚洲最刺激的过山车之一",
    current_price: 0,
    original_price: 0,
    duration: "约2分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["guangzhou-chimelong"],
    name: "国际大马戏",
    activity_type: "show",
    description: "世界顶级马戏表演，汇集全球顶尖马戏团队",
    current_price: 150,
    original_price: 200,
    duration: "约90分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["guangzhou-chimelong"],
    name: "园区专业摄影",
    activity_type: "photo_service",
    description: "专业摄影师跟拍，记录欢乐时光，提供精修照片12张",
    current_price: 388,
    original_price: 488,
    duration: "约2小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # 杭州宋城项目
  {
    attraction_id: attractions_map["hangzhou-songcheng"],
    name: "宋城千古情",
    activity_type: "show",
    description: "大型歌舞表演，再现宋朝繁华盛世，气势恢宏",
    current_price: 0,
    original_price: 0,
    duration: "约60分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["hangzhou-songcheng"],
    name: "古装摄影体验",
    activity_type: "photo_service",
    description: "宋代服饰+专业摄影+精修10张，穿越回宋朝",
    current_price: 299,
    original_price: 399,
    duration: "约1.5小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["hangzhou-songcheng"],
    name: "宋代美食体验",
    activity_type: "dining",
    description: "品尝正宗宋代美食套餐，体验宋朝饮食文化",
    current_price: 128,
    original_price: 168,
    duration: "不限时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # 成都欢乐谷项目
  {
    attraction_id: attractions_map["chengdu-happy-valley"],
    name: "雪域雄鹰",
    activity_type: "ride",
    description: "西南地区最大悬挂式过山车，体验飞翔的感觉",
    current_price: 0,
    original_price: 0,
    duration: "约3分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["chengdu-happy-valley"],
    name: "玛雅灾难",
    activity_type: "show",
    description: "4D特效剧场，体验玛雅文明末日灾难",
    current_price: 0,
    original_price: 0,
    duration: "约15分钟",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    attraction_id: attractions_map["chengdu-happy-valley"],
    name: "园区跟拍服务",
    activity_type: "photo_service",
    description: "专业摄影师全天跟拍，记录每个精彩瞬间",
    current_price: 328,
    original_price: 428,
    duration: "全天",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

AttractionActivity.insert_all(activities_data)
puts "✓ 已批量创建 #{AttractionActivity.count} 个园内项目"

# ==================== 评价数据 ====================
puts "\n⭐ 批量创建评价..."

# 确保有Demo用户
demo_user = User.find_or_create_by(email: "demo@example.com") do |u|
  u.name = "演示用户"
  u.password_digest = BCrypt::Password.create("password123")
end

review_comments = [
  { rating: 5, comment: "景点太棒了！项目丰富，玩了一整天都不够，强烈推荐！" },
  { rating: 5, comment: "带孩子来的，孩子玩得非常开心，设施很安全，服务也很好。" },
  { rating: 4, comment: "整体体验不错，就是人有点多，排队时间较长。" },
  { rating: 5, comment: "值得一去！环境很好，工作人员态度也很友善。" },
  { rating: 4, comment: "门票价格稍贵，但玩下来觉得还是物有所值的。" },
  { rating: 5, comment: "和朋友一起来的，大家都玩得很尽兴，拍了很多美照！" },
  { rating: 4, comment: "项目很刺激，适合年轻人，带老人的话要注意选择合适的项目。" },
  { rating: 5, comment: "园区很大，建议提前规划路线，可以下载官方APP查看项目排队情况。" }
]

reviews_data = []
Attraction.find_each do |attraction|
  # 每个景点创建5-8条评价
  review_comments.sample(rand(5..8)).each do |review|
    reviews_data << {
      attraction_id: attraction.id,
      user_id: demo_user.id,
      rating: review[:rating],
      comment: review[:comment],
      helpful_count: rand(0..50),
      data_version: 0,
      created_at: timestamp - rand(1..30).days,
      updated_at: timestamp - rand(1..30).days
    }
  end
end

AttractionReview.insert_all(reviews_data)
puts "✓ 已批量创建 #{AttractionReview.count} 条评价"

# 更新景点统计数据（rating 和 review_count）
puts "\n🔄 更新景点统计数据..."
Attraction.find_each do |attraction|
  reviews = AttractionReview.where(attraction_id: attraction.id)
  attraction.update_columns(
    rating: reviews.average(:rating)&.round(1) || 0,
    review_count: reviews.count
  )
end

puts "\n" + "="*50
puts "✅ 景点数据包加载完成！"
puts "="*50
puts "📊 数据统计："
puts "  - 景点数量: #{Attraction.count}"
puts "  - 门票数量: #{Ticket.count}"
puts "  - 供应商数量: #{Supplier.count}"
puts "  - 门票供应商关联: #{TicketSupplier.count}"
puts "  - 园内项目: #{AttractionActivity.count}"
puts "  - 评价数量: #{AttractionReview.count}"
puts "="*50
