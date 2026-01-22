# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例: 预订后天入住一晚深圳的经济型酒店
# 
# 任务描述:
#   Agent 需要在系统中搜索深圳的酒店，
#   找到预算≤500元且性价比最高的酒店并成功创建订单
# 
# 复杂度分析:
#   1. 需要搜索"深圳"城市的酒店（从10个城市中筛选）
#   2. 需要选择"后天"日期（理解相对日期）
#   3. 需要对比价格（5家深圳酒店，找到≤500元的）
#   4. 需要在多个符合条件的酒店中选择性价比最高的
#   5. 需要填写入住信息（房型、入住1晚，离店日期为大后天）
#   ❌ 不能一次性提供：需要先搜索→筛选价格→对比评分→预订
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（深圳市）(15分)
#   - 入住日期正确（后天入住，大后天离店，共1晚）(15分)
#   - 价格符合预算（≤500元/晚）(30分)
#   - 选择了性价比最高的酒店（综合价格和评分）(20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_budget_hotel_shenzhen/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V001BookBudgetHotelValidator < BaseValidator
  self.validator_id = 'book_budget_hotel_shenzhen'
  self.title = ' 预订后天入住一晚深圳的经济型酒店'
  self.description = '需要在系统中搜索深圳的酒店，找到预算≤500元且性价比最高的酒店并成功创建订单'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @city = '深圳'
    @budget = 500
    @check_in_date = Date.current + 2.days  # 后天
    @nights = 1  # 入住1晚
    @check_out_date = @check_in_date + @nights.days  # 离店日期
    
    # 查找符合条件的酒店（用于后续验证）
    # 注意：查询基线数据 (data_version=0)
    eligible_hotels = Hotel.where(
      city: @city,
      data_version: 0
    ).where('price <= ?', @budget)
    
    # 找到性价比最高的酒店（评分最高）
    @best_hotel = eligible_hotels.order(rating: :desc, price: :asc).first
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订后天入住#{@city}的经济型酒店（预算≤#{@budget}元/晚，入住1晚）",
      city: @city,
      budget: @budget,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      date_description: "入住：后天（#{@check_in_date.strftime('%Y年%m月%d日')}），离店：#{@check_out_date.strftime('%Y年%m月%d日')}",
      nights: @nights,
      hint: "系统中有多家酒店可选，请选择性价比最高的（综合价格和评分）",
      available_hotels_count: eligible_hotels.count,
      budget_range: "≤#{@budget}元/晚"
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
    
    # 断言3: 入住日期正确
    add_assertion "入住日期正确", weight: 15 do
      expect(@hotel_booking.check_in_date).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
    end
    
    # 断言4: 价格符合预算（核心评分项）
    add_assertion "价格符合预算", weight: 30 do
      hotel_price = @hotel_booking.hotel.price
      expect(hotel_price <= @budget).to be_truthy,
        "价格超出预算。预算: ≤#{@budget}元, 实际: #{hotel_price}元"
    end
    
    # 断言5: 选择了性价比最高的酒店（核心评分项）
    add_assertion "选择了性价比最高的酒店", weight: 20 do
      # 查找所有符合预算的酒店
      eligible_hotels = Hotel.where(
        city: @city,
        data_version: 0
      ).where('price <= ?', @budget)
      
      # 找到性价比最高的（评分最高，价格相同时选便宜的）
      best_hotel = eligible_hotels.order(rating: :desc, price: :asc).first
      
      # 验证是否选择了最优酒店
      expect(@hotel_booking.hotel_id).to eq(best_hotel.id),
        "未选择性价比最高的酒店。应选: #{best_hotel.name}(评分#{best_hotel.rating}分，价格#{best_hotel.price}元), " \
        "实际选择: #{@hotel_booking.hotel.name}(评分#{@hotel_booking.hotel.rating}分，价格#{@hotel_booking.hotel.price}元)"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      city: @city,
      budget: @budget,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      nights: @nights,
      best_hotel_id: @best_hotel&.id
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @city = data['city']
    @budget = data['budget']
    @check_in_date = Date.parse(data['check_in_date'])
    @check_out_date = Date.parse(data['check_out_date'])
    @nights = data['nights']
    @best_hotel = Hotel.find_by(id: data['best_hotel_id']) if data['best_hotel_id']
  end
  
  # 模拟 AI Agent 操作：预订深圳最优性价比酒店
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合预算的酒店，选择评分最高的
    target_hotel = Hotel.where(
      city: @city,
      data_version: 0
    ).where('price <= ?', @budget)
     .order(rating: :desc, price: :asc)
     .first
    
    raise "未找到符合预算的酒店" unless target_hotel
    
    # 3. 查找该酒店的房型（HotelRoom，选择最便宜的标准房）
    target_hotel_room = HotelRoom.where(hotel_id: target_hotel.id)
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
      adults_count: 1,
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
      hotel_price: target_hotel.price,
      hotel_rating: target_hotel.rating,
      room_type: target_hotel_room.room_type,
      check_in_date: @check_in_date.to_s,
      nights: @nights,
      total_price: hotel_booking.total_price,
      user_email: user.email
    }
  end
end
