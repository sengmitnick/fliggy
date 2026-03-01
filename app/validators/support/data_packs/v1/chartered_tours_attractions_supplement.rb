# frozen_string_literal: true

require_relative '../../../../../app/helpers/image_seed_helper'

# 景点补充数据包 - chartered_tours.rb 的补充文件
# 
# 用途：
# 1. 创建22个精选高质量景点（深圳、上海、北京等热门城市）
# 2. 为精选景点添加详细门票、活动、一日游数据
# 3. 为 chartered_tours.rb 创建的景点（华山、南山一棵树等）补充门票和活动
#
# ⚠️ 加载顺序依赖：
# - chartered_tours.rb 先加载（批量创建74个城市的基础景点）
# - 本文件后加载（通过字母顺序：chartered_tours < chartered_tours_attractions_supplement）
# - 使用 find_by 查询 chartered_tours.rb 创建的景点，为其补充门票和活动
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载景点补充数据包（chartered_tours_attractions_supplement）..."

timestamp = Time.current

# ==================== 景点数据 ====================

attractions_data = [
  # ========== 深圳景点 (8个) ==========
  {
    name: "深圳欢乐港湾",
    slug: "shenzhen-happy-harbor",
    city: "深圳",
    district: "宝安区",
    address: "深圳市宝安区海天路与宝华路交汇处",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 22.563889,
    longitude: 113.862222,
    description: "欢乐港湾是深圳西部的滨海文化旅游新地标，集主题乐园、文化演艺、购物餐饮于一体。这里拥有全球最大的海上摩天轮，以及精彩的水幕灯光秀表演。",
    opening_hours: "10:00-22:00",
    phone: "0755-88888888",
    rating: 4.5,
    review_count: 1258,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳世界之窗",
    slug: "shenzhen-window-of-the-world",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区华侨城深南大道9037号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 22.537,
    longitude: 113.974,
    description: "汇集世界各地名胜古迹的微缩景观，一天游遍全球。含埃菲尔铁塔、金字塔、泰姬陵等130多个世界著名景点的缩影。",
    opening_hours: "09:00-22:30",
    phone: "0755-26608000",
    rating: 4.4,
    review_count: 3528,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳欢乐谷",
    slug: "shenzhen-happy-valley",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区侨城西路18号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 22.540,
    longitude: 113.980,
    description: "中国最佳主题乐园之一，拥有100多个游乐项目。含九大主题区，如西班牙广场、卡通城、冒险山、金矿镇等，适合全家游玩。",
    opening_hours: "09:30-21:00",
    phone: "0755-26949184",
    rating: 4.6,
    review_count: 4856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳东部华侨城",
    slug: "shenzhen-oct-east",
    city: "深圳",
    district: "盐田区",
    address: "深圳市盐田区大梅沙东部华侨城",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 22.596,
    longitude: 114.306,
    description: "集休闲度假、观光旅游、户外运动等于一体的大型综合性旅游度假区。含大侠谷、茶溪谷两大主题公园，还有云海谷高尔夫球场。",
    opening_hours: "09:30-17:30",
    phone: "0755-88889888",
    rating: 4.5,
    review_count: 2156,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳野生动物园",
    slug: "shenzhen-safari-park",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区西丽湖路4065号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 22.595,
    longitude: 113.949,
    description: "中国第一家放养式野生动物园，拥有300多种、近万只野生动物。可近距离观看狮子、老虎、长颈鹿等动物，还有精彩的动物表演。",
    opening_hours: "09:30-18:00",
    phone: "0755-26622892",
    rating: 4.3,
    review_count: 3256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳锦绣中华民俗村",
    slug: "shenzhen-splendid-china",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区深南大道9003号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 22.537,
    longitude: 113.968,
    description: "展示中国传统文化和民族风情的主题公园。82个中国各地景区的缩影，以及56个民族的民俗文化表演，是了解中国文化的绝佳窗口。",
    opening_hours: "10:00-21:00",
    phone: "0755-26605626",
    rating: 4.2,
    review_count: 2856,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳海上世界",
    slug: "shenzhen-sea-world",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区蛇口望海路1128号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 22.487,
    longitude: 113.909,
    description: "以明华轮邮轮为中心的滨海文化旅游区，集购物、餐饮、娱乐为一体。夜景优美，是深圳年轻人休闲聚会的热门地点。",
    opening_hours: "全天开放",
    phone: "0755-26851777",
    rating: 4.4,
    review_count: 1958,
    is_free: true,  # 免费景点
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "深圳大梅沙海滨公园",
    slug: "shenzhen-dameisha-beach",
    city: "深圳",
    district: "盐田区",
    address: "深圳市盐田区大梅沙盐梅路9号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 22.592,
    longitude: 114.315,
    description: "深圳最长的海滩，免费开放的公共海滨浴场。金色沙滩、碧蓝海水，是夏日消暑的好去处，也是观赏日出的绝佳地点。",
    opening_hours: "全天开放",
    phone: "0755-25036051",
    rating: 4.1,
    review_count: 4256,
    is_free: true,  # 免费景点
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },

  # ========== 上海景点 (7个) ==========
  {
    name: "上海迪士尼乐园",
    slug: "shanghai-disney",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区川沙新镇上海迪士尼度假区",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 31.145,
    longitude: 121.666,
    description: "中国大陆首座迪士尼主题乐园，拥有七大主题园区，包括米奇大街、奇想花园、梦幻世界、探险岛、宝藏湾、明日世界和迪士尼·皮克斯玩具总动员主题园区，适合全家游玩。",
    opening_hours: "09:00-21:00",
    phone: "021-31580000",
    rating: 4.7,
    review_count: 8520,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海海昌海洋公园",
    slug: "shanghai-haichang-ocean-park",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区南汇新城银飞路166号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 31.016,
    longitude: 121.921,
    description: "大型海洋主题公园，拥有五大主题区和十余项游乐设施。可观赏白鲸、海豚、企鹅等海洋动物，还有精彩的海洋动物表演。",
    opening_hours: "09:00-17:30",
    phone: "021-61674888",
    rating: 4.5,
    review_count: 3256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海欢乐谷",
    slug: "shanghai-happy-valley",
    city: "上海",
    district: "松江区",
    address: "上海市松江区林湖路888号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 31.069,
    longitude: 121.174,
    description: "华东地区最大的主题乐园之一，拥有100多个游乐项目。七大主题区域包括阳光港、欢乐时光、上海滩等，刺激与欢乐并存。",
    opening_hours: "10:00-18:00",
    phone: "021-33552222",
    rating: 4.4,
    review_count: 4156,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海野生动物园",
    slug: "shanghai-wild-animal-park",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区南六公路178号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 31.052,
    longitude: 121.703,
    description: "国家5A级景区，中国首座国家级野生动物园。拥有200余种、上万只动物，可乘车游览猛兽区，近距离观看狮虎熊豹等动物。",
    opening_hours: "08:30-17:00",
    phone: "021-58036000",
    rating: 4.5,
    review_count: 5256,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海东方明珠广播电视塔",
    slug: "shanghai-oriental-pearl-tower",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区世纪大道1号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 31.240,
    longitude: 121.501,
    description: "上海的标志性建筑，高468米。塔内有观光层、旋转餐厅、上海历史博物馆等。在观光层可360度俯瞰上海全景，是游客必打卡的地标。",
    opening_hours: "08:00-21:30",
    phone: "021-58791888",
    rating: 4.6,
    review_count: 12580,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海科技馆",
    slug: "shanghai-science-and-technology-museum",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区世纪大道2000号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 31.222,
    longitude: 121.547,
    description: "中国首个国家级科技馆，拥有生物万象、地壳探秘、机器人世界等13个主题展区。互动性强，寓教于乐，是亲子游的理想选择。",
    opening_hours: "09:00-17:15（周一闭馆）",
    phone: "021-68622000",
    rating: 4.7,
    review_count: 8560,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "上海外滩",
    slug: "shanghai-the-bund",
    city: "上海",
    district: "黄浦区",
    address: "上海市黄浦区中山东一路",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 31.239,
    longitude: 121.491,
    description: "上海的城市象征，位于黄浦江西岸。这里保留着52幢风格迥异的古典复兴建筑，是观赏浦江两岸摩登都市风光的最佳地点。",
    opening_hours: "全天开放",
    phone: "021-63232570",
    rating: 4.8,
    review_count: 15680,
    is_free: true,  # 免费景点
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "北京欢乐谷",
    slug: "beijing-happy-valley",
    city: "北京",
    district: "朝阳区",
    address: "北京市朝阳区东四环小武基北路",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 39.867,
    longitude: 116.485,
    description: "大型现代主题公园，拥有多个主题区域和大型游乐设施。包括过山车、激流勇进等热门项目，适合家庭和年轻人游玩。",
    opening_hours: "10:00-18:00（周末延长至20:00）",
    phone: "010-67389898",
    rating: 4.6,
    review_count: 12560,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "成都欢乐谷",
    slug: "chengdu-happy-valley",
    city: "成都",
    district: "金牛区",
    address: "四川省成都市金牛区西华大道16号",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 30.720,
    longitude: 104.014,
    description: "西南地区大型主题乐园，拥有9大主题区域和100多个游乐项目。特色夜场开放至22:00，夜间灯光秀璀璨夺目，是年轻人夜生活的热门选择。",
    opening_hours: "09:30-22:00（夜场18:00-22:00）",
    phone: "028-89338000",
    rating: 4.6,
    review_count: 14560,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "广州长隆野生动物世界",
    slug: "guangzhou-chimelong-safari-park",
    city: "广州",
    district: "番禺区",
    address: "广州市番禺区大石东路长隆旅游度假区内",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 23.003,
    longitude: 113.294,
    description: "大型野生动物园，以大规模野生动物种群放养和自驾车观赏为特色。拥有世界珍稀动物种群，是亚洲最大的野生动物公园。",
    opening_hours: "09:30-18:00",
    phone: "020-84783333",
    rating: 4.8,
    review_count: 25680,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },

  # ========== 张家界景区 (V318需要) ==========
  {
    name: "张家界国家森林公园",
    slug: "zhangjiajie-national-forest-park",
    city: "张家界",
    district: "武陵源区",
    address: "湖南省张家界市武陵源区金鞭路",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 29.3255,
    longitude: 110.4442,
    description: "中国第一个国家森林公园，世界自然遗产。以独特的刃山石峰、峡谷溪流、岩溶洞穴、珍稀动植物著称。代表景点有金鞭溪、袖子溪、天子山等。",
    opening_hours: "07:00-18:00",
    phone: "0744-5712189",
    rating: 4.7,
    review_count: 18560,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },

  # ========== 三亚景区 (V308需要：潜水活动, V319需要：亲子活动) ==========
  {
    name: "蜈支洲岛",
    slug: "wuzhizhou-island",
    city: "三亚",
    district: "海棠区",
    address: "海南省三亚市海棠湾镇蜈支洲岛",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 18.3116,
    longitude: 109.7633,
    description: "中国首屈一指的潜水胜地，水质清澈，海洋生物丰富。享有\"中国马尔代夫\"美誉。提供多种潜水教学、水上运动和水下摄影服务。",
    opening_hours: "08:00-17:30",
    phone: "0898-88751258",
    rating: 4.7,
    review_count: 18560,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "三亚亚龙湾热带天堂森林公园",
    slug: "sanya-yalong-bay-tropical-paradise",
    city: "三亚",
    district: "吉阳区",
    address: "海南省三亚市亚龙湾国家旅游度假区",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 18.2469,
    longitude: 109.6576,
    description: "亚龙湾热带天堂森林公园集山海于一体，可俘瞰亚龙湾全景。拥有热带雨林、空中缆车、亲子探险项目。是亲子游的热门选择。",
    opening_hours: "08:00-18:00",
    phone: "0898-38250000",
    rating: 4.6,
    review_count: 12560,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },

  # ========== 崇礼滑雪场 (V320需要：寒假滑雪) ==========
  {
    name: "崇礼万龙滑雪场",
    slug: "chongli-wanlong-ski-resort",
    city: "张家口",
    district: "崇礼区",
    address: "河北省张家口市崇礼区红花梁",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 40.9773,
    longitude: 115.3833,
    description: "中国首家开放的滑雪场，2022年冬奥会雪上项目比赛场地。拥有3200米雪道，适合各级别滑雪者。提供滑雪装备租赁和教学服务。",
    opening_hours: "08:30-16:30",
    phone: "0313-4785599",
    rating: 4.8,
    review_count: 15680,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },

  # ========== 新疆薰衣草景区 (V327需要：花期限定游) ==========
  {
    name: "普罗旺斯风格薰衣草园",
    slug: "provence-style-lavender-garden",
    city: "伊犁",
    district: "霍城县",
    address: "新疆伊犁哈萨克自治州霍城县大西渠乡",
    cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
    latitude: 44.0542,
    longitude: 81.1667,
    description: "中国薰衣草之乡，6月花期时紫色花海壮观。提供花海摄影、薰衣草产品制作体验、田园采风等活动。是摄影爱好者的天堂。",
    opening_hours: "09:00-20:00 (花期6-7月)",
    phone: "0999-3028888",
    rating: 4.7,
    review_count: 9560,
    is_free: false,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

# 批量插入景点数据
Attraction.insert_all(attractions_data)

# 为新插入的 Attraction 生成 slug（FriendlyId 需要 save 触发回调）
puts "     正在为景点生成 slug..."
Attraction.where(data_version: '0', slug: [nil, '']).find_each(&:save)

puts "✓ 创建了 #{attractions_data.size} 个景点"

# ==================== 获取景点 ID ====================
attractions = Attraction.all.index_by(&:name)

# ==================== 门票数据 ====================
# 注意：Ticket 模型没有 image_url 字段，无需迁移图片

tickets_data = []

# 深圳欢乐港湾门票
attraction = attractions["深圳欢乐港湾"]
tickets_data << {
  attraction_id: attraction.id,
  name: "深圳欢乐港湾成人票",
  ticket_type: "adult",
  current_price: 90,
  original_price: 120,
  requirements: "含园区所有游乐设施，不含餐饮和单独收费项目。",
  sales_count: 2580,
  validity_days: 90,
  booking_notice: "游玩当天16:00前可预订，预订成功后2小时生效",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "深圳欢乐港湾儿童票",
  ticket_type: "child",
  current_price: 45,
  original_price: 60,
  requirements: "适用于1.2米-1.5米儿童。含园区所有游乐设施，不含餐饮和单独收费项目。",
  sales_count: 1520,
  validity_days: 90,
  booking_notice: "游玩当天16:00前可预订，预订成功后2小时生效",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 深圳世界之窗门票
attraction = attractions["深圳世界之窗"]
tickets_data << {
  attraction_id: attraction.id,
  name: "深圳世界之窗成人票",
  ticket_type: "adult",
  current_price: 180,
  original_price: 220,
  requirements: "含园区所有景点和常规演出，不含收费项目和餐饮。",
  sales_count: 8560,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "深圳世界之窗儿童票",
  ticket_type: "child",
  current_price: 90,
  original_price: 110,
  requirements: "适用于1.2米-1.5米儿童。含园区所有景点和常规演出。",
  sales_count: 4280,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 深圳欢乐谷门票
attraction = attractions["深圳欢乐谷"]
tickets_data << {
  attraction_id: attraction.id,
  name: "深圳欢乐谷成人票",
  ticket_type: "adult",
  current_price: 200,
  original_price: 230,
  requirements: "含园区所有游乐项目，不含收费项目和餐饮。",
  sales_count: 12560,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "深圳欢乐谷儿童票",
  ticket_type: "child",
  current_price: 100,
  original_price: 115,
  requirements: "适用于1.2米-1.5米儿童。含园区所有适龄游乐项目。",
  sales_count: 6280,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 深圳东部华侨城门票
attraction = attractions["深圳东部华侨城"]
tickets_data << {
  attraction_id: attraction.id,
  name: "深圳东部华侨城大侠谷成人票",
  ticket_type: "adult",
  current_price: 180,
  original_price: 200,
  requirements: "含大侠谷所有游乐项目和演出，不含茶溪谷。",
  sales_count: 5680,
  validity_days: 90,
  booking_notice: "需提前1天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "深圳东部华侨城茶溪谷成人票",
  ticket_type: "adult",
  current_price: 140,
  original_price: 160,
  requirements: "含茶溪谷所有景点和表演，不含大侠谷。",
  sales_count: 4280,
  validity_days: 90,
  booking_notice: "需提前1天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 深圳野生动物园门票
attraction = attractions["深圳野生动物园"]
tickets_data << {
  attraction_id: attraction.id,
  name: "深圳野生动物园成人票",
  ticket_type: "adult",
  current_price: 220,
  original_price: 240,
  requirements: "含园区所有展馆和动物表演，含观光车。",
  sales_count: 9560,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "深圳野生动物园儿童票",
  ticket_type: "child",
  current_price: 110,
  original_price: 120,
  requirements: "适用于1.2米-1.5米儿童。含园区所有展馆和动物表演。",
  sales_count: 5280,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 深圳锦绣中华民俗村门票
attraction = attractions["深圳锦绣中华民俗村"]
tickets_data << {
  attraction_id: attraction.id,
  name: "深圳锦绣中华民俗村成人票",
  ticket_type: "adult",
  current_price: 160,
  original_price: 180,
  requirements: "含锦绣中华和民俗村两个园区，含所有演出。",
  sales_count: 7560,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "深圳锦绣中华民俗村儿童票",
  ticket_type: "child",
  current_price: 80,
  original_price: 90,
  requirements: "适用于1.2米-1.5米儿童。含两个园区和所有演出。",
  sales_count: 3280,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 北京欢乐谷门票
attraction = attractions["北京欢乐谷"]
tickets_data << {
  attraction_id: attraction.id,
  name: "北京欢乐谷成人票",
  ticket_type: "adult",
  current_price: 260,
  original_price: 299,
  requirements: "含园区所有游乐项目，不含收费项目和餐饮。",
  sales_count: 15680,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "北京欢乐谷儿童票",
  ticket_type: "child",
  current_price: 130,
  original_price: 149,
  requirements: "适用于1.2米-1.5米儿童。含园区所有适龄游乐项目。",
  sales_count: 8560,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 成都欢乐谷门票
attraction = attractions["成都欢乐谷"]
tickets_data << {
  attraction_id: attraction.id,
  name: "成都欢乐谷夜场票（成人票）",
  ticket_type: "adult",
  current_price: 120,
  original_price: 150,
  requirements: "夜场专用票，18:00-22:00入园。含园区所有夜间开放游乐项目和灯光秀演出，不含餐饮。",
  sales_count: 8560,
  validity_days: 90,
  booking_notice: "当天17:00前可预订，夜场18:00开始入园",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "成都欢乐谷成人票",
  ticket_type: "adult",
  current_price: 220,
  original_price: 260,
  requirements: "含园区所有游乐项目，不含收费项目和餐饮。",
  sales_count: 13560,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "成都欢乐谷儿童票",
  ticket_type: "child",
  current_price: 110,
  original_price: 130,
  requirements: "适用于1.2米-1.5米儿童。含园区所有适龄游乐项目。",
  sales_count: 7560,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 广州长隆野生动物世界门票
attraction = attractions["广州长隆野生动物世界"]
tickets_data << {
  attraction_id: attraction.id,
  name: "广州长隆野生动物世界成人票",
  ticket_type: "adult",
  current_price: 300,
  original_price: 350,
  requirements: "含园区所有展馆、动物表演和乘车游览，不含餐饮。",
  sales_count: 22560,
  validity_days: 90,
  booking_notice: "需提前1天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "广州长隆野生动物世界儿童票",
  ticket_type: "child",
  current_price: 210,
  original_price: 245,
  requirements: "适用于1.0米-1.5米儿童。含园区所有展馆、动物表演和乘车游览。",
  sales_count: 11280,
  validity_days: 90,
  booking_notice: "需提前1天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "广州长隆野生动物世界学生票",
  ticket_type: "student",
  current_price: 240,
  original_price: 280,
  requirements: "适用于全日制大学本科及以下学历学生（凭学生证）。含园区所有项目。",
  sales_count: 6280,
  validity_days: 90,
  booking_notice: "需提前1天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海迪士尼乐园门票
attraction = attractions["上海迪士尼乐园"]
tickets_data << {
  attraction_id: attraction.id,
  name: "上海迪士尼乐园1日票（平日）",
  ticket_type: "adult",
  current_price: 435,
  original_price: 475,
  requirements: "平日通用，含园区所有游乐设施和娱乐演出，不含餐饮。",
  sales_count: 28560,
  validity_days: 180,
  booking_notice: "需提前1天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "上海迪士尼乐园1日票（周末）",
  ticket_type: "adult",
  current_price: 575,
  original_price: 619,
  requirements: "周末通用，含园区所有游乐设施和娱乐演出，不含餐饮。",
  sales_count: 18560,
  validity_days: 180,
  booking_notice: "需提前1天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "上海迪士尼乐园2日联票",
  ticket_type: "adult",
  current_price: 785,
  original_price: 850,
  requirements: "两日内任选2天游玩，含园区所有游乐设施和娱乐演出。",
  sales_count: 12560,
  validity_days: 180,
  booking_notice: "需提前3天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "上海迪士尼乐园1日票（平日）儿童票",
  ticket_type: "child",
  current_price: 325,
  original_price: 356,
  requirements: "适用于1.0米-1.4米儿童。平日通用，含园区所有游乐设施和娱乐演出，不含餐饮。",
  sales_count: 15280,
  validity_days: 180,
  booking_notice: "需提前1天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "上海迪士尼乐园1日票（周末）儿童票",
  ticket_type: "child",
  current_price: 431,
  original_price: 464,
  requirements: "适用于1.0米-1.4米儿童。周末通用，含园区所有游乐设施和娱乐演出，不含餐饮。",
  sales_count: 9280,
  validity_days: 180,
  booking_notice: "需提前1天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海海昌海洋公园门票
attraction = attractions["上海海昌海洋公园"]
tickets_data << {
  attraction_id: attraction.id,
  name: "上海海昌海洋公园成人票",
  ticket_type: "adult",
  current_price: 260,
  original_price: 299,
  requirements: "含园区所有展馆、游乐项目和动物表演，不含餐饮。",
  sales_count: 9560,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "上海海昌海洋公园儿童票",
  ticket_type: "child",
  current_price: 180,
  original_price: 209,
  requirements: "适用于1.0米-1.4米儿童。含园区所有展馆、游乐项目和表演。",
  sales_count: 5280,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海欢乐谷门票
attraction = attractions["上海欢乐谷"]
tickets_data << {
  attraction_id: attraction.id,
  name: "上海欢乐谷成人票",
  ticket_type: "adult",
  current_price: 230,
  original_price: 260,
  requirements: "含园区所有游乐项目和演出，不含收费项目和餐饮。",
  sales_count: 11560,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "上海欢乐谷儿童票",
  ticket_type: "child",
  current_price: 115,
  original_price: 130,
  requirements: "适用于1.2米-1.5米儿童。含园区所有适龄游乐项目和演出。",
  sales_count: 6280,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海野生动物园门票
attraction = attractions["上海野生动物园"]
tickets_data << {
  attraction_id: attraction.id,
  name: "上海野生动物园成人票",
  ticket_type: "adult",
  current_price: 110,
  original_price: 130,
  requirements: "含园区所有展馆和动物表演，含观光车。",
  sales_count: 15560,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "上海野生动物园儿童票",
  ticket_type: "child",
  current_price: 55,
  original_price: 65,
  requirements: "适用于1.3米以下儿童。含园区所有展馆和动物表演。",
  sales_count: 8280,
  validity_days: 90,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海东方明珠门票
attraction = attractions["上海东方明珠广播电视塔"]
tickets_data << {
  attraction_id: attraction.id,
  name: "上海东方明珠观光层门票",
  ticket_type: "adult",
  current_price: 160,
  original_price: 180,
  requirements: "含第一球观光层（263米）、第二球观光层（259米）、全透明观光廊（259米）。",
  sales_count: 25680,
  validity_days: 30,
  booking_notice: "游玩当天16:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "上海东方明珠全景门票",
  ticket_type: "adult",
  current_price: 220,
  original_price: 250,
  requirements: "含三个观光层（351米太空舱、263米第一球、259米第二球）、全透明观光廊、上海历史陈列馆。",
  sales_count: 18560,
  validity_days: 30,
  booking_notice: "游玩当天16:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海科技馆门票
attraction = attractions["上海科技馆"]
tickets_data << {
  attraction_id: attraction.id,
  name: "上海科技馆成人票",
  ticket_type: "adult",
  current_price: 45,
  original_price: 60,
  requirements: "含常设展厅（生物万象、地壳探秘、设计师摇篮等13个主题展区）。",
  sales_count: 22560,
  validity_days: 30,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "上海科技馆学生票",
  ticket_type: "student",
  current_price: 20,
  original_price: 30,
  requirements: "适用于全日制大学本科及以下学历学生（凭学生证）。含常设展厅。",
  sales_count: 12560,
  validity_days: 30,
  booking_notice: "游玩当天15:00前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 张家界国家森林公园门票 (V318需要)
attraction = attractions["张家界国家森林公园"]
tickets_data << {
  attraction_id: attraction.id,
  name: "张家界国家森林公园成人票",
  ticket_type: "adult",
  current_price: 225,
  original_price: 248,
  requirements: "含园区所有景点和观光车，不含索道、天门山手扶电梯等单独收费项目。",
  sales_count: 28560,
  validity_days: 90,
  booking_notice: "需提前1天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "张家界国家森林公园儿童票",
  ticket_type: "child",
  current_price: 118,
  original_price: 124,
  requirements: "适用于1.2米-1.5米儿童。含园区所有景点和观光车。",
  sales_count: 15680,
  validity_days: 90,
  booking_notice: "需提前1天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 三亚亚龙湾热带天堂森林公园门票 (V319需要：亲子活动)
attraction = attractions["三亚亚龙湾热带天堂森林公园"]
tickets_data << {
  attraction_id: attraction.id,
  name: "三亚亚龙湾热带天堂森林公园成人票",
  ticket_type: "adult",
  current_price: 165,
  original_price: 198,
  requirements: "含园区所有景点、空中缆车和亲子探险项目。",
  sales_count: 18560,
  validity_days: 90,
  booking_notice: "游玩当天1天前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "三亚亚龙湾热带天堂森林公园儿童票",
  ticket_type: "child",
  current_price: 108,
  original_price: 128,
  requirements: "适用于1.2米-1.5米儿童。含园区所有景点和亲子项目。",
  sales_count: 12680,
  validity_days: 90,
  booking_notice: "游玩当天1天前可预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 崇礼万龙滑雪场门票 (V320需要：寒假滑雪)
attraction = attractions["崇礼万龙滑雪场"]
tickets_data << {
  attraction_id: attraction.id,
  name: "崇礼万龙滑雪场全天票",
  ticket_type: "adult",
  current_price: 580,
  original_price: 650,
  requirements: "含雪场门票、雪道缆车。不含滑雪装备租赁（可单独购买）。",
  sales_count: 8560,
  validity_days: 30,
  booking_notice: "需提前1天预订，仅雪季（12月-3月）有效",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "崇礼万龙滑雪场半天票",
  ticket_type: "adult",
  current_price: 380,
  original_price: 420,
  requirements: "半天场（4小时），含雪场门票和缆车。不含装备租赁。",
  sales_count: 12560,
  validity_days: 30,
  booking_notice: "需提前1天预订，仅雪季有效",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 普罗旺斯风格薰衣草园门票 (V327需要：花期限定游)
attraction = attractions["普罗旺斯风格薰衣草园"]
tickets_data << {
  attraction_id: attraction.id,
  name: "普罗旺斯风格薰衣草园门票",
  ticket_type: "adult",
  current_price: 68,
  original_price: 88,
  requirements: "含薰衣草花海参观、摄影区域，不含体验活动。仅花期（6月-7月）有效。",
  sales_count: 5680,
  validity_days: 60,
  booking_notice: "花期预订，需提前3天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

tickets_data << {
  attraction_id: attraction.id,
  name: "普罗旺斯风格薰衣草园体验套票",
  ticket_type: "adult",
  current_price: 128,
  original_price: 168,
  requirements: "含门票+薰衣草产品制作体验（手工香袋或精油）。仅花期有效。",
  sales_count: 3280,
  validity_days: 60,
  booking_notice: "花期预订，需提前3天预订",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 批量插入门票数据
Ticket.insert_all(tickets_data)

puts "✓ 创建了 #{tickets_data.size} 张门票"

# ==================== 供应商数据 ====================

suppliers_data = [
  {
    name: "携程旅行",
    supplier_type: "platform",
    rating: 4.8,
    sales_count: 158000,
    description: "国内领先的在线旅游平台，提供门票、酒店、机票等服务",
    contact_phone: "10106666",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "飞猪旅行",
    supplier_type: "platform",
    rating: 4.7,
    sales_count: 126000,
    description: "阿里巴巴旗下综合性旅游出行服务平台",
    contact_phone: "10101688",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "美团门票",
    supplier_type: "platform",
    rating: 4.6,
    sales_count: 98000,
    description: "美团旗下景区门票预订平台，覆盖全国景点",
    contact_phone: "10109777",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "景区官方",
    supplier_type: "official",
    rating: 4.9,
    sales_count: 85000,
    description: "景区官方直销渠道",
    contact_phone: "400-000-0000",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

Supplier.insert_all(suppliers_data)

puts "✓ 创建了 #{suppliers_data.size} 个供应商"

# 重新加载供应商以获取 ID
suppliers = {}
Supplier.where(data_version: 0).each do |supplier|
  suppliers[supplier.name] = supplier
end

# 重新加载门票以获取 ID
tickets = {}
Ticket.where(data_version: 0).includes(:attraction).each do |ticket|
  key = "#{ticket.attraction.name}_#{ticket.name}"
  tickets[key] = ticket
end

# ==================== 门票供应商关联数据 ====================

ticket_suppliers_data = []

# 深圳欢乐港湾成人票 - 4个供应商
ticket = tickets["深圳欢乐港湾_深圳欢乐港湾成人票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 85,
  original_price: 120,
  stock: 500,
  discount_info: "早鸟优惠",
  sales_count: 2580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 88,
  original_price: 120,
  stock: 300,
  discount_info: "限时特惠",
  sales_count: 1850,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["美团门票"].id,
  current_price: 90,
  original_price: 120,
  stock: 400,
  discount_info: "满减优惠",
  sales_count: 1560,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 95,
  original_price: 120,
  stock: -1,
  discount_info: nil,
  sales_count: 980,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 深圳欢乐港湾儿童票 - 4个供应商
ticket = tickets["深圳欢乐港湾_深圳欢乐港湾儿童票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 42,
  original_price: 60,
  stock: 500,
  discount_info: "儿童特惠",
  sales_count: 1520,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 45,
  original_price: 60,
  stock: 300,
  discount_info: nil,
  sales_count: 980,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["美团门票"].id,
  current_price: 43,
  original_price: 60,
  stock: 400,
  discount_info: nil,
  sales_count: 850,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 48,
  original_price: 60,
  stock: -1,
  discount_info: nil,
  sales_count: 560,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海迪士尼乐园1日票（平日）- 3个供应商
ticket = tickets["上海迪士尼乐园_上海迪士尼乐园1日票（平日）"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 435,
  original_price: 475,
  stock: 1000,
  discount_info: "官方授权",
  sales_count: 15600,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 438,
  original_price: 475,
  stock: 800,
  discount_info: nil,
  sales_count: 8960,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 445,
  original_price: 475,
  stock: -1,
  discount_info: nil,
  sales_count: 4000,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海迪士尼乐园1日票（周末）- 3个供应商
ticket = tickets["上海迪士尼乐园_上海迪士尼乐园1日票（周末）"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 570,
  original_price: 619,
  stock: 800,
  discount_info: nil,
  sales_count: 10200,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 575,
  original_price: 619,
  stock: 600,
  discount_info: nil,
  sales_count: 5680,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 585,
  original_price: 619,
  stock: -1,
  discount_info: nil,
  sales_count: 2680,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海迪士尼乐园儿童票（平日）- 3个供应商
ticket = tickets["上海迪士尼乐园_上海迪士尼乐园1日票（平日）儿童票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 315,
  original_price: 356,
  stock: 300,
  discount_info: "儿童票优惠",
  sales_count: 2580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 325,
  original_price: 356,
  stock: 200,
  discount_info: nil,
  sales_count: 1580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 356,
  original_price: 356,
  stock: 400,
  discount_info: nil,
  sales_count: 3280,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海迪士尼乐园儿童票（周末）- 3个供应商
ticket = tickets["上海迪士尼乐园_上海迪士尼乐园1日票（周末）儿童票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 420,
  original_price: 464,
  stock: 200,
  discount_info: "周末儿童票",
  sales_count: 1580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 431,
  original_price: 464,
  stock: 150,
  discount_info: nil,
  sales_count: 980,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 464,
  original_price: 464,
  stock: 300,
  discount_info: nil,
  sales_count: 2280,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 深圳欢乐谷成人票 - 4个供应商
ticket = tickets["深圳欢乐谷_深圳欢乐谷成人票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 185,
  original_price: 230,
  stock: 500,
  discount_info: "早鸟优惠",
  sales_count: 3580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 190,
  original_price: 230,
  stock: 400,
  discount_info: nil,
  sales_count: 2580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["美团门票"].id,
  current_price: 195,
  original_price: 230,
  stock: 350,
  discount_info: nil,
  sales_count: 1980,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 200,
  original_price: 230,
  stock: 600,
  discount_info: nil,
  sales_count: 4280,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 深圳欢乐谷儿童票 - 4个供应商
ticket = tickets["深圳欢乐谷_深圳欢乐谷儿童票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 92,
  original_price: 115,
  stock: 300,
  discount_info: "儿童票优惠",
  sales_count: 1580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 95,
  original_price: 115,
  stock: 250,
  discount_info: nil,
  sales_count: 980,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["美团门票"].id,
  current_price: 98,
  original_price: 115,
  stock: 200,
  discount_info: nil,
  sales_count: 780,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 100,
  original_price: 115,
  stock: 400,
  discount_info: nil,
  sales_count: 2280,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 北京欢乐谷成人票 - 4个供应商
ticket = tickets["北京欢乐谷_北京欢乐谷成人票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 245,
  original_price: 299,
  stock: 600,
  discount_info: "早鸟优惠",
  sales_count: 4580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 250,
  original_price: 299,
  stock: 500,
  discount_info: nil,
  sales_count: 3580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["美团门票"].id,
  current_price: 255,
  original_price: 299,
  stock: 450,
  discount_info: nil,
  sales_count: 2580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 260,
  original_price: 299,
  stock: 700,
  discount_info: nil,
  sales_count: 5280,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 北京欢乐谷儿童票 - 4个供应商
ticket = tickets["北京欢乐谷_北京欢乐谷儿童票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 120,
  original_price: 149,
  stock: 400,
  discount_info: "儿童票优惠",
  sales_count: 2280,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 125,
  original_price: 149,
  stock: 350,
  discount_info: nil,
  sales_count: 1580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["美团门票"].id,
  current_price: 128,
  original_price: 149,
  stock: 300,
  discount_info: nil,
  sales_count: 980,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 130,
  original_price: 149,
  stock: 500,
  discount_info: nil,
  sales_count: 3280,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 成都欢乐谷夜场票（成人票） - 4个供应商
ticket = tickets["成都欢乐谷_成都欢乐谷夜场票（成人票）"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 115,
  original_price: 150,
  stock: 400,
  discount_info: "夜场特惠",
  sales_count: 2580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["美团门票"].id,
  current_price: 108,
  original_price: 150,
  stock: 350,
  discount_info: "新用户立减42元",
  sales_count: 1980,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 112,
  original_price: 150,
  stock: 300,
  discount_info: nil,
  sales_count: 1580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 120,
  original_price: 150,
  stock: 500,
  discount_info: nil,
  sales_count: 2280,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 广州长隆野生动物世界成人票 - 4个供应商
ticket = tickets["广州长隆野生动物世界_广州长隆野生动物世界成人票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 285,
  original_price: 350,
  stock: 800,
  discount_info: "早鸟优惠",
  sales_count: 6580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 290,
  original_price: 350,
  stock: 700,
  discount_info: nil,
  sales_count: 5580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["美团门票"].id,
  current_price: 295,
  original_price: 350,
  stock: 650,
  discount_info: nil,
  sales_count: 4580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 300,
  original_price: 350,
  stock: 900,
  discount_info: nil,
  sales_count: 5880,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 广州长隆野生动物世界儿童票 - 3个供应商
ticket = tickets["广州长隆野生动物世界_广州长隆野生动物世界儿童票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 200,
  original_price: 245,
  stock: 500,
  discount_info: "儿童票优惠",
  sales_count: 3280,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 205,
  original_price: 245,
  stock: 450,
  discount_info: nil,
  sales_count: 2580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 210,
  original_price: 245,
  stock: 600,
  discount_info: nil,
  sales_count: 4280,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 广州长隆野生动物世界学生票 - 3个供应商
ticket = tickets["广州长隆野生动物世界_广州长隆野生动物世界学生票"]
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["携程旅行"].id,
  current_price: 230,
  original_price: 280,
  stock: 400,
  discount_info: "学生特惠",
  sales_count: 1580,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["飞猪旅行"].id,
  current_price: 235,
  original_price: 280,
  stock: 350,
  discount_info: nil,
  sales_count: 980,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}
ticket_suppliers_data << {
  ticket_id: ticket.id,
  supplier_id: suppliers["景区官方"].id,
  current_price: 240,
  original_price: 280,
  stock: 500,
  discount_info: nil,
  sales_count: 2280,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 为其他所有门票添加供应商（已有供应商的跳过）
tickets.each do |key, ticket|
  # 跳过已有供应商的门票（广州长隆、成都欢乐谷夜场票）
  next if key.start_with?('广州长隆野生动物世界')
  next if key == '成都欢乐谷_成都欢乐谷夜场票（成人票）'
  
  # 为每张门票添加3个供应商：携程、飞猪、景区官方
  base_price = ticket.current_price
  original_price = ticket.original_price
  
  # 供应商1：携程旅行（价格与门票current_price一致）
  ticket_suppliers_data << {
    ticket_id: ticket.id,
    supplier_id: suppliers["携程旅行"].id,
    current_price: base_price,
    original_price: original_price,
    stock: 500,
    discount_info: base_price < original_price ? "线上预订立减#{(original_price - base_price).to_i}元" : nil,
    sales_count: (ticket.sales_count * 0.4).to_i,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 供应商2：飞猪旅行（价格更低5元）
  ticket_suppliers_data << {
    ticket_id: ticket.id,
    supplier_id: suppliers["飞猪旅行"].id,
    current_price: base_price - 5,
    original_price: original_price,
    stock: 600,
    discount_info: "新用户立减#{(original_price - base_price + 5).to_i}元",
    sales_count: (ticket.sales_count * 0.3).to_i,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 供应商3：景区官方（原价）
  ticket_suppliers_data << {
    ticket_id: ticket.id,
    supplier_id: suppliers["景区官方"].id,
    current_price: original_price,
    original_price: original_price,
    stock: 1000,
    discount_info: nil,
    sales_count: (ticket.sales_count * 0.3).to_i,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
end

TicketSupplier.insert_all(ticket_suppliers_data) if ticket_suppliers_data.any?

puts "✓ 创建了 #{ticket_suppliers_data.size} 个门票供应商关联"

# ==================== 景点内项目数据 ====================
# 注意：AttractionActivity 模型没有 image_url 字段，无需迁移图片

attraction_activities_data = []

# 深圳东部华侨城景点内项目
attraction = attractions["深圳东部华侨城"]
attraction_activities_data << {
  attraction_id: attraction.id,
  name: "云中部落观光缆车",
  activity_type: "交通工具",
  current_price: 35,
  description: "索道全长约1600米，从大侠谷至云中部落，欣赏沿途美景。",
  duration: "15分钟单程",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

attraction_activities_data << {
  attraction_id: attraction.id,
  name: "云海谷高尔夫球场",
  activity_type: "运动体验",
  current_price: 580,
  description: "27洞山地高尔夫球场，含球杆租赁和教练指导。",
  duration: "4-5小时",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海海昌海洋公园景点内项目
attraction = attractions["上海海昌海洋公园"]
attraction_activities_data << {
  attraction_id: attraction.id,
  name: "VR深海奇妙夜",
  activity_type: "互动体验",
  current_price: 80,
  description: "佩戴VR设备，沉浸式体验深海世界，与海洋生物互动。",
  duration: "20分钟",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

attraction_activities_data << {
  attraction_id: attraction.id,
  name: "海豚互动体验",
  activity_type: "动物互动",
  current_price: 380,
  description: "在专业驯养师指导下，近距离接触海豚，喂食、抚摸、合影。限4-12岁儿童。",
  duration: "30分钟",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海迪士尼乐园景点内项目
attraction = attractions["上海迪士尼乐园"]
attraction_activities_data << {
  attraction_id: attraction.id,
  name: "米奇童话专列巡游",
  activity_type: "娱乐演出",
  current_price: 0,  # 免费，含在门票内
  description: "迪士尼经典花车巡游，米奇、米妮、唐老鸭等经典角色登场。",
  duration: "30分钟",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

attraction_activities_data << {
  attraction_id: attraction.id,
  name: "点亮奇梦：夜光幻影秀",
  activity_type: "娱乐演出",
  current_price: 0,  # 免费，含在门票内
  description: "奇幻城堡投影秀，配合烟花和音乐，讲述迪士尼经典故事。",
  duration: "30分钟",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海东方明珠景点内项目
attraction = attractions["上海东方明珠广播电视塔"]
attraction_activities_data << {
  attraction_id: attraction.id,
  name: "旋转餐厅用餐",
  activity_type: "餐饮服务",
  current_price: 398,
  description: "267米空中旋转餐厅，360度观景，中西式自助餐。",
  duration: "2小时",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# V310需要：人像跟拍服务
attraction_activities_data << {
  attraction_id: attraction.id,
  name: "人像跟拍服务",
  activity_type: "摄影服务",
  current_price: 688,
  description: "专业摄影师全程跟拍，提供40张精修照片。拍摄地点：观光层、空中走廊、外滩全景。拍摄后48小时内电子交付。",
  duration: "2-3小时",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# V310需要：服装租赁+化妆造型
attraction_activities_data << {
  attraction_id: attraction.id,
  name: "服装租赁+化妆造型",
  activity_type: "摄影服务",
  current_price: 388,
  description: "提供多套主题服装选择（旗袍、礼服、民国风等），包含专业化妆造型服务。服装租赁时长4小时。",
  duration: "4小时",
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 批量插入景点内项目数据
AttractionActivity.insert_all(attraction_activities_data)

puts "✓ 创建了 #{attraction_activities_data.size} 个景点内项目"

# ==================== 为蜈支洲岛添加门票和活动 ====================
# 为其他数据包创建的景点添加门票和活动数据

puts "\n为蜈支洲岛添加门票和活动..."

supplemental_tickets_data = []
supplemental_activities_data = []
supplemental_ticket_suppliers_data = []

# 蜈支洲岛门票 (门票页面需要)
if (wuzhizhou_island = Attraction.find_by(name: '蜈支洲岛', data_version: 0))
  # 添加景区门票
  supplemental_tickets_data << {
    attraction_id: wuzhizhou_island.id,
    name: "蜈支洲岛成人票",
    ticket_type: "adult",
    original_price: 168,
    current_price: 148,
    discount_info: "线上预订立减20元",
    requirements: "身靰1.4米以上游客",
    booking_notice: "请至少提前2小时预订；凭订单短信至景区售票处换票；1.2米以下儿童免票；门票当日有效。",
    refund_policy: "未使用可随时退款，使用后不可退改。",
    validity_days: 1,
    sales_count: 8520,
    stock: 1000,
    image_url: ImageSeedHelper.random_image_from_category(:attractions),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  supplemental_tickets_data << {
    attraction_id: wuzhizhou_island.id,
    name: "蜈支洲岛儿童票",
    ticket_type: "child",
    original_price: 88,
    current_price: 78,
    discount_info: "儿童优惠票",
    requirements: "身靰1.2米-1.4米儿童",
    booking_notice: "请至少提前2小时预订；凭订单短信至景区售票处换票；需出示儿童身份证件；门票当日有效。",
    refund_policy: "未使用可随时退款，使用后不可退改。",
    validity_days: 1,
    sales_count: 3210,
    stock: 500,
    image_url: ImageSeedHelper.random_image_from_category(:attractions),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  puts "     ✓ 为蜈支洲岛添加2张门票（成人票、儿童票）"
end

# 蜈支洲岛景点内项目 (V308需要：潜水教学+体验+摄影)
if (wuzhizhou_island = Attraction.find_by(name: '蜈支洲岛', data_version: 0))
  supplemental_activities_data << {
    attraction_id: wuzhizhou_island.id,
    name: "潜水教学+体验",
    activity_type: "水上运动",
    current_price: 380,
    description: "专业教练带领，适合初学者。包含潜水装备租赁、教学课程、潜水体验（深度6-12米）。每次限制最备4人，保障学习质量。",
    duration: "2-3小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }

  supplemental_activities_data << {
    attraction_id: wuzhizhou_island.id,
    name: "水下摄影服务",
    activity_type: "摄影服务",
    current_price: 200,
    description: "专业水下摄影师全程跟拍，提供精修照片。包含20张海洋生物与环境的高清照片，拍摄后24小时内电子交付。",
    duration: "1-2小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  puts "     ✓ 为蜈支洲岛添加2个活动（潜水教学+体验、水下摄影服务）"
else
  puts "     ⚠ 警告：未找到蜈支洲岛景点，跳过潜水活动创建"
end

# 批量插入门票数据
if supplemental_tickets_data.any?
  Ticket.insert_all(supplemental_tickets_data)
  puts "✓ 创建了 #{supplemental_tickets_data.size} 张补充门票"
end

# 为蜈支洲岛门票添加供应商关联
if (wuzhizhou_island = Attraction.find_by(name: '蜈支洲岛', data_version: 0))
  adult_ticket = Ticket.find_by(attraction_id: wuzhizhou_island.id, ticket_type: 'adult', data_version: 0)
  child_ticket = Ticket.find_by(attraction_id: wuzhizhou_island.id, ticket_type: 'child', data_version: 0)
  
  if adult_ticket && child_ticket
    # 成人票供应商
    supplemental_ticket_suppliers_data << {
      ticket_id: adult_ticket.id,
      supplier_id: 1,  # 携程旅行
      current_price: 148,
      original_price: 168,
      stock: 500,
      discount_info: '线上预订立减20元',
      sales_count: 4200,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    supplemental_ticket_suppliers_data << {
      ticket_id: adult_ticket.id,
      supplier_id: 2,  # 飞猪旅行
      current_price: 145,
      original_price: 168,
      stock: 600,
      discount_info: '新用户立减23元',
      sales_count: 3100,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    supplemental_ticket_suppliers_data << {
      ticket_id: adult_ticket.id,
      supplier_id: 4,  # 景区官方
      current_price: 168,
      original_price: 168,
      stock: 1000,
      discount_info: nil,
      sales_count: 1220,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    # 儿童票供应商
    supplemental_ticket_suppliers_data << {
      ticket_id: child_ticket.id,
      supplier_id: 1,  # 携程旅行
      current_price: 78,
      original_price: 88,
      stock: 300,
      discount_info: '儿童优惠票',
      sales_count: 1500,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    supplemental_ticket_suppliers_data << {
      ticket_id: child_ticket.id,
      supplier_id: 2,  # 飞猪旅行
      current_price: 75,
      original_price: 88,
      stock: 400,
      discount_info: '新用户立减13元',
      sales_count: 1200,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    supplemental_ticket_suppliers_data << {
      ticket_id: child_ticket.id,
      supplier_id: 4,  # 景区官方
      current_price: 88,
      original_price: 88,
      stock: 500,
      discount_info: nil,
      sales_count: 510,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    puts "     ✓ 为蜈支洲岛门票添加供应商关联（6个）"
  end
end

if supplemental_ticket_suppliers_data.any?
  TicketSupplier.insert_all(supplemental_ticket_suppliers_data)
  puts "✓ 创建了 #{supplemental_ticket_suppliers_data.size} 个门票供应商关联"
end

# 批量插入景点内项目数据
if supplemental_activities_data.any?
  AttractionActivity.insert_all(supplemental_activities_data)
  puts "✓ 创建了 #{supplemental_activities_data.size} 个补充景点内项目"
end

# ==================== 为华山添加门票和登山活动 ====================
# 用于V311：预订登山门票+向导装备+山顶住宿

puts "\n为华山添加门票和登山活动..."

huashan_tickets_data = []
huashan_activities_data = []

if (huashan = Attraction.find_by(name: '华山', data_version: 0))
  # 添加华山门票
  huashan_tickets_data << {
    attraction_id: huashan.id,
    name: "华山景区成人票",
    ticket_type: "adult",
    original_price: 180,
    current_price: 160,
    discount_info: "线上预订立减20元",
    requirements: "身高1.4米以上游客",
    booking_notice: "请至少提前2小时预订；凭订单短信至景区售票处换票；1.2米以下儿童免票；门票当日有效。",
    refund_policy: "未使用可随时退款，使用后不可退改。",
    validity_days: 1,
    sales_count: 15600,
    stock: 2000,
    image_url: ImageSeedHelper.random_image_from_category(:attractions),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  huashan_tickets_data << {
    attraction_id: huashan.id,
    name: "华山景区儿童票",
    ticket_type: "child",
    original_price: 90,
    current_price: 80,
    discount_info: "儿童优惠票",
    requirements: "身高1.2米-1.4米儿童",
    booking_notice: "请至少提前2小时预订；凭订单短信至景区售票处换票；需出示儿童身份证件；门票当日有效。",
    refund_policy: "未使用可随时退款，使用后不可退改。",
    validity_days: 1,
    sales_count: 5200,
    stock: 800,
    image_url: ImageSeedHelper.random_image_from_category(:attractions),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  puts "     ✓ 为华山添加2张门票（成人票、儿童票）"
end

# 华山景点内项目 (V311需要：登山向导+装备租赁, V314需要：攀岩教学+安全装备+教练陪同)
if (huashan = Attraction.find_by(name: '华山', data_version: 0))
  # 活动1: 登山向导+装备租赁服务 (V311)
  huashan_activities_data << {
    attraction_id: huashan.id,
    name: "登山向导+装备租赁服务",
    activity_type: "运动体验",
    current_price: 580,
    description: "专业登山向导带领，适合初学者。包含登山装备租赁（登山杖、安全绳、头盔、手套）、向导讲解服务、安全保障。每次限制最多6人，保障服务质量。",
    duration: "6-8小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 活动2: 攀岩教学+安全装备+教练陪同 (V314)
  huashan_activities_data << {
    attraction_id: huashan.id,
    name: "攀岩教学+安全装备+教练陪同",
    activity_type: "运动体验",
    current_price: 480,
    description: "华山攀岩专业教练一对一指导，适合初学者和进阶者。包含攀岩装备租赁（安全绳、头盔、手套、攀岩鞋）、教学课程、教练全程陪同、运动保险，保障安全。每次限制最多4人。",
    duration: "3-4小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  puts "     ✓ 为华山添加2个活动（登山向导+装备租赁、攀岩教学+安全装备+教练）"
else
  puts "     ⚠ 警告：未找到华山景点，跳过登山和攀岩活动创建"
end

# 批量插入华山门票数据
if huashan_tickets_data.any?
  Ticket.insert_all(huashan_tickets_data)
  puts "✓ 创建了 #{huashan_tickets_data.size} 张华山门票"
end

# 批量插入华山活动数据
if huashan_activities_data.any?
  AttractionActivity.insert_all(huashan_activities_data)
  puts "✓ 创建了 #{huashan_activities_data.size} 个华山活动"
end

# ==================== 深圳大梅沙海滨公园活动数据 ====================
# 为冲浪验证器v312提供数据支持

dameisha = Attraction.find_by(name: "深圳大梅沙海滨公园", data_version: 0)

dameisha_activities_data = []

if dameisha
  puts "正在为深圳大梅沙海滨公园添加冲浪相关活动..."
  
  # 活动1: 冲浪教学（含装备）
  dameisha_activities_data << {
    attraction_id: dameisha.id,
    name: "冲浪教学（含装备）",
    activity_type: "水上运动",
    current_price: 280,
    description: "专业冲浪教练一对一指导，适合初学者。包含冲浪板、防寒服、脚绳等全套装备租赁，课程时长2小时，保障安全。",
    duration: "2小时",
    image_url: ImageSeedHelper.random_image_from_category(:activities),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 活动2: 海滩娱乐项目
  dameisha_activities_data << {
    attraction_id: dameisha.id,
    name: "海滩娱乐项目",
    activity_type: "娱乐演出",
    current_price: 150,
    description: "包含沙滩排球、摩托艇、香蕉船、飞鱼艇等多项海上娱乐活动，任选其一体验，感受海滨乐趣。",
    duration: "1小时",
    image_url: ImageSeedHelper.random_image_from_category(:activities),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  puts "     ✓ 为深圳大梅沙海滨公园添加2个活动（冲浪教学+海滩娱乐）"
else
  puts "     ⚠ 警告：未找到深圳大梅沙海滨公园景点，跳过冲浪活动创建"
end

# 批量插入大梅沙活动数据
if dameisha_activities_data.any?
  AttractionActivity.insert_all(dameisha_activities_data)
  puts "✓ 创建了 #{dameisha_activities_data.size} 个深圳大梅沙活动"
end

# ==================== 南山一棵树攀岩活动数据 ====================
# 为攀岩验证器v266/v310/v314/v315/v316提供数据支持

nanshan = Attraction.find_by(name: "南山一棵树", data_version: 0)

nanshan_activities_data = []

if nanshan
  puts "正在为南山一棵树添加攀岩相关活动..."
  
  # 活动1: 攀岩教学+安全装备+教练陪同
  nanshan_activities_data << {
    attraction_id: nanshan.id,
    name: "攀岩教学+安全装备+教练陪同",
    activity_type: "运动体验",
    current_price: 380,
    description: "专业攀岩教练一对一指导，适合初学者。包含攀岩装备租赁（安全绳、头盔、手套、攀岩鞋）、教学课程、教练全程陪同，保障安全。每次限制最多4人。",
    duration: "2-3小时",
    image_url: ImageSeedHelper.random_image_from_category(:activities),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  # 活动2: 极限攀岩挑战
  nanshan_activities_data << {
    attraction_id: nanshan.id,
    name: "极限攀岩挑战",
    activity_type: "运动体验",
    current_price: 580,
    description: "适合有经验的攀岩爱好者，挑战高难度线路。包含专业装备、教练保护、运动伤害保险。难度系数5.10-5.12。",
    duration: "3-4小时",
    image_url: ImageSeedHelper.random_image_from_category(:activities),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  puts "     ✓ 为南山一棵树添加2个活动（攀岩教学+极限攀岩）"
else
  puts "     ⚠ 警告：未找到南山一棵树景点，跳过攀岩活动创建"
end

# 批量插入南山攀岩活动数据
if nanshan_activities_data.any?
  AttractionActivity.insert_all(nanshan_activities_data)
  puts "✓ 创建了 #{nanshan_activities_data.size} 个南山一棵树攀岩活动"
end

# ==================== 为 V315 添加漂流活动 ====================
# V315需要：漂流探险+安全保障+装备提供
# V315的查询逻辑：.where("name LIKE ? OR name LIKE ? OR name LIKE ?", '%江%', '%河%', '%峡%').first
# 第一个匹配的景点是"长江索道"

puts "\n为长江索道添加漂流活动..."

changjiang_rafting_activities = []

if (changjiang_cableway = Attraction.find_by(name: '长江索道', data_version: 0))
  changjiang_rafting_activities << {
    attraction_id: changjiang_cableway.id,
    name: "长江观光漂流",
    activity_type: "水上运动",
    current_price: 480,
    description: "长江观光漂流体验，包含全套安全装备（头盔、救生衣、漂流船）、专业教练全程陪同、运动保险。适合无经验者，沿途欣赏两江交汇美景。",
    duration: "3-4小时",
    image_url: ImageSeedHelper.random_image_from_category(:activities),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  puts "     ✓ 为长江索道添加漂流活动"
else
  puts "     ⚠ 警告：未找到长江索道景点，跳过漂流活动创建"
end

if changjiang_rafting_activities.any?
  AttractionActivity.insert_all(changjiang_rafting_activities)
  puts "✓ 创建了 #{changjiang_rafting_activities.size} 个长江索道漂流活动"
end

# ==================== 为 V316 添加马术活动 ====================
# V316需要：马术体验+教练指导+马场服务
# V316的查询逻辑：.where("name LIKE ? OR name LIKE ?", '%草原%', '%马场%').first
# 创建专门的马场景点以支持马术活动

puts "\n创建马场景点并添加马术活动..."

# 创建马场景点
equestrian_attractions_data = []
equestrian_activities_data = []

equestrian_attractions_data << {
  name: "八达岭国际马场",
  city: "北京",
  province: "北京",
  description: "位于长城脚下的专业马术训练基地，拥有国际标准马场和专业教练团队。提供从基础骑乘到高级马术的全方位培训服务，适合各年龄段马术爱好者。",
  address: "北京市延庆区八达岭镇",
  latitude: 40.3587,
  longitude: 115.9870,
  rating: 4.7,
  cover_image_url: ImageSeedHelper.random_image_from_category(:attractions),
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

puts "     ✓ 准备创建八达岭国际马场"

# 批量插入马场景点
if equestrian_attractions_data.any?
  Attraction.insert_all(equestrian_attractions_data)
  puts "✓ 创建了 #{equestrian_attractions_data.size} 个马场景点"
  
  # 为马场添加马术体验活动
  if (equestrian_center = Attraction.find_by(name: '八达岭国际马场', data_version: 0))
    equestrian_activities_data << {
      attraction_id: equestrian_center.id,
      name: "马术体验课程",
      activity_type: "运动体验",
      current_price: 380,
      description: "专业马术教练一对一指导，适合零基础学员。包含马场服务、全套骑马装备租赁（头盔、护具、骑马服、马靴）、基础骑乘技巧教学、运动保险。体验路线约2公里，包含平地和小坡练习。",
      duration: "2-3小时",
      image_url: ImageSeedHelper.random_image_from_category(:activities),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    equestrian_activities_data << {
      attraction_id: equestrian_center.id,
      name: "亲子马术体验",
      activity_type: "运动体验",
      current_price: 680,
      description: "适合家庭参与的马术体验活动，一位教练带领一个家庭（最多3人）。包含马场服务、装备租赁、安全讲解、基础骑乘教学、合影服务。",
      duration: "2小时",
      image_url: ImageSeedHelper.random_image_from_category(:activities),
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    puts "     ✓ 为八达岭国际马场添加马术活动"
  end
end

if equestrian_activities_data.any?
  AttractionActivity.insert_all(equestrian_activities_data)
  puts "✓ 创建了 #{equestrian_activities_data.size} 个马术活动"
end

# ==================== 为杭州西湖添加门票和自行车租赁活动 ====================
# 用于V313：预订杭州西湖3人自行车环湖骑行服务

puts "\n为杭州西湖添加门票和自行车租赁活动..."

xihu_tickets_data = []
xihu_activities_data = []
xihu_ticket_suppliers_data = []

if (xihu = Attraction.find_by(name: '西湖', city: '杭州', data_version: 0))
  # 添加西湖门票（免费景区，但游船、部分景点需门票）
  xihu_tickets_data << {
    attraction_id: xihu.id,
    name: "西湖门票（免费）",
    ticket_type: "adult",
    original_price: 0,
    current_price: 0,
    discount_info: nil,
    requirements: "所有游客，需提前预约",
    booking_notice: "西湖景区免费开放，但需提前1天预约；凭预约码入园；预约当日有效。",
    refund_policy: "未使用可随时取消预约。",
    validity_days: 1,
    sales_count: 85600,
    stock: 9999,
    image_url: ImageSeedHelper.random_image_from_category(:attractions),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  xihu_tickets_data << {
    attraction_id: xihu.id,
    name: "西湖游船票",
    ticket_type: "adult",
    original_price: 55,
    current_price: 45,
    discount_info: "线上预订立减10元",
    requirements: "身高1.2米以上游客",
    booking_notice: "请至少提前1小时预订；凭订单短信至码头换票；1.2米以下儿童免票；门票当日有效。游船路线：断桥→三潭印月→岳庙码头，约45分钟。",
    refund_policy: "未使用可随时退款，使用后不可退改。",
    validity_days: 1,
    sales_count: 12800,
    stock: 2000,
    image_url: ImageSeedHelper.random_image_from_category(:attractions),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  xihu_tickets_data << {
    attraction_id: xihu.id,
    name: "西湖游船票（儿童票）",
    ticket_type: "child",
    original_price: 28,
    current_price: 25,
    discount_info: "儿童优惠票",
    requirements: "身高1.2米以下儿童",
    booking_notice: "请至少提前1小时预订；凭订单短信至码头换票；需成人陪同；门票当日有效。游船路线：断桥→三潭印月→岳庙码头。",
    refund_policy: "未使用可随时退款，使用后不可退改。",
    validity_days: 1,
    sales_count: 4200,
    stock: 1000,
    image_url: ImageSeedHelper.random_image_from_category(:attractions),
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  puts "     ✓ 为杭州西湖添加3张门票（免费门票、游船成人票、游船儿童票）"
end

# 杭州西湖景点内项目 (V313需要：自行车租赁服务)
if (xihu = Attraction.find_by(name: '西湖', city: '杭州', data_version: 0))
  xihu_activities_data << {
    attraction_id: xihu.id,
    name: "双人自行车租赁",
    activity_type: "ride",
    current_price: 80,
    description: "环西湖骑行体验，双人自行车租赁。包含车辆、头盔、锁具。推荐路线：断桥→白堤→平湖秋月→苏堤→雷峰塔，全程约10公里。租赁时长4小时，押金200元。",
    duration: "4小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  xihu_activities_data << {
    attraction_id: xihu.id,
    name: "单人自行车租赁",
    activity_type: "ride",
    current_price: 50,
    description: "环西湖骑行体验，单人自行车租赁。包含车辆、头盔、锁具。推荐路线：沿湖骑行，自由探索西湖美景。租赁时长4小时，押金100元。",
    duration: "4小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  xihu_activities_data << {
    attraction_id: xihu.id,
    name: "电动自行车租赁",
    activity_type: "ride",
    current_price: 120,
    description: "环西湖电动自行车租赁，省力便捷。包含电动车、头盔、充电器、锁具。续航30公里，适合全天游览。租赁时长8小时，押金300元。",
    duration: "8小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
  
  puts "     ✓ 为杭州西湖添加3个活动（双人自行车、单人自行车、电动自行车租赁）"
else
  puts "     ⚠ 警告：未找到杭州西湖景点，跳过自行车租赁活动创建"
end

# 批量插入西湖门票数据
if xihu_tickets_data.any?
  Ticket.insert_all(xihu_tickets_data)
  puts "✓ 创建了 #{xihu_tickets_data.size} 张西湖门票"
end

# 为西湖门票添加供应商关联
if (xihu = Attraction.find_by(name: '西湖', city: '杭州', data_version: 0))
  free_ticket = Ticket.find_by(attraction_id: xihu.id, name: '西湖门票（免费）', data_version: 0)
  boat_ticket = Ticket.find_by(attraction_id: xihu.id, name: '西湖游船票', data_version: 0)
  child_ticket = Ticket.find_by(attraction_id: xihu.id, ticket_type: 'child', data_version: 0)
  
  if free_ticket
    # 免费票供应商（景区官方预约）
    xihu_ticket_suppliers_data << {
      ticket_id: free_ticket.id,
      supplier_id: 4,  # 景区官方
      current_price: 0,
      original_price: 0,
      stock: 9999,
      discount_info: nil,
      sales_count: 85600,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
  
  if boat_ticket && child_ticket
    # 游船成人票供应商
    xihu_ticket_suppliers_data << {
      ticket_id: boat_ticket.id,
      supplier_id: 1,  # 携程旅行
      current_price: 45,
      original_price: 55,
      stock: 800,
      discount_info: '线上预订立减10元',
      sales_count: 6400,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    xihu_ticket_suppliers_data << {
      ticket_id: boat_ticket.id,
      supplier_id: 2,  # 飞猪旅行
      current_price: 42,
      original_price: 55,
      stock: 1000,
      discount_info: '新用户立减13元',
      sales_count: 4800,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    xihu_ticket_suppliers_data << {
      ticket_id: boat_ticket.id,
      supplier_id: 4,  # 景区官方
      current_price: 55,
      original_price: 55,
      stock: 2000,
      discount_info: nil,
      sales_count: 1600,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    # 游船儿童票供应商
    xihu_ticket_suppliers_data << {
      ticket_id: child_ticket.id,
      supplier_id: 1,  # 携程旅行
      current_price: 25,
      original_price: 28,
      stock: 500,
      discount_info: '儿童优惠票',
      sales_count: 2000,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    xihu_ticket_suppliers_data << {
      ticket_id: child_ticket.id,
      supplier_id: 2,  # 飞猪旅行
      current_price: 23,
      original_price: 28,
      stock: 600,
      discount_info: '新用户立减5元',
      sales_count: 1600,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    xihu_ticket_suppliers_data << {
      ticket_id: child_ticket.id,
      supplier_id: 4,  # 景区官方
      current_price: 28,
      original_price: 28,
      stock: 1000,
      discount_info: nil,
      sales_count: 600,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    puts "     ✓ 为西湖门票添加供应商关联（7个）"
  end
end

if xihu_ticket_suppliers_data.any?
  TicketSupplier.insert_all(xihu_ticket_suppliers_data)
  puts "✓ 创建了 #{xihu_ticket_suppliers_data.size} 个西湖门票供应商关联"
end

# 批量插入西湖活动数据
if xihu_activities_data.any?
  AttractionActivity.insert_all(xihu_activities_data)
  puts "✓ 创建了 #{xihu_activities_data.size} 个西湖自行车租赁活动"
end

puts "✓ 景点数据包加载完成"
