# frozen_string_literal: true

# 包车游数据包 v1
# 包含武汉地区的包车游路线、景点和车型数据
#
# 用途：
# - 初始化包车游系统的基础数据
# - 提供测试和演示数据
#
# 加载方式：
# rails runner "load Rails.root.join('app/validators/support/data_packs/v1/chartered_tours.rb')"


# 确保武汉城市存在
wuhan = City.find_or_create_by!(name: '武汉') do |city|
  city.pinyin = 'wuhan'
  city.region = '华中'
  city.is_hot = true
end


# 1. 创建景点（使用省/市/区字符串字段）
attractions_data = [
  {
    name: '黄鹤楼',
    city: wuhan.name,
    province: '湖北',
    district: '武昌区',
    address: '武昌区蛇山西坡特1号',
    latitude: 30.5450,
    longitude: 114.2968,
    rating: 4.6,
    review_count: 15234,
    opening_hours: '08:00-18:00',
    phone: '027-88877332',
    description: '江南三大名楼之一，"昔人已乘黄鹤楼去，此地空余黄鹤楼"。登楼远眺，武汉三镇尽收眼底，长江大桥飞架南北。'
  },
  {
    name: '武汉大学',
    city: wuhan.name,
    province: '湖北',
    district: '武昌区',
    address: '武昌区八一路299号',
    latitude: 30.5327,
    longitude: 114.3671,
    rating: 4.7,
    review_count: 12890,
    opening_hours: '全天开放',
    phone: '027-68752114',
    description: '中国最美大学之一，樱花季美景如画。校园依山傍水，建筑古朴典雅，是赏樱胜地。'
  },
  {
    name: '湖北省博物馆',
    city: wuhan.name,
    province: '湖北',
    district: '武昌区',
    address: '武昌区东湖路160号',
    latitude: 30.5613,
    longitude: 114.3708,
    rating: 4.8,
    review_count: 8765,
    opening_hours: '09:00-17:00（周一闭馆）',
    phone: '027-86794127',
    description: '编钟之乡，珍藏曾侯乙编钟等国宝级文物。可以欣赏到精彩的编钟演奏表演。'
  },
  {
    name: '东湖听涛景区',
    city: wuhan.name,
    province: '湖北',
    district: '武昌区',
    address: '武昌区沿湖大道16号',
    latitude: 30.5672,
    longitude: 114.3918,
    rating: 4.5,
    review_count: 6543,
    opening_hours: '全天开放',
    phone: '027-86772505',
    description: '中国最大的城中湖，风景秀丽。可以游湖、骑行、漫步湖畔绿道，感受自然之美。'
  },
  {
    name: '长江游船',
    city: wuhan.name,
    province: '湖北',
    district: '汉口区',
    address: '汉口区中山大道武汉港',
    latitude: 30.5833,
    longitude: 114.3054,
    rating: 4.4,
    review_count: 4321,
    opening_hours: '14:00-20:00',
    phone: '027-82782222',
    description: '乘船游览长江，感受武汉两江交汇的壮观。夜游长江，欣赏两岸灯光秀，美轮美奂。'
  },
  {
    name: '古德寺',
    city: wuhan.name,
    province: '湖北',
    district: '汉口区',
    address: '汉口区黄浦路上滑坡74号',
    latitude: 30.6103,
    longitude: 114.2858,
    rating: 4.3,
    review_count: 2345,
    opening_hours: '08:00-17:00',
    phone: '027-82832994',
    description: '建筑风格独特的佛教寺院，融合了中西建筑元素。寺内清静祥和，是闹市中的一片净土。'
  },
  {
    name: '晴川阁',
    city: wuhan.name,
    province: '湖北',
    district: '汉阳区',
    address: '汉阳区洗马长街86号',
    latitude: 30.5499,
    longitude: 114.2752,
    rating: 4.4,
    review_count: 3456,
    opening_hours: '08:00-17:00',
    phone: '027-84710101',
    description: '楚天第一名楼，与黄鹤楼隔江相望。登楼可远眺长江大桥，景色壮丽。'
  },
  {
    name: '户部巷',
    city: wuhan.name,
    province: '湖北',
    district: '武昌区',
    address: '武昌区司门口户部巷',
    latitude: 30.5483,
    longitude: 114.2991,
    rating: 4.2,
    review_count: 9876,
    opening_hours: '07:00-23:00',
    phone: '027-88871688',
    description: '武汉著名美食街，汇集热干面、豆皮、面窝等武汉特色小吃。品尝地道早点的最佳去处。'
  },
  {
    name: '木兰天池',
    city: wuhan.name,
    province: '湖北',
    district: '黄陂区',
    address: '黄陂区长轩岭街道',
    latitude: 31.1234,
    longitude: 114.5678,
    rating: 4.5,
    review_count: 5432,
    opening_hours: '08:00-17:30',
    phone: '027-61518923',
    description: '国家森林公园，山清水秀，空气清新。可以爬山、玩水、赏瀑布，是周边游的好去处。'
  }
]

Attraction.insert_all(attractions_data)
attractions = Attraction.by_city(wuhan.name).index_by(&:name)


# 2. 创建车型
vehicle_types_data = [
  {
    name: '经济5座',
    category: '5座',
    level: '经济',
    seats: 5,
    luggage_capacity: 2,
    hourly_price_6h: 308.0,
    hourly_price_8h: 388.0,
    included_mileage: 100,
    image_url: 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2'
  },
  {
    name: '舒适5座',
    category: '5座',
    level: '舒适',
    seats: 5,
    luggage_capacity: 2,
    hourly_price_6h: 378.0,
    hourly_price_8h: 478.0,
    included_mileage: 100,
    image_url: 'https://images.unsplash.com/photo-1563720360172-67b8f3dce741'
  },
  {
    name: '豪华5座',
    category: '5座',
    level: '豪华',
    seats: 5,
    luggage_capacity: 3,
    hourly_price_6h: 588.0,
    hourly_price_8h: 688.0,
    included_mileage: 100,
    image_url: 'https://images.unsplash.com/photo-1617814076367-b759c7d7e738'
  },
  {
    name: '经济7座',
    category: '7座',
    level: '经济',
    seats: 7,
    luggage_capacity: 3,
    hourly_price_6h: 428.0,
    hourly_price_8h: 528.0,
    included_mileage: 100,
    image_url: 'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b'
  },
  {
    name: '舒适7座',
    category: '7座',
    level: '舒适',
    seats: 7,
    luggage_capacity: 3,
    hourly_price_6h: 528.0,
    hourly_price_8h: 628.0,
    included_mileage: 100,
    image_url: 'https://images.unsplash.com/photo-1503736334956-4c8f8e92946d'
  },
  {
    name: '商务巴士',
    category: '巴士',
    level: '舒适',
    seats: 15,
    luggage_capacity: 10,
    hourly_price_6h: 888.0,
    hourly_price_8h: 1088.0,
    included_mileage: 100,
    image_url: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957'
  }
]

VehicleType.insert_all(vehicle_types_data)
vehicle_types = VehicleType.all.index_by(&:name)


# 3. 创建包车路线
routes_data = [
  {
    name: '武汉经典一日游',
    city_id: wuhan.id,
    slug: nil, # Will be generated by FriendlyId
    duration_days: 1,
    distance_km: 50,
    category: 'hot',
    description: '游览武汉最著名的景点，包括黄鹤楼、武汉大学、湖北省博物馆、东湖听涛景区，深度体验武汉历史文化。',
    price_from: 450.0,
    highlights: ['黄鹤楼登高望远', '武大赏樱花', '编钟演奏', '东湖泛舟', '品尝美食'].to_json,
    cover_image_url: 'https://images.unsplash.com/photo-1580836572436-7f8e60ec0d99'
  },
  {
    name: '武汉精华四景',
    city_id: wuhan.id,
    slug: nil,
    duration_days: 1,
    distance_km: 40,
    category: 'featured',
    description: '精选武汉四大必游景点，轻松舒适的行程安排，适合第一次来武汉的游客。',
    price_from: 400.0,
    highlights: ['黄鹤楼', '武汉大学', '省博物馆', '东湖听涛'].to_json,
    cover_image_url: 'https://images.unsplash.com/photo-1562774053-701939374585'
  },
  {
    name: '武汉文化深度游',
    city_id: wuhan.id,
    slug: nil,
    duration_days: 1,
    distance_km: 55,
    category: 'classic',
    description: '深度探索武汉历史文化，游览黄鹤楼、古德寺、晴川阁等文化景点，感受武汉深厚的历史底蕴。',
    price_from: 480.0,
    highlights: ['黄鹤楼', '古德寺独特建筑', '晴川阁', '省博物馆', '东湖'].to_json,
    cover_image_url: 'https://images.unsplash.com/photo-1566127992631-137a642a90f4'
  },
  {
    name: '武汉美食文化游',
    city_id: wuhan.id,
    slug: nil,
    duration_days: 1,
    distance_km: 35,
    category: 'featured',
    description: '游览武汉经典景点的同时，深入户部巷品尝地道武汉美食，热干面、豆皮、面窝一网打尽。',
    price_from: 380.0,
    highlights: ['黄鹤楼', '户部巷美食', '长江游船', '品尝热干面'].to_json,
    cover_image_url: 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1'
  },
  {
    name: '武汉夜游江城',
    city_id: wuhan.id,
    slug: nil,
    duration_days: 1,
    distance_km: 30,
    category: 'hot',
    description: '体验武汉夜晚的魅力，乘坐长江游船欣赏两岸灯光秀，感受江城夜色之美。',
    price_from: 420.0,
    highlights: ['长江夜游', '两岸灯光秀', '江滩夜景', '夜市美食'].to_json,
    cover_image_url: 'https://images.unsplash.com/photo-1514565131-fce0801e5785'
  },
  {
    name: '武汉周边木兰天池',
    city_id: wuhan.id,
    slug: nil,
    duration_days: 1,
    distance_km: 80,
    category: 'classic',
    description: '前往黄陂区木兰天池国家森林公园，享受大自然的清新空气，爬山玩水，远离城市喧嚣。',
    price_from: 550.0,
    highlights: ['木兰天池', '森林氧吧', '瀑布景观', '山水风光'].to_json,
    cover_image_url: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4'
  }
]

CharterRoute.insert_all(routes_data)
charter_routes = CharterRoute.by_city(wuhan.id)


# 4. 创建路线-景点关联
route_attractions_data = []

# 路线1: 武汉经典一日游
route1 = charter_routes.find_by(name: '武汉经典一日游')
if route1
  [
    [attractions['黄鹤楼'].id, 1],
    [attractions['武汉大学'].id, 2],
    [attractions['湖北省博物馆'].id, 3],
    [attractions['东湖听涛景区'].id, 4],
    [attractions['户部巷'].id, 5]
  ].each do |attraction_id, position|
    route_attractions_data << {
      charter_route_id: route1.id,
      attraction_id: attraction_id,
      position: position
    }
  end
end

# 路线2: 武汉精华四景
route2 = charter_routes.find_by(name: '武汉精华四景')
if route2
  [
    [attractions['黄鹤楼'].id, 1],
    [attractions['武汉大学'].id, 2],
    [attractions['湖北省博物馆'].id, 3],
    [attractions['东湖听涛景区'].id, 4]
  ].each do |attraction_id, position|
    route_attractions_data << {
      charter_route_id: route2.id,
      attraction_id: attraction_id,
      position: position
    }
  end
end

# 路线3: 武汉文化深度游
route3 = charter_routes.find_by(name: '武汉文化深度游')
if route3
  [
    [attractions['黄鹤楼'].id, 1],
    [attractions['古德寺'].id, 2],
    [attractions['晴川阁'].id, 3],
    [attractions['湖北省博物馆'].id, 4],
    [attractions['东湖听涛景区'].id, 5]
  ].each do |attraction_id, position|
    route_attractions_data << {
      charter_route_id: route3.id,
      attraction_id: attraction_id,
      position: position
    }
  end
end

# 路线4: 武汉美食文化游
route4 = charter_routes.find_by(name: '武汉美食文化游')
if route4
  [
    [attractions['黄鹤楼'].id, 1],
    [attractions['户部巷'].id, 2],
    [attractions['长江游船'].id, 3]
  ].each do |attraction_id, position|
    route_attractions_data << {
      charter_route_id: route4.id,
      attraction_id: attraction_id,
      position: position
    }
  end
end

# 路线5: 武汉夜游江城
route5 = charter_routes.find_by(name: '武汉夜游江城')
if route5
  [
    [attractions['长江游船'].id, 1]
  ].each do |attraction_id, position|
    route_attractions_data << {
      charter_route_id: route5.id,
      attraction_id: attraction_id,
      position: position
    }
  end
end

# 路线6: 武汉周边木兰天池
route6 = charter_routes.find_by(name: '武汉周边木兰天池')
if route6
  [
    [attractions['木兰天池'].id, 1]
  ].each do |attraction_id, position|
    route_attractions_data << {
      charter_route_id: route6.id,
      attraction_id: attraction_id,
      position: position
    }
  end
end

RouteAttraction.insert_all(route_attractions_data) if route_attractions_data.any?


puts ""
puts "数据统计："
puts "  - 城市: 1个 (#{wuhan.name})"
puts "  - 景点: #{attractions.size}个"
puts "  - 车型: #{vehicle_types.size}种"
puts "  - 路线: #{charter_routes.size}条"
puts "  - 路线景点关联: #{route_attractions_data.size}条"
