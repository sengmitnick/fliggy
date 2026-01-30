# frozen_string_literal: true

require_relative '../../../../../app/helpers/image_seed_helper'

# 景点数据包 - 使用 insert_all 批量插入
# 包含景点、门票、景点内项目、一日游等数据
#
# ⚠️ 注意：景点没有 image_url 字段，所以无需迁移图片
# 但其他模型（门票、一日游等）可能需要图片

puts "正在加载景点数据包..."

# 清理现有数据
AttractionReview.destroy_all
ActivityOrder.destroy_all
TicketOrder.destroy_all
AttractionActivity.destroy_all
TicketSupplier.destroy_all
Ticket.destroy_all
Attraction.destroy_all

timestamp = Time.current

# ==================== 景点数据 ====================

attractions_data = [
  # ========== 深圳景点 (8个) ==========
  {
    name: "深圳欢乐港湾",
    slug: "shenzhen-happy-harbor",
    province: "广东省",
    city: "深圳",
    district: "宝安区",
    address: "深圳市宝安区海天路与宝华路交汇处",
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
    province: "广东省",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区华侨城深南大道9037号",
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
    province: "广东省",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区侨城西路18号",
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
    province: "广东省",
    city: "深圳",
    district: "盐田区",
    address: "深圳市盐田区大梅沙东部华侨城",
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
    province: "广东省",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区西丽湖路4065号",
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
    province: "广东省",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区深南大道9003号",
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
    province: "广东省",
    city: "深圳",
    district: "南山区",
    address: "深圳市南山区蛇口望海路1128号",
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
    province: "广东省",
    city: "深圳",
    district: "盐田区",
    address: "深圳市盐田区大梅沙盐梅路9号",
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
    province: "上海市",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区川沙新镇上海迪士尼度假区",
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
    province: "上海市",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区南汇新城银飞路166号",
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
    province: "上海市",
    city: "上海",
    district: "松江区",
    address: "上海市松江区林湖路888号",
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
    province: "上海市",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区南六公路178号",
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
    province: "上海市",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区世纪大道1号",
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
    province: "上海市",
    city: "上海",
    district: "浦东新区",
    address: "上海市浦东新区世纪大道2000号",
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
    province: "上海市",
    city: "上海",
    district: "黄浦区",
    address: "上海市黄浦区中山东一路",
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
  }
]

# 批量插入景点数据
Attraction.insert_all(attractions_data)
# Regenerate slugs for FriendlyId (insert_all bypasses callbacks)
Attraction.find_each(&:save)

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

# 批量插入门票数据
Ticket.insert_all(tickets_data)

puts "✓ 创建了 #{tickets_data.size} 张门票"

# ==================== 景点内项目数据 ====================
# 注意：AttractionActivity 模型没有 image_url 字段，无需迁移图片

attraction_activities_data = []

# 深圳东部华侨城景点内项目
attraction = attractions["深圳东部华侨城"]
attraction_activities_data << {
  attraction_id: attraction.id,
  name: "云中部落观光缆车",
  category: "交通工具",
  current_price: 35,
  requirements: "索道全长约1600米，从大侠谷至云中部落，欣赏沿途美景。",
  duration: "15分钟单程",
  booking_required: false,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

attraction_activities_data << {
  attraction_id: attraction.id,
  name: "云海谷高尔夫球场",
  category: "运动体验",
  current_price: 580,
  requirements: "27洞山地高尔夫球场，含球杆租赁和教练指导。",
  duration: "4-5小时",
  booking_required: true,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海海昌海洋公园景点内项目
attraction = attractions["上海海昌海洋公园"]
attraction_activities_data << {
  attraction_id: attraction.id,
  name: "VR深海奇妙夜",
  category: "互动体验",
  current_price: 80,
  requirements: "佩戴VR设备，沉浸式体验深海世界，与海洋生物互动。",
  duration: "20分钟",
  booking_required: false,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

attraction_activities_data << {
  attraction_id: attraction.id,
  name: "海豚互动体验",
  category: "动物互动",
  current_price: 380,
  requirements: "在专业驯养师指导下，近距离接触海豚，喂食、抚摸、合影。限4-12岁儿童。",
  duration: "30分钟",
  booking_required: true,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海迪士尼乐园景点内项目
attraction = attractions["上海迪士尼乐园"]
attraction_activities_data << {
  attraction_id: attraction.id,
  name: "米奇童话专列巡游",
  category: "娱乐演出",
  current_price: 0,  # 免费，含在门票内
  requirements: "迪士尼经典花车巡游，米奇、米妮、唐老鸭等经典角色登场。",
  duration: "30分钟",
  booking_required: false,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

attraction_activities_data << {
  attraction_id: attraction.id,
  name: "点亮奇梦：夜光幻影秀",
  category: "娱乐演出",
  current_price: 0,  # 免费，含在门票内
  requirements: "奇幻城堡投影秀，配合烟花和音乐，讲述迪士尼经典故事。",
  duration: "30分钟",
  booking_required: false,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 上海东方明珠景点内项目
attraction = attractions["上海东方明珠广播电视塔"]
attraction_activities_data << {
  attraction_id: attraction.id,
  name: "旋转餐厅用餐",
  category: "餐饮服务",
  current_price: 398,
  requirements: "267米空中旋转餐厅，360度观景，中西式自助餐。",
  duration: "2小时",
  booking_required: true,
  data_version: 0,
  created_at: timestamp,
  updated_at: timestamp
}

# 批量插入景点内项目数据
AttractionActivity.insert_all(attraction_activities_data)

puts "✓ 创建了 #{attraction_activities_data.size} 个景点内项目"

puts "✓ 景点数据包加载完成"
