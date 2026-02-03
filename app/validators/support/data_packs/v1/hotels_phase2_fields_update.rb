# frozen_string_literal: true

# hotels_phase2_fields_update 数据包
# 为Phase 2验证器添加缺失的酒店字段
#
# 用途：
# - 为现有酒店数据添加新字段（facilities, cancellation_policy, price_per_night）
#
# 加载方式：
# rake validator:reset_baseline

puts "正在更新酒店数据的Phase 2字段..."

# 批量更新所有data_version=0的酒店
hotels = Hotel.where(data_version: 0).to_a

puts "  找到 #{hotels.count} 个酒店需要更新"

# 常见设施列表
facility_options = [
  ['WiFi', '停车场', '餐厅'],
  ['WiFi', '停车场', '健身房'],
  ['WiFi', '游泳池', '餐厅'],
  ['WiFi', '游泳池', '健身房', '餐厅'],
  ['WiFi', '停车场', '游泳池', '健身房', '餐厅', '会议室'],
  ['WiFi', '停车场', '早餐'],
  ['WiFi', '游泳池', '健身房', '早餐']
]

# 取消政策选项
cancellation_policies = [
  '入住前24小时免费取消',
  '入住前48小时免费取消',
  '入住前7天免费取消',
  '不可取消',
  '任何时间免费取消'
]

hotels.each_slice(100) do |batch|
  updates = batch.map do |hotel|
    # 根据价格和评分设置设施
    is_premium = hotel.price.to_f >= 500
    has_pool = is_premium || (hotel.rating.to_f >= 4.5)
    has_gym = is_premium
    has_breakfast = hotel.rating.to_f >= 4.0
    
    # 构建设施列表
    facilities_list = ['WiFi', '停车场']
    facilities_list << '游泳池' if has_pool
    facilities_list << '健身房' if has_gym
    facilities_list << '早餐' if has_breakfast
    facilities_list << '餐厅' if is_premium
    
    # 设置取消政策（高端酒店更宽松）
    cancellation = if is_premium
      '任何时间免费取消'
    elsif hotel.rating.to_f >= 4.0
      '入住前24小时免费取消'
    else
      '入住前48小时免费取消'
    end
    
    {
      id: hotel.id,
      facilities: facilities_list.join(', '),
      cancellation_policy: cancellation,
      price_per_night: hotel.price  # 使用现有的price字段作为price_per_night
    }
  end
  
  Hotel.upsert_all(updates, unique_by: :id)
end

puts "✓ 酒店字段更新完成"
