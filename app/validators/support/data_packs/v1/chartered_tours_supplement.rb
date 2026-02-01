# frozen_string_literal: true

# 包车游补充数据包 v1 - 添加上海包车路线
# 补充上海地区的包车游路线和景点数据
#
# 用途：
# - 支持 v107 验证器（上海定制游预订）
#
# 加载方式：
# rake validator:reset_baseline

require_relative '../../../../../app/helpers/image_seed_helper'

puts "正在加载 chartered_tours_supplement_v1 数据包（上海包车路线）..."

# 确保上海城市存在
shanghai = City.find_or_create_by!(name: '上海') do |city|
  city.pinyin = 'shanghai'
  city.region = '华东'
  city.is_hot = true
  city.data_version = 0
end

# 创建上海景点
shanghai_attractions_data = [
  {
    name: '外滩',
    city: '上海',
    province: '上海',
    district: '黄浦区',
    address: '黄浦区中山东一路',
    latitude: 31.2400,
    longitude: 121.4900,
    rating: 4.7,
    review_count: 25000,
    opening_hours: '全天开放',
    phone: '021-63505500',
    description: '上海的标志性景点，万国建筑博览群，浦江两岸风光尽收眼底。',
    data_version: 0
  },
  {
    name: '东方明珠',
    city: '上海',
    province: '上海',
    district: '浦东新区',
    address: '浦东新区陆家嘴世纪大道1号',
    latitude: 31.2397,
    longitude: 121.4997,
    rating: 4.5,
    review_count: 18000,
    opening_hours: '08:00-22:00',
    phone: '021-58791888',
    description: '上海地标建筑，登塔可360度俯瞰上海全景。',
    data_version: 0
  },
  {
    name: '豫园',
    city: '上海',
    province: '上海',
    district: '黄浦区',
    address: '黄浦区安仁街137号',
    latitude: 31.2277,
    longitude: 121.4920,
    rating: 4.4,
    review_count: 12000,
    opening_hours: '08:30-17:30',
    phone: '021-63260830',
    description: '江南古典园林，明代私家花园，体验老上海风情。',
    data_version: 0
  },
  {
    name: '南京路步行街',
    city: '上海',
    province: '上海',
    district: '黄浦区',
    address: '黄浦区南京东路',
    latitude: 31.2353,
    longitude: 121.4808,
    rating: 4.3,
    review_count: 20000,
    opening_hours: '全天开放',
    phone: '021-63515388',
    description: '中国最繁华的商业街之一，购物美食的天堂。',
    data_version: 0
  },
  {
    name: '田子坊',
    city: '上海',
    province: '上海',
    district: '黄浦区',
    address: '黄浦区泰康路210弄',
    latitude: 31.2112,
    longitude: 121.4673,
    rating: 4.2,
    review_count: 8500,
    opening_hours: '10:00-22:00',
    phone: '021-54657531',
    description: '上海特色石库门里弄，艺术创意聚集地。',
    data_version: 0
  }
]

Attraction.insert_all(shanghai_attractions_data)
shanghai_attractions = Attraction.where(city: '上海', data_version: 0).index_by(&:name)

# 创建包车路线（包括经典路线）
shanghai_routes_data = [
  {
    name: '上海经典一日游',
    city_id: shanghai.id,
    duration_days: 1,
    distance_km: 40,
    category: 'classic',  # 经典路线
    description: '游览上海最著名的景点：外滩、东方明珠、豫园、南京路步行街，深度体验海派文化。',
    price_from: 380.0,
    highlights: ['外滩万国建筑', '东方明珠登塔', '豫园古典园林', '南京路购物', '品尝本帮菜'].to_json,
    cover_image_url: ImageSeedHelper.random_image_from_category(:tours),
    data_version: 0
  },
  {
    name: '上海精华四景',
    city_id: shanghai.id,
    duration_days: 1,
    distance_km: 35,
    category: 'hot',  # 热门路线
    description: '精选上海四大核心景点，适合时间有限的游客快速打卡。',
    price_from: 350.0,
    highlights: ['外滩夜景', '东方明珠', '田子坊', '豫园'].to_json,
    cover_image_url: ImageSeedHelper.random_image_from_category(:tours),
    data_version: 0
  }
]

CharterRoute.insert_all(shanghai_routes_data)
routes = CharterRoute.where(city_id: shanghai.id, data_version: 0).index_by(&:name)

# 为路线关联景点
route_attractions_data = []

# 上海经典一日游路线景点
classic_route = routes['上海经典一日游']
if classic_route
  ['外滩', '东方明珠', '豫园', '南京路步行街'].each_with_index do |attr_name, index|
    attraction = shanghai_attractions[attr_name]
    if attraction
      route_attractions_data << {
        charter_route_id: classic_route.id,
        attraction_id: attraction.id,
        position: index + 1,
        data_version: 0
      }
    end
  end
end

# 上海精华四景路线景点
hot_route = routes['上海精华四景']
if hot_route
  ['外滩', '东方明珠', '田子坊', '豫园'].each_with_index do |attr_name, index|
    attraction = shanghai_attractions[attr_name]
    if attraction
      route_attractions_data << {
        charter_route_id: hot_route.id,
        attraction_id: attraction.id,
        position: index + 1,
        data_version: 0
      }
    end
  end
end

RouteAttraction.insert_all(route_attractions_data) if route_attractions_data.any?

puts "✓ 数据包加载完成"
puts "  - 创建上海景点: #{shanghai_attractions.size} 个"
puts "  - 创建包车路线: #{routes.size} 条"
puts "  - 关联景点数: #{route_attractions_data.size} 个"
