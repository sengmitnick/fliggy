# frozen_string_literal: true

# z_flight_offers_v1 数据包
# 为所有航班统一生成 FlightOffer
#
# 用途：
# - 在所有航班数据包（flights.rb, premium_flights.rb, phase2_extended_scenarios.rb等）加载完成后
# - 统一为没有FlightOffer的航班生成4种套餐类型
#
# 加载方式：
# rake validator:reset_baseline
#
# 注意：
# - 使用 z_ 前缀确保此文件在所有其他数据包之后加载
# - 避免在各个航班数据包中重复生成FlightOffer的逻辑

puts "正在加载 z_flight_offers_v1 数据包..."

require_relative '../../../../../app/helpers/image_seed_helper'

# 查找所有没有FlightOffer的航班
flights_without_offers = Flight.where(data_version: 0)
  .left_joins(:flight_offers)
  .where(flight_offers: { id: nil })
  .to_a

puts "   找到 #{flights_without_offers.count} 个航班需要生成套餐"

if flights_without_offers.any?
  all_offers = []
  timestamp = Time.current
  
  flights_without_offers.each do |flight|
    base_price = flight.price.to_f
    
    # Package 1: 超值精选 (Best Value)
    all_offers << {
      flight_id: flight.id,
      provider_name: '超值精选',
      offer_type: 'featured',
      price: base_price,
      original_price: base_price + 42,
      cashback_amount: 0,
      discount_items: ['无免费托运行李'],
      services: ['退改¥92起', '经济舱', '仅全额电子发票'],
      tags: ['含合餐权益', '手提行李7KG/尺寸20'],
      baggage_info: '手提行李7KG/尺寸20',
      meal_included: false,
      refund_policy: '退改¥92起',
      is_featured: true,
      display_order: 0,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    # Package 2: 选座无忧 (Seat Selection)
    all_offers << {
      flight_id: flight.id,
      provider_name: '选座无忧',
      offer_type: 'standard',
      price: base_price + 8,
      original_price: base_price + 50,
      cashback_amount: 24,
      discount_items: ['无免费托运行李'],
      services: ['退改¥92起', '经济舱', '仅全额电子发票'],
      tags: ['含合餐权益', '手提行李7KG/尺寸20'],
      baggage_info: '含合餐权益',
      meal_included: false,
      refund_policy: '手提行李7KG/尺寸20',
      is_featured: false,
      display_order: 1,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    # Package 3: 返现礼遇 (Cashback Package)
    all_offers << {
      flight_id: flight.id,
      provider_name: '返现礼遇',
      offer_type: 'cashback',
      price: base_price + 120,
      original_price: base_price + 220,
      cashback_amount: 90,
      discount_items: ['无免费托运行李'],
      services: ['经济舱', '全额电子发票'],
      tags: [
        '返¥520里程礼包',
        '手提行李7KG/尺寸20',
        '成人可订返现',
        '仅限预定电子票'
      ],
      baggage_info: '返¥520里程礼包',
      meal_included: false,
      refund_policy: '手提行李7KG/尺寸20',
      is_featured: false,
      display_order: 2,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
    
    # Package 4: 家庭好选 (Family Choice)
    all_offers << {
      flight_id: flight.id,
      provider_name: '家庭好选',
      offer_type: 'family',
      price: base_price + 5,
      original_price: base_price + 40,
      cashback_amount: 20,
      discount_items: ['结果送出票'],
      services: ['经济舱', '1.7折'],
      tags: [
        '结果送出票',
        '结果提交'
      ],
      baggage_info: '结果送出票',
      meal_included: false,
      refund_policy: '结果提交',
      is_featured: false,
      display_order: 3,
      data_version: 0,
      created_at: timestamp,
      updated_at: timestamp
    }
  end
  
  FlightOffer.insert_all(all_offers)
  puts "   ✓ 已生成 #{all_offers.count} 个套餐（为 #{flights_without_offers.count} 个航班）"
else
  puts "   ℹ️  所有航班已有套餐，跳过"
end

puts "\n✅ z_flight_offers_v1 数据包加载完成！"
