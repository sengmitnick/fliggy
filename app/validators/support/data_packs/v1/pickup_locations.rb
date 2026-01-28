# frozen_string_literal: true

# pickup_locations_v1 数据包
# 自取地点信息
#
# 用途：
# - 为WiFi租赁提供自取地点数据
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 pickup_locations_v1 数据包..."

# 清空旧数据
PickupLocation.delete_all

# 自取地点数据
PickupLocation.insert_all([
  # 南宁
  {
    city: '南宁',
    district: '市区',
    detail: '南宁市青秀区民族大道131号航洋国际城B座2楼',
    phone: '18617147510',
    business_hours: '24小时',
    notes: '(漫游超人)(北京时间)',
    is_active: true,
    data_version: 0
  },
  # 福州
  {
    city: '福州',
    district: '市区',
    detail: '福州市鼓楼区五四路国际大厦A座3楼',
    phone: '13800000001',
    business_hours: '9:00-21:00',
    notes: '(漫游超人)(北京时间)',
    is_active: true,
    data_version: 0
  },
  # 成都
  {
    city: '成都',
    district: '市区',
    detail: '成都市武侯区天府大道中段666号希顿国际广场',
    phone: '13800000002',
    business_hours: '8:00-22:00',
    notes: '(漫游超人)(北京时间)',
    is_active: true,
    data_version: 0
  },
  # 上海
  {
    city: '上海',
    district: '市区',
    detail: '上海市浦东新区陆家嘴环路1000号恒生银行大厦',
    phone: '13800000003',
    business_hours: '8:00-23:00',
    notes: '(漫游超人)(北京时间)',
    is_active: true,
    data_version: 0
  },
  # 济南
  {
    city: '济南',
    district: '市区',
    detail: '济南市历下区泉城路188号恒隆广场',
    phone: '13800000004',
    business_hours: '9:00-21:00',
    notes: '(漫游超人)(北京时间)',
    is_active: true,
    data_version: 0
  },
  # 香港 - 宝安机场T3 (安检区内)
  {
    city: '香港',
    district: '宝安机场T3',
    detail: "深圳宝安机场T3（安检区内）航站楼国际出发（海关内）进安检后306号登机口对面-【空港礼程 右侧 KJLife店】",
    phone: '19928804603',
    business_hours: '8:10-23:00',
    notes: '【需提前2小时下单】)(漫游超人)(北京时间)',
    is_active: true,
    data_version: 0
  },
  # 香港 - 宝安机场T3 (安检区外)
  {
    city: '香港',
    district: '宝安机场T3',
    detail: '深圳宝安机场T3（安检区外）航站楼4楼出发层E岛岛头狮子航空柜台',
    phone: '18129840096',
    business_hours: '6:00-22:30',
    notes: '【需提前2小时下单】)(漫游超人)(北京时间)',
    is_active: true,
    data_version: 0
  },
  # 沈阳
  {
    city: '沈阳',
    district: '市区',
    detail: '沈阳市沈河区青年大街288号华润大厦',
    phone: '13800000005',
    business_hours: '9:00-20:00',
    notes: '(漫游超人)(北京时间)',
    is_active: true,
    data_version: 0
  },
  # 厦门
  {
    city: '厦门',
    district: '市区',
    detail: '厦门市思明区鹭江道8号国际银行大厦',
    phone: '13800000006',
    business_hours: '9:00-21:00',
    notes: '(漫游超人)(北京时间)',
    is_active: true,
    data_version: 0
  }
])

puts "✓ 数据包加载完成：已添加 #{PickupLocation.count} 个自取地点"
