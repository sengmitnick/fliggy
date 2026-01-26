# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例20: 预订明天深圳酒店（入住2晚）
# 
# 任务描述:
#   Agent 需要在系统中搜索深圳的酒店，
#   选择任意一家酒店并成功创建入住2晚的订单
# 
# 复杂度分析:
#   1. 需要搜索"深圳"城市的酒店
#   2. 需要选择"明天"日期（理解相对日期）
#   3. 需要正确计算2晚的离店日期（明天+2天）
#   ❌ 重点验证多晚入住的日期计算，无其他筛选条件
# 
# 评分标准:
#   - 订单已创建 (30分)
#   - 城市正确（深圳） (20分)
#   - 入住日期正确（明天）(20分)
#   - 离店日期正确（大后天，共2晚）(30分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v020_book_hotel_shenzhen_two_nights_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V020BookHotelShenzhenTwoNightsValidator < BaseValidator
  self.validator_id = 'v020_book_hotel_shenzhen_two_nights_validator'
  self.title = '预订明天深圳酒店（入住2晚）'
  self.description = '搜索深圳的酒店，选择任意一家并完成明天入住2晚的预订'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    @city = '深圳'
    @check_in_date = Date.current + 1.day  # 明天
    @nights = 2
    @check_out_date = @check_in_date + @nights.days  # 大后天
    
    # 查找可用酒店数量
    available_hotels = Hotel.where(city: @city, data_version: 0)
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订明天入住#{@city}的酒店（入住2晚）",
      city: @city,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      date_description: "入住：明天（#{@check_in_date.strftime('%Y年%m月%d日')}），离店：大后天（#{@check_out_date.strftime('%Y年%m月%d日')}），共2晚",
      nights: @nights,
      hint: "系统中有多家酒店可选，选择任意一家即可，重点是正确计算2晚的离店日期",
      available_hotels_count: available_hotels.count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建
    add_assertion "订单已创建", weight: 30 do
      @hotel_booking = HotelBooking.order(created_at: :desc).first
      expect(@hotel_booking).not_to be_nil, "未找到任何酒店订单记录"
    end
    
    return unless @hotel_booking
    
    # 断言2: 城市正确
    add_assertion "城市正确（深圳）", weight: 20 do
      expect(@hotel_booking.hotel.city).to eq(@city),
        "城市错误。期望: #{@city}, 实际: #{@hotel_booking.hotel.city}"
    end
    
    # 断言3: 入住日期正确
    add_assertion "入住日期正确（明天）", weight: 20 do
      expect(@hotel_booking.check_in_date).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
    end
    
    # 断言4: 离店日期正确（核心评分项）
    add_assertion "离店日期正确（大后天，共2晚）", weight: 30 do
      expect(@hotel_booking.check_out_date).to eq(@check_out_date),
        "离店日期错误。期望: #{@check_out_date} (入住2晚), 实际: #{@hotel_booking.check_out_date}"
      
      # 额外验证：计算实际入住晚数
      actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
      expect(actual_nights).to eq(@nights),
        "入住晚数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
    end
  end
  
  private
  
  def execution_state_data
    {
      city: @city,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      nights: @nights
    }
  end
  
  def restore_from_state(data)
    @city = data['city']
    @check_in_date = Date.parse(data['check_in_date'])
    @check_out_date = Date.parse(data['check_out_date'])
    @nights = data['nights']
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 随机选择一家深圳的酒店
    target_hotel = Hotel.where(city: @city, data_version: 0).sample
    
    target_hotel_room = HotelRoom.where(hotel_id: target_hotel.id)
                                 .where(room_category: 'overnight')
                                 .order(:price)
                                 .first
    
    raise "未找到可用房型" unless target_hotel_room
    
    hotel_booking = HotelBooking.create!(
      hotel_id: target_hotel.id,
      hotel_room_id: target_hotel_room.id,
      user_id: user.id,
      check_in_date: @check_in_date,
      check_out_date: @check_out_date,
      rooms_count: 1,
      adults_count: 1,
      children_count: 0,
      total_price: target_hotel_room.price * @nights,
      payment_method: '花呗',
      status: 'pending',
      guest_name: user.email.split('@').first,
      guest_phone: '13800138000'
    )
    
    {
      action: 'create_hotel_booking',
      booking_id: hotel_booking.id,
      hotel_name: target_hotel.name,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      nights: @nights,
      user_email: user.email
    }
  end
end
