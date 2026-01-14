# 境外上网服务种子数据
puts "Creating internet services data..."

# 清理现有数据
InternetSimCard.destroy_all
InternetDataPlan.destroy_all
InternetWifi.destroy_all

# 境外电话卡数据
sim_cards_data = [
  {
    name: "插卡即用",
    region: "中国香港",
    validity_days: 1,
    data_limit: "5GB/天",
    price: 9.9,
    features: ["虚商卡", "价格优", "5G网络", "赠 卡针 + 电子地图", "香港24小时制"],
    sales_count: 10000,
    shop_name: "深圳游小匠旅游专营店"
  },
  {
    name: "插卡即用",
    region: "中国香港",
    validity_days: 1,
    data_limit: "5GB/天",
    price: 11.5,
    features: ["虚商卡", "价格优", "5G网络", "赠 卡针 + 电子地图", "港澳24小时制"],
    sales_count: 10000,
    shop_name: "深圳游小匠旅游专营店"
  },
  {
    name: "插卡即用",
    region: "中国香港",
    validity_days: 1,
    data_limit: "5GB/天",
    price: 12.5,
    features: ["虚商卡", "价格优", "5G网络", "赠 卡针 + 电子地图", "含 转换插头", "港澳24小时制"],
    sales_count: 200,
    shop_name: "深圳游小匠旅游专营店"
  },
  {
    name: "插卡即用",
    region: "中国香港",
    validity_days: 2,
    data_limit: "3GB/天",
    price: 18.0,
    features: ["虚商卡", "价格优", "5G网络", "赠 卡针 + 电子地图", "香港24小时制"],
    sales_count: 5000,
    shop_name: "深圳游小匠旅游专营店"
  }
]

sim_cards_data.each do |data|
  InternetSimCard.create!(data)
end

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
    description: "4G/5G漫游，网速更快且支持境内APP。当日用量达到0.4GB将降速至384kbps，次日0时恢复（以北京时间为准）"
  },
  {
    name: "香港3天漫游包+20元话费券",
    region: "中国香港",
    validity_days: 3,
    data_limit: "0.4GB/天",
    price: 88,
    phone_number: "180 2712 8600",
    carrier: "中国电信",
    description: "4G/5G漫游，网速更快且支持境内APP"
  },
  {
    name: "香港5天漫游包+20元话费券",
    region: "中国香港",
    validity_days: 5,
    data_limit: "0.4GB/天",
    price: 128,
    phone_number: "180 2712 8600",
    carrier: "中国电信",
    description: "4G/5G漫游，网速更快且支持境内APP"
  },
  {
    name: "香港7天漫游包+20元话费券",
    region: "中国香港",
    validity_days: 7,
    data_limit: "0.4GB/天",
    price: 168,
    phone_number: "180 2712 8600",
    carrier: "中国电信",
    description: "4G/5G漫游，网速更快且支持境内APP"
  },
  {
    name: "香港5天漫游包",
    region: "中国香港",
    validity_days: 5,
    data_limit: "0.4GB/天",
    price: 108,
    phone_number: "180 2712 8600",
    carrier: "中国电信",
    description: "4G/5G漫游，网速更快且支持境内APP"
  }
]

data_plans_data.each do |data|
  InternetDataPlan.create!(data)
end

# 随身WiFi数据
wifis_data = [
  {
    name: "4G网·无限量",
    region: "中国香港",
    network_type: "4G",
    data_limit: "无限量",
    daily_price: 17,
    features: ["多网覆盖", "信号稳定", "多人共享"],
    sales_count: 5000,
    shop_name: "漫游超人通讯旗舰店",
    deposit: 500
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
    deposit: 500
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
    deposit: 500
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
    deposit: 500
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
    deposit: 500
  }
]

wifis_data.each do |data|
  InternetWifi.create!(data)
end

puts "Created #{InternetSimCard.count} sim cards"
puts "Created #{InternetDataPlan.count} data plans"
puts "Created #{InternetWifi.count} wifi devices"
