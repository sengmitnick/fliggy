# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例: 搜索后天入住两晚北京评分最高的高档酒店
# 
# 任务描述:
#   Agent 需要在系统中搜索北京的酒店，
#   筛选4星级及以上的酒店，找到评分最高的并完成预订
# 
# 复杂度分析:
#   1. 需要搜索"北京"城市（从10个城市中筛选）
#   2. 需要筛选星级（≥4星）
#   3. 需要对比评分（4.0-5.0分范围）
#   4. 需要找到评分最高的（可能有多个4.9分，需要对比价格）
#   5. 需要完成预订流程（入住2晚，离店日期为后天+2天）
#   ❌ 不能一次性提供：需要搜索→筛选星级→对比评分→确认最高分→预订
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（北京市）(15分)
#   - 星级符合（≥4星）(15分)
#   - 选择了评分最高的酒店 (35分)
#   - 订单信息准确（入住2晚，离店日期正确）(15分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/search_high_rated_hotel_beijing/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class SearchHighRatedHotelValidator < BaseValidator
  self.validator_id = 'search_high_rated_hotel_beijing'
  self.title = '搜索北京评分最高的高档酒店'
  self.description = '在后天入住北京，找到4星级及以上、评分最高的酒店'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @city = '北京'
    @min_star_level = 4
    @check_in_date = Date.current + 2.days  # 后天
    @nights = 2  # 入住2晚
    
    # 查找符合条件的酒店（用于后续验证）
    # 注意：查询基线数据 (data_version=0)
    eligible_hotels = Hotel.where(
      city: @city,
      data_version: 0
    ).where('star_level >= ?', @min_star_level)
    
    # 找到评分最高的酒店
    @best_hotel = eligible_hotels.order(rating: :desc, price: :asc).first
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订后天入住#{@city}的高档酒店（4星级及以上，评分最高）",
      city: @city,
      min_star_level: @min_star_level,
      check_in_date: @check_in_date.to_s,
      date_description: "后天（#{@check_in_date.strftime('%Y年%m月%d日')}）",
      nights: @nights,
      hint: "系统中有多家高档酒店可选，请选择评分最高的",
      available_hotels_count: eligible_hotels.count,
      requirement: "≥#{@min_star_level}星级，评分最高"
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @hotel_booking = HotelBooking.order(created_at: :desc).first
      expect(@hotel_booking).not_to be_nil, "未找到任何酒店订单记录"
    end
    
    return unless @hotel_booking # 如果没有订单，后续断言无法继续
    
    # 断言2: 城市正确
    add_assertion "城市正确", weight: 15 do
      expect(@hotel_booking.hotel.city).to eq(@city),
        "城市错误。期望: #{@city}, 实际: #{@hotel_booking.hotel.city}"
    end
    
    # 断言3: 星级符合要求
    add_assertion "星级符合要求", weight: 15 do
      hotel_star_level = @hotel_booking.hotel.star_level
      expect(hotel_star_level >= @min_star_level).to be_truthy,
        "星级不符合要求。最低要求: #{@min_star_level}星, 实际: #{hotel_star_level}星"
    end
    
    # 断言4: 选择了评分最高的酒店（核心评分项）
    add_assertion "选择了评分最高的酒店", weight: 35 do
      # 查找所有符合星级要求的酒店
      eligible_hotels = Hotel.where(
        city: @city,
        data_version: 0
      ).where('star_level >= ?', @min_star_level)
      
      # 找到评分最高的（评分相同时选价格最低的）
      best_hotel = eligible_hotels.order(rating: :desc, price: :asc).first
      
      # 验证是否选择了评分最高的酒店
      expect(@hotel_booking.hotel_id).to eq(best_hotel.id),
        "未选择评分最高的酒店。应选: #{best_hotel.name}(#{best_hotel.star_level}星，评分#{best_hotel.rating}分), " \
        "实际选择: #{@hotel_booking.hotel.name}(#{@hotel_booking.hotel.star_level}星，评分#{@hotel_booking.hotel.rating}分)"
    end
    
    # 断言5: 订单信息准确
    add_assertion "订单信息准确", weight: 15 do
      # 检查入住日期
      expect(@hotel_booking.check_in_date).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
      
      # 检查入住天数（通过check_out_date计算）
      actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
      expect(actual_nights).to eq(@nights),
        "入住天数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      city: @city,
      min_star_level: @min_star_level,
      check_in_date: @check_in_date.to_s,
      nights: @nights,
      best_hotel_id: @best_hotel&.id
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @city = data['city']
    @min_star_level = data['min_star_level']
    @check_in_date = Date.parse(data['check_in_date'])
    @nights = data['nights']
    @best_hotel = Hotel.find_by(id: data['best_hotel_id']) if data['best_hotel_id']
  end
  
  # 模拟 AI Agent 操作：预订北京评分最高的高档酒店
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合星级要求的酒店，选择评分最高的
    target_hotel = Hotel.where(
      city: @city,
      data_version: 0
    ).where('star_level >= ?', @min_star_level)
     .order(rating: :desc, price: :asc)
     .first
    
    raise "未找到符合星级要求的酒店" unless target_hotel
    
    # 3. 查找该酒店的房型（HotelRoom，选择豪华大床房）
    target_hotel_room = HotelRoom.where(hotel_id: target_hotel.id)
                                 .where(room_category: 'overnight')
                                 .where('room_type LIKE ?', '%豪华%')
                                 .first
    
    # 如果没有豪华房，选择第一个可用房型
    target_hotel_room ||= HotelRoom.where(hotel_id: target_hotel.id)
                                   .where(room_category: 'overnight')
                                   .order(:price)
                                   .first
    
    raise "未找到可用房型" unless target_hotel_room
    
    # 4. 创建酒店订单
    hotel_booking = HotelBooking.create!(
      hotel_id: target_hotel.id,
      hotel_room_id: target_hotel_room.id,
      user_id: user.id,
      check_in_date: @check_in_date,
      check_out_date: @check_in_date + @nights.days,
      rooms_count: 1,
      adults_count: 2,
      children_count: 0,
      total_price: target_hotel_room.price * @nights,
      payment_method: '花呗',
      status: 'pending',
      guest_name: user.email.split('@').first,
      guest_phone: '13800138000'
    )
    
    # 返回操作信息
    {
      action: 'create_hotel_booking',
      booking_id: hotel_booking.id,
      hotel_name: target_hotel.name,
      hotel_star_level: target_hotel.star_level,
      hotel_rating: target_hotel.rating,
      hotel_price: target_hotel.price,
      room_type: target_hotel_room.room_type,
      check_in_date: @check_in_date.to_s,
      nights: @nights,
      total_price: hotel_booking.total_price,
      user_email: user.email
    }
  end
end
