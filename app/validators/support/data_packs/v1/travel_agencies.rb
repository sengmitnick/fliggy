# frozen_string_literal: true

# travel_agencies_v1 数据包
# 为验证器 V327-V348 提供旅行社数据
#
# 用途：
# - 提供全国各地区的旅行社基础数据
# - 覆盖华北、华东、华南、西南、西北等主要区域
#
# 加载方式：
# rake validator:reset_baseline

puts "正在加载 travel_agencies_v1 数据包..."

timestamp = Time.current

travel_agencies_data = [
  # V327: 新疆薰衣草旅行社
  {
    name: "新疆伊犁花海旅行社",
    description: "专注新疆花期主题游，薰衣草、向日葵赏花专家。提供伊犁地区全程包车、导游、住宿一站式服务。",
    logo_url: nil,
    rating: 4.8,
    sales_count: 1280,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # V328-V330: 各区域赏花旅行社
  {
    name: "云南罗平油菜花旅行社",
    description: "云南罗平油菜花节指定接待旅行社，提供油菜花海摄影团、亲子赏花团等特色线路。",
    logo_url: nil,
    rating: 4.6,
    sales_count: 980,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  {
    name: "婺源春季赏花旅行社",
    description: "婺源油菜花、梯田摄影专家，提供古村落+花海深度游线路，专业摄影指导服务。",
    logo_url: nil,
    rating: 4.7,
    sales_count: 1150,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # V331-V335: 各省市主要旅行社
  {
    name: "北京环球国际旅行社",
    description: "北京老牌旅行社，专注出境游、国内高端定制游，拥有30年服务经验。",
    logo_url: nil,
    rating: 4.5,
    sales_count: 5200,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  {
    name: "上海春秋国际旅行社",
    description: "上海知名旅行社，提供机票+酒店自由行、跟团游、邮轮游等全品类旅游产品。",
    logo_url: nil,
    rating: 4.4,
    sales_count: 6800,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  {
    name: "广东南湖国际旅行社",
    description: "广东省最大旅行社之一，覆盖港澳游、东南亚游、国内游等全线路。",
    logo_url: nil,
    rating: 4.6,
    sales_count: 4500,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # V336-V340: 西南、西北区域旅行社
  {
    name: "成都中国旅行社",
    description: "四川本地知名旅行社，专注川西、西藏、云南线路，提供专业高原旅游服务。",
    logo_url: nil,
    rating: 4.7,
    sales_count: 3200,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  {
    name: "丽江古城国际旅行社",
    description: "丽江本地旅行社，专注云南深度游、茶马古道、香格里拉线路。",
    logo_url: nil,
    rating: 4.5,
    sales_count: 2100,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  {
    name: "西安丝绸之路旅行社",
    description: "陕西本地旅行社，专注丝绸之路文化游、西北大环线、敦煌专线。",
    logo_url: nil,
    rating: 4.6,
    sales_count: 1800,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # V341-V345: 华东、华中旅行社
  {
    name: "杭州西湖国际旅行社",
    description: "杭州本地旅行社，专注江南水乡游、杭州周边游、黄山线路。",
    logo_url: nil,
    rating: 4.5,
    sales_count: 2600,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  {
    name: "苏州园林旅行社",
    description: "苏州本地旅行社，专注苏州园林游、江南古镇游、上海周边游。",
    logo_url: nil,
    rating: 4.4,
    sales_count: 1900,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  {
    name: "武汉长江旅行社",
    description: "武汉本地旅行社，专注长江三峡游、湖北神农架、恩施大峡谷线路。",
    logo_url: nil,
    rating: 4.5,
    sales_count: 2200,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  # V346-V348: 东北、华南旅行社
  {
    name: "哈尔滨冰雪旅行社",
    description: "哈尔滨本地旅行社，专注冰雪旅游、雪乡线路、东北民俗游。",
    logo_url: nil,
    rating: 4.6,
    sales_count: 1500,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  },
  
  {
    name: "三亚海岛度假旅行社",
    description: "三亚本地旅行社，专注海岛度假游、潜水、游艇、海鲜美食线路。",
    logo_url: nil,
    rating: 4.7,
    sales_count: 3800,
    is_verified: true,
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }
]

TravelAgency.insert_all(travel_agencies_data)

puts "✓ travel_agencies_v1 数据包加载完成（#{travel_agencies_data.size}家旅行社）"
