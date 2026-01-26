# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例21: 预订后天杭州商务酒店（类型：商务酒店）
# 
# 任务描述:
#   Agent 需要在系统中搜索杭州的酒店，
#   找到类型为"商务酒店"的酒店并成功创建入住1晚的订单
# 
# 复杂度分析:
#   1. 需要搜索"杭州"城市的酒店
#   2. 需要选择"后天"日期（理解相对日期）
#   3. 需要筛选类型为"商务酒店"的酒店
#   ❌ 不需要价格和评分对比，只要类型正确即可
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（杭州） (20分)
#   - 入住日期正确（后天）(20分)
#   - 酒店类型正确（商务酒店）(40分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v021_book_business_hotel_hangzhou_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V021BookBusinessHotelHangzhouValidator < BaseValidator
  self.validator_id = 'v021_book_business_hotel_hangzhou_validator'
  self.title = '预订后天杭州商务酒店'
  self.description = '搜索杭州的酒店，找到类型为"商务酒店"的酒店并完成后天入住1晚的预订'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    @city = '杭州'
    @brand = '商务酒店'  # 使用brand字段，不是hotel_type
    @check_in_date = Date.current + 2.days  # 后天
    @nights = 1
    @check_out_date = @check_in_date + @nights.days
    
    # 查找符合条件的酒店
    qualified_hotels = Hotel.where(
      city: @city,
      brand: @brand,
      data_version: 0
    )
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订后天入住#{@city}的#{@brand}（入住1晚）",
      city: @city,
      hotel_brand: @brand,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      date_description: "入住：后天（#{@check_in_date.strftime('%Y年%m月%d日')}）",
      nights: @nights,
      hint: "系统中有多家#{@brand}可选，选择类型正确的酒店即可",
      qualified_hotels_count: qualified_hotels.count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建
    add_assertion "订单已创建", weight: 20 do
      @hotel_booking = HotelBooking.order(created_at: :desc).first
      expect(@hotel_booking).not_to be_nil, "未找到任何酒店订单记录"
    end
    
    return unless @hotel_booking
    
    # 断言2: 城市正确
    add_assertion "城市正确（杭州）", weight: 20 do
      expect(@hotel_booking.hotel.city).to eq(@city),
        "城市错误。期望: #{@city}, 实际: #{@hotel_booking.hotel.city}"
    end
    
    # 断言3: 入住日期正确
    add_assertion "入住日期正确（后天）", weight: 20 do
      expect(@hotel_booking.check_in_date).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
    end
    
    # 断言4: 酒店类型正确（核心评分项）
    add_assertion "酒店品牌正确（#{@brand}）", weight: 40 do
      actual_brand = @hotel_booking.hotel.brand
      expect(actual_brand).to eq(@brand),
        "酒店品牌错误。期望: #{@brand}, 实际: #{actual_brand || '未分类'}"
    end
  end
  
  private
  
  def execution_state_data
    {
      city: @city,
      brand: @brand,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      nights: @nights
    }
  end
  
  def restore_from_state(data)
    @city = data['city']
    @brand = data['brand']
    @check_in_date = Date.parse(data['check_in_date'])
    @check_out_date = Date.parse(data['check_out_date'])
    @nights = data['nights']
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 随机选择一家杭州的商务酒店
    target_hotel = Hotel.where(
      city: @city,
      brand: @brand,
      data_version: 0
    ).sample
    
    raise "未找到符合条件的酒店" if target_hotel.nil?
    
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
      hotel_brand: target_hotel.brand,
      check_in_date: @check_in_date.to_s,
      user_email: user.email
    }
  end
end
