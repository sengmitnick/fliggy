# frozen_string_literal: true

# Transfer (接送机服务) 数据包 v1
# 
# 包含：
# - TransferPackage: 接送机套餐数据
# 
# 用途：
# - 为接送机服务验证器提供测试数据
# - 支持不同车型、价格的对比测试
# 
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 Transfer 数据包..."

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
    is_active: true
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
    is_active: true
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
    is_active: true
  },
  {
    name: '旅程约车',
    vehicle_category: 'economy_5',
    seats: 4,
    luggage: 2,
    wait_time: 60,
    refund_policy: '条件退',
    price: 82,
    original_price: 97,
    features: ['免费等60分钟', '条件退'],
    provider: '旅程约车',
    priority: 4,
    is_active: true
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
    is_active: true
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
    is_active: true
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
    is_active: true
  },
  {
    name: '伙力专车',
    vehicle_category: 'economy_7',
    seats: 6,
    luggage: 3,
    wait_time: 60,
    refund_policy: '条件退',
    price: 115,
    original_price: 135,
    features: ['免费等60分钟', '条件退', '大空间'],
    provider: '伙力专车',
    priority: 2,
    is_active: true
  }
]

# 使用 insert_all 批量插入
TransferPackage.insert_all(packages_data.map { |data| data.merge(data_version: 0) })

puts "✓ 数据包加载完成"
puts "  - TransferPackage: #{TransferPackage.where(data_version: 0).count} 条记录"
puts "  - 经济5座: #{TransferPackage.where(data_version: 0, vehicle_category: 'economy_5').count} 条"
puts "  - 舒适5座: #{TransferPackage.where(data_version: 0, vehicle_category: 'comfort_5').count} 条"
puts "  - 经济7座: #{TransferPackage.where(data_version: 0, vehicle_category: 'economy_7').count} 条"
puts "  - 最低价格: ¥#{TransferPackage.where(data_version: 0).minimum(:price)}"
