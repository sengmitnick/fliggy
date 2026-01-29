# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例17: 预订明天上海任意酒店（入住1晚）
# 
# 任务描述:
#   Agent 需要在系统中搜索上海的酒店，
#   选择任意一家酒店并成功创建入住1晚的订单
# 
# 复杂度分析:
#   1. 需要搜索"上海"城市的酒店
#   2. 需要选择"明天"日期（理解相对日期）
#   3. 需要填写入住信息（入住1晚，离店日期为后天）
#   ❌ 不需要价格对比或评分筛选，任意酒店即可
# 
# 评分标准:
#   - 订单已创建 (30分)
#   - 城市正确（上海） (30分)
#   - 入住日期正确（明天入住，后天离店，共1晚）(40分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v017_book_any_hotel_shanghai_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V017BookAnyHotelShanghaiValidator < BaseValidator
  self.validator_id = 'v017_book_any_hotel_shanghai_validator'
  self.task_id = 'ab3c6f57-e4e4-4574-9806-25ed3c2ffa8f'
  self.title = '预订明天上海任意酒店（入住1晚）'
  self.description = '在上海搜索酒店，选择任意一家并完成明天入住1晚的预订'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    @city = '上海'
    @check_in_date = Date.current + 1.day  # 明天
    @nights = 1
    @check_out_date = @check_in_date + @nights.days
    
    # 查找可用酒店数量
    available_hotels = Hotel.where(city: @city, data_version: 0)
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订明天入住#{@city}的任意酒店（入住1晚）",
      city: @city,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      date_description: "入住：明天（#{@check_in_date.strftime('%Y年%m月%d日')}），离店：后天（#{@check_out_date.strftime('%Y年%m月%d日')}）",
      nights: @nights,
      hint: "系统中有多家酒店可选，选择任意一家即可",
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
    add_assertion "城市正确（上海）", weight: 30 do
      expect(@hotel_booking.hotel.city).to eq(@city),
        "城市错误。期望: #{@city}, 实际: #{@hotel_booking.hotel.city}"
    end
    
    # 断言3: 入住日期正确
    add_assertion "入住日期正确（明天）", weight: 20 do
      expect(@hotel_booking.check_in_date).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
    end
    
    # 断言4: 离店日期正确
    add_assertion "离店日期正确（后天，共1晚）", weight: 20 do
      expect(@hotel_booking.check_out_date).to eq(@check_out_date),
        "离店日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
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
    
    # 随机选择一家上海的酒店
    target_hotel = Hotel.where(city: @city, data_version: 0).sample
    
    # 选择一个房型
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
      nights: @nights,
      user_email: user.email
    }
  end
end