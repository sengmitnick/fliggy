# 境外上网服务种子数据
puts "Creating internet services data..."

timestamp = Time.current

# 境外电话卡数据
sim_cards_data = [
  # 日本地区 SIM卡（支持 BookJapanSimCardValidator）
  {
    name: "日本7天无限流量卡",
    region: "日本",
    validity_days: 7,
    data_limit: "无限流量",
    price: 68.0,
    features: ["4G/5G网络", "热点分享", "插卡即用"],
    sales_count: 15000,
    shop_name: "日本通信专营店",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "日本7天大流量卡",
    region: "日本",
    validity_days: 7,
    data_limit: "无限流量不降速",
    price: 88.0,
    features: ["5G网络", "真无限", "热点分享"],
    sales_count: 12000,
    shop_name: "日本通信专营店",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "日本5天流量卡",
    region: "日本",
    validity_days: 5,
    data_limit: "10GB/天",
    price: 45.0,
    features: ["4G网络", "高速流量"],
    sales_count: 8000,
    shop_name: "日本通信专营店",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 香港地区 SIM卡
  {
    name: "插卡即用",
    region: "中国香港",
    validity_days: 1,
    data_limit: "5GB/天",
    price: 9.9,
    features: ["虚商卡", "价格优", "5G网络", "赠 卡针 + 电子地图", "香港24小时制"],
    sales_count: 10000,
    shop_name: "深圳游小匠旅游专营店",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "插卡即用",
    region: "中国香港",
    validity_days: 1,
    data_limit: "5GB/天",
    price: 11.5,
    features: ["虚商卡", "价格优", "5G网络", "赠 卡针 + 电子地图", "港澳24小时制"],
    sales_count: 10000,
    shop_name: "深圳游小匠旅游专营店",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "插卡即用",
    region: "中国香港",
    validity_days: 1,
    data_limit: "5GB/天",
    price: 12.5,
    features: ["虚商卡", "价格优", "5G网络", "赠 卡针 + 电子地图", "含 转换插头", "港澳24小时制"],
    sales_count: 200,
    shop_name: "深圳游小匠旅游专营店",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "插卡即用",
    region: "中国香港",
    validity_days: 2,
    data_limit: "3GB/天",
    price: 18.0,
    features: ["虚商卡", "价格优", "5G网络", "赠 卡针 + 电子地图", "香港24小时制"],
    sales_count: 5000,
    shop_name: "深圳游小匠旅游专营店",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

# 批量插入电话卡
InternetSimCard.insert_all(sim_cards_data) if sim_cards_data.any?

# 境外流量包数据
data_plans_data = [
  {
    name: "香港1天漫游包+10元话费券",
    region: "中国香港",
    validity_days: 1,
    data_limit: "0.4GB/天",
    price: 35,
    phone_number: "180 2712 8600",
    carrier: "中国电信",
    description: "4G/5G漫游，网速更快且支持境内APP。当日用量达到0.4GB将降速至384kbps，次日0时恢复（以北京时间为准）",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "香港3天漫游包+20元话费券",
    region: "中国香港",
    validity_days: 3,
    data_limit: "0.4GB/天",
    price: 88,
    phone_number: "180 2712 8600",
    carrier: "中国电信",
    description: "4G/5G漫游，网速更快且支持境内APP",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "香港5天漫游包+20元话费券",
    region: "中国香港",
    validity_days: 5,
    data_limit: "0.4GB/天",
    price: 128,
    phone_number: "180 2712 8600",
    carrier: "中国电信",
    description: "4G/5G漫游，网速更快且支持境内APP",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "香港7天漫游包+20元话费券",
    region: "中国香港",
    validity_days: 7,
    data_limit: "0.4GB/天",
    price: 168,
    phone_number: "180 2712 8600",
    carrier: "中国电信",
    description: "4G/5G漫游，网速更快且支持境内APP",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "香港5天漫游包",
    region: "中国香港",
    validity_days: 5,
    data_limit: "0.4GB/天",
    price: 108,
    phone_number: "180 2712 8600",
    carrier: "中国电信",
    description: "4G/5G漫游，网速更快且支持境内APP",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

# 批量插入流量包
InternetDataPlan.insert_all(data_plans_data) if data_plans_data.any?

# 随身WiFi数据
wifis_data = [
  # 欧洲多国覆盖WiFi（支持 SearchMultiCountryWifiValidator）
  {
    name: "欧洲8国通用WiFi",
    region: "欧洲8国通用",
    network_type: "4G",
    data_limit: "无限量",
    daily_price: 25,
    features: ["8国覆盖", "无限流量", "多人共享", "免押金"],
    sales_count: 8000,
    shop_name: "欧洲漫游专营店",
    deposit: 0,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "欧洲6国通用WiFi·5G高速",
    region: "欧洲6国通用",
    network_type: "5G",
    data_limit: "无限量",
    daily_price: 35,
    features: ["6国覆盖", "5G网络", "多人共享", "含充电宝"],
    sales_count: 6000,
    shop_name: "欧洲漫游专营店",
    deposit: 500,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "欧洲10国通用WiFi·豪华版",
    region: "欧洲10国通用",
    network_type: "4G",
    data_limit: "无限量",
    daily_price: 30,
    features: ["10国覆盖", "无限流量", "多人共享", "含转换插头"],
    sales_count: 5000,
    shop_name: "欧洲漫游专营店",
    deposit: 500,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "欧洲5国通用WiFi",
    region: "欧洲5国通用",
    network_type: "4G",
    data_limit: "无限量",
    daily_price: 20,
    features: ["5国覆盖", "无限流量", "多人共享"],
    sales_count: 7000,
    shop_name: "欧洲漫游专营店",
    deposit: 500,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  # 香港地区WiFi
  {
    name: "4G网·无限量",
    region: "中国香港",
    network_type: "4G",
    data_limit: "无限量",
    daily_price: 17,
    features: ["多网覆盖", "信号稳定", "多人共享"],
    sales_count: 5000,
    shop_name: "漫游超人通讯旗舰店",
    deposit: 500,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "5G网·无限量",
    region: "中国香港",
    network_type: "5G",
    data_limit: "无限量",
    daily_price: 35,
    features: ["多网覆盖", "信号稳定", "多人共享", "5G高速"],
    sales_count: 3000,
    shop_name: "漫游超人通讯旗舰店",
    deposit: 500,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "5G网·无限量·配转换插头",
    region: "中国香港",
    network_type: "5G",
    data_limit: "无限量",
    daily_price: 37,
    features: ["多网覆盖", "信号稳定", "多人共享", "5G高速", "含转换插头"],
    sales_count: 2000,
    shop_name: "漫游超人通讯旗舰店",
    deposit: 500,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "4G网·无限量·配转换插头",
    region: "中国香港",
    network_type: "4G",
    data_limit: "无限量",
    daily_price: 21,
    features: ["多网覆盖", "信号稳定", "多人共享", "含转换插头"],
    sales_count: 1500,
    shop_name: "漫游超人通讯旗舰店",
    deposit: 500,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  {
    name: "4G网·500MB/天·用完即止",
    region: "中国香港",
    network_type: "4G",
    data_limit: "500MB/天",
    daily_price: 13,
    features: ["多网覆盖", "信号稳定", "多人共享"],
    sales_count: 1000,
    shop_name: "漫游超人通讯旗舰店",
    deposit: 500,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

# 批量插入WiFi设备
InternetWifi.insert_all(wifis_data) if wifis_data.any?

puts "Created #{InternetSimCard.count} sim cards"
puts "Created #{InternetDataPlan.count} data plans"
puts "Created #{InternetWifi.count} wifi devices"
