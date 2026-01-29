# frozen_string_literal: true

# Transfer (接送机服务) 数据包 v1
# 
# 包含：
# - TransferPackage: 接送机套餐数据
# - TransferLocation: 接送机地点数据（机场、火车站等）
# 
# 用途：
# - 为接送机服务验证器提供测试数据
# - 支持不同车型、价格的对比测试
# - 提供独立的接送机地点数据，不依赖租车模块
# 
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 Transfer 数据包..."

# 创建时间戳（用于 insert_all）
timestamp = Time.current

# 创建接送机地点数据
locations_data = [
  # 北京
  { city: '北京', name: '首都国际机场T2航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '北京', name: '首都国际机场T3航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '北京', name: '大兴国际机场综合服务楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '北京', name: '北京南站北广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '北京', name: '北京西站南广场停车楼', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '北京', name: '朝阳门CBD接送服务点', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  { city: '北京', name: '中关村科技园接送服务站', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  { city: '北京', name: '三里屯太古里接送服务站', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  
  # 上海
  { city: '上海', name: '虹桥国际机场T2航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '上海', name: '浦东国际机场T1航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '上海', name: '浦东国际机场T2航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '上海', name: '上海虹桥站西广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '上海', name: '上海虹桥站南广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '上海', name: '上海南站南广场停车场', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '上海', name: '陆家嘴金融区接送服务点', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  { city: '上海', name: '徐家汇商圈接送服务点', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  { city: '上海', name: '人民广场接送服务站', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  
  # 广州
  { city: '广州', name: '白云国际机场T1航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '广州', name: '白云国际机场T2航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '广州', name: '广州南站东广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '广州', name: '广州东站南广场停车场', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '广州', name: '珠江新城CBD接送服务站', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  { city: '广州', name: '琶洲会展中心接送服务点', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  
  # 深圳
  { city: '深圳', name: '宝安国际机场T3航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '深圳', name: '深圳北站西广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '深圳', name: '深圳北站东广场停车场', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '深圳', name: '深圳站罗湖口岸接送服务点', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '深圳', name: '福田中心区会展中心接送服务点', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  { city: '深圳', name: '南山科技园接送服务点', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  
  # 成都
  { city: '成都', name: '双流国际机场T1航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '成都', name: '双流国际机场T2航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '成都', name: '成都东站东广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '成都', name: '成都南站南广场停车场', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '成都', name: '春熙路太古里接送服务站', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  { city: '成都', name: '高新区环球中心接送服务点', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  
  # 杭州
  { city: '杭州', name: '萧山国际机场T3航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '杭州', name: '杭州东站东广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '杭州', name: '杭州站南广场停车场', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '杭州', name: '武林广场接送服务站', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  { city: '杭州', name: '钱江新城CBD接送服务点', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  
  # 重庆
  { city: '重庆', name: '江北国际机场T3航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '重庆', name: '重庆北站北广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '重庆', name: '重庆西站西广场停车场', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '重庆', name: '解放碑商圈接送服务站', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  { city: '重庆', name: '观音桥商圈接送服务点', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  
  # 西安
  { city: '西安', name: '咸阳国际机场T3航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '西安', name: '西安北站北广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '西安', name: '西安站南广场停车场', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '西安', name: '钟楼商圈接送服务站', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  
  # 南京
  { city: '南京', name: '禄口国际机场T2航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '南京', name: '南京南站南广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '南京', name: '南京站北广场停车场', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '南京', name: '新街口商圈接送服务站', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  
  # 武汉
  { city: '武汉', name: '天河国际机场T3', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '武汉', name: '武汉站东广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '武汉', name: '汉口站北广场接送服务点', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '武汉', name: '武昌站南广场停车场', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '武汉', name: '光谷广场接送服务站', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  
  # 三亚
  { city: '三亚', name: '凤凰国际机场航站楼', location_type: 'airport', created_at: timestamp, updated_at: timestamp },
  { city: '三亚', name: '三亚站东广场接送中心', location_type: 'train_station', created_at: timestamp, updated_at: timestamp },
  { city: '三亚', name: '三亚湾度假区接送服务站', location_type: 'other', created_at: timestamp, updated_at: timestamp },
  { city: '三亚', name: '大东海广场接送服务点', location_type: 'other', created_at: timestamp, updated_at: timestamp }
]

# 使用 insert_all 批量创建地点数据（符合项目规范）
TransferLocation.insert_all(locations_data)

# 创建接送机套餐数据
packages_data = [
  # 经济5座车型
  {
    name: '阳光出行',
    vehicle_category: 'economy_5',
    seats: 4,
    luggage: 2,
    wait_time: 60,
    refund_policy: '条件退',
    price: 80,
    original_price: 95,
    features: ['免费等60分钟', '条件退'],
    provider: '阳光出行',
    priority: 1,
    is_active: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: '伙力专车',
    vehicle_category: 'economy_5',
    seats: 4,
    luggage: 2,
    wait_time: 60,
    refund_policy: '条件退',
    price: 81,
    original_price: 96,
    features: ['免费等60分钟', '条件退'],
    provider: '伙力专车',
    priority: 2,
    is_active: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: '风韵出行',
    vehicle_category: 'economy_5',
    seats: 4,
    luggage: 2,
    wait_time: 60,
    refund_policy: '条件退',
    price: 82,
    original_price: 97,
    features: ['免费等60分钟', '条件退'],
    provider: '风韵出行',
    priority: 3,
    is_active: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: '旅程约车',
    vehicle_category: 'economy_5',
    seats: 4,
    luggage: 2,
    wait_time: 60,
    refund_policy: '随时退',
    price: 85,
    original_price: 100,
    features: ['免费等60分钟', '随时退'],
    provider: '旅程约车',
    priority: 4,
    is_active: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 舒适5座车型
  {
    name: '阳光出行',
    vehicle_category: 'comfort_5',
    seats: 4,
    luggage: 2,
    wait_time: 60,
    refund_policy: '条件退',
    price: 91,
    original_price: 106,
    features: ['免费等60分钟', '条件退'],
    provider: '阳光出行',
    priority: 1,
    is_active: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: '900游',
    vehicle_category: 'comfort_5',
    seats: 4,
    luggage: 2,
    wait_time: 60,
    refund_policy: '随时退·迟到赔',
    price: 92,
    original_price: 122,
    features: ['舒心行', '随时退·迟到赔', '免费等60分钟'],
    provider: '900游',
    priority: 2,
    is_active: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: '伙力专车',
    vehicle_category: 'comfort_5',
    seats: 4,
    luggage: 2,
    wait_time: 60,
    refund_policy: '随时退',
    price: 95,
    original_price: 110,
    features: ['免费等60分钟', '随时退'],
    provider: '伙力专车',
    priority: 3,
    is_active: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 经济7座车型
  {
    name: '阳光出行',
    vehicle_category: 'economy_7',
    seats: 6,
    luggage: 3,
    wait_time: 60,
    refund_policy: '条件退',
    price: 110,
    original_price: 130,
    features: ['免费等60分钟', '条件退', '大空间'],
    provider: '阳光出行',
    priority: 1,
    is_active: true,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: '伙力专车',
    vehicle_category: 'economy_7',
    seats: 6,
    luggage: 3,
    wait_time: 60,
    refund_policy: '随时退',
    price: 118,
    original_price: 138,
    features: ['免费等60分钟', '随时退', '大空间'],
    provider: '伙力专车',
    priority: 2,
    is_active: true,
    created_at: timestamp,
    updated_at: timestamp
  }
]

# 使用 insert_all 批量创建套餐数据（符合项目规范）
TransferPackage.insert_all(packages_data)

puts "✓ 数据包加载完成"
puts "  - TransferLocation: #{TransferLocation.where(data_version: 0).count} 条记录"
puts "    * 机场: #{TransferLocation.where(data_version: 0, location_type: 'airport').count} 个"
puts "    * 火车站: #{TransferLocation.where(data_version: 0, location_type: 'train_station').count} 个"
puts "    * 其他地点: #{TransferLocation.where(data_version: 0, location_type: 'other').count} 个"
puts "  - TransferPackage: #{TransferPackage.where(data_version: 0).count} 条记录"
puts "    * 经济5座: #{TransferPackage.where(data_version: 0, vehicle_category: 'economy_5').count} 条"
puts "    * 舒适5座: #{TransferPackage.where(data_version: 0, vehicle_category: 'comfort_5').count} 条"
puts "    * 经济7座: #{TransferPackage.where(data_version: 0, vehicle_category: 'economy_7').count} 条"
puts "  - 最低价格: ¥#{TransferPackage.where(data_version: 0).minimum(:price)}"
