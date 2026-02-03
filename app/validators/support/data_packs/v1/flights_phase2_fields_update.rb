# frozen_string_literal: true

# flights_phase2_fields_update 数据包
# 为Phase 2验证器添加缺失的航班字段
#
# 用途：
# - 为现有航班数据添加新字段（baggage_allowance, refund_policy, meal_service, mileage_accrual, is_direct, stops）
#
# 加载方式：
# rake validator:reset_baseline

puts "正在更新航班数据的Phase 2字段..."

# 批量更新所有data_version=0的航班
flights = Flight.where(data_version: 0).to_a

puts "  找到 #{flights.count} 个航班需要更新"

flights.each_slice(100) do |batch|
  updates = batch.map do |flight|
    # 根据航空公司和价格设置字段
    is_major_airline = ['国航', '东航', '南航', '海航'].any? { |name| flight.airline&.include?(name) }
    is_premium = flight.price.to_f >= 1500
    
    {
      id: flight.id,
      baggage_allowance: is_premium ? '托运行李2件(每件23kg)' : '托运行李1件(23kg)',
      refund_policy: is_premium ? '可免费改签，退票收5%手续费' : '改签收50元，退票收10%手续费',
      meal_service: is_premium ? '含飞机餐+饮料' : '含简餐',
      mileage_accrual: is_major_airline ? '可累积里程' : '不可累积',
      is_direct: flight.stops.nil? ? true : (flight.stops == 0),
      stops: flight.stops || 0
    }
  end
  
  Flight.upsert_all(updates, unique_by: :id)
end

puts "✓ 航班字段更新完成"
