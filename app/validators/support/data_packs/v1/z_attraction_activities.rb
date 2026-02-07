# frozen_string_literal: true

# z_attraction_activities_v1 数据包
# 补充景点活动数据（需要在 chartered_tours.rb 之后加载）
#
# 用途：
# - 为其他数据包创建的景点添加活动数据
# - 文件名以 z_ 开头确保在 chartered_tours.rb 之后加载
#
# 加载方式：
# rake validator:reset_baseline

require_relative '../../../../../app/helpers/image_seed_helper'

puts "正在加载 z_attraction_activities_v1 数据包..."

timestamp = Time.current
attraction_activities_data = []
tickets_data = []
ticket_suppliers_data = []

# 蜈支洲岛门票 (门票页面需要)
if (wuzhizhou_island = Attraction.find_by(name: '蜈支洲岛', data_version: 0))
  # 添加景区门票
  tickets_data << {
    attraction_id: wuzhizhou_island.id,
    name: "蜈支洲岛成人票",
    ticket_type: "adult",
    original_price: 168,
    current_price: 148,
    discount_info: "线上预订立减20元",
    requirements: "身高1.4米以上游客",
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
  
  tickets_data << {
    attraction_id: wuzhizhou_island.id,
    name: "蜈支洲岛儿童票",
    ticket_type: "child",
    original_price: 88,
    current_price: 78,
    discount_info: "儿童优惠票",
    requirements: "身高1.2米-1.4米儿童",
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
  attraction_activities_data << {
    attraction_id: wuzhizhou_island.id,
    name: "潜水教学+体验",
    activity_type: "水上运动",
    current_price: 380,
    description: "专业教练带领，适合初学者。包含潜水装备租赁、教学课程、潜水体验（深度6-12米）。每次限制最多4人，保障学习质量。",
    duration: "2-3小时",
    data_version: 0,
    created_at: timestamp,
    updated_at: timestamp
  }

  attraction_activities_data << {
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
if tickets_data.any?
  Ticket.insert_all(tickets_data)
  puts "✓ 创建了 #{tickets_data.size} 张门票"
end

# 为蜈支洲岛门票添加供应商关联
if (wuzhizhou_island = Attraction.find_by(name: '蜈支洲岛', data_version: 0))
  adult_ticket = Ticket.find_by(attraction_id: wuzhizhou_island.id, ticket_type: 'adult', data_version: 0)
  child_ticket = Ticket.find_by(attraction_id: wuzhizhou_island.id, ticket_type: 'child', data_version: 0)
  
  if adult_ticket && child_ticket
    # 成人票供应商
    ticket_suppliers_data << {
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
    
    ticket_suppliers_data << {
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
    
    ticket_suppliers_data << {
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
    ticket_suppliers_data << {
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
    
    ticket_suppliers_data << {
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
    
    ticket_suppliers_data << {
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

if ticket_suppliers_data.any?
  TicketSupplier.insert_all(ticket_suppliers_data)
  puts "✓ 创建了 #{ticket_suppliers_data.size} 个门票供应商关联"
end

# 批量插入景点内项目数据
if attraction_activities_data.any?
  AttractionActivity.insert_all(attraction_activities_data)
  puts "✓ 创建了 #{attraction_activities_data.size} 个景点内项目"
end

puts "✓ z_attraction_activities_v1 数据包加载完成"
