# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例19: 预订大后天广州便宜酒店（价格≤300元）
# 
# 任务描述:
#   Agent 需要在系统中搜索广州的酒店，
#   找到价格≤300元/晚的酒店并成功创建入住1晚的订单
# 
# 复杂度分析:
#   1. 需要搜索"广州"城市的酒店
#   2. 需要选择"大后天"日期（理解相对日期）
#   3. 需要筛选价格≤300元的酒店
#   ❌ 不需要找最便宜的，只要在预算内即可
# 
# 评分标准:
#   - 订单已创建 (15分)
#   - 城市正确（广州） (15分)
#   - 入住日期正确（大后天）(15分)
#   - 离店日期正确（大后天+1天）(15分)
#   - 价格符合预算（≤300元/晚）(40分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v019_book_budget_hotel_guangzhou_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V019BookBudgetHotelGuangzhouValidator < BaseValidator
    self.validator_id = 'v019_book_budget_hotel_guangzhou_validator'
    self.task_id = '7b8e1ba1-622b-44a7-ab82-d733845f73d5'
    self.title = '预订3天后广州便宜酒店（价格≤300元，1晚，1间房1成人）'
    self.description = '搜索广州的酒店，找到价格≤300元/晚的酒店并完成大后天入住1晚的预订'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      @city = '广州'
      @budget = 300
      @check_in_date = Date.current + 3.days  # 大后天
      @nights = 1
      @check_out_date = @check_in_date + @nights.days
    
      # 查找符合条件的酒店
      eligible_hotels = Hotel.where(city: @city, data_version: 0)
                             .where('price <= ?', @budget)
    
      # 返回给 Agent 的任务信息
      {
        task: "请预订大后天入住#{@city}的便宜酒店（预算≤#{@budget}元/晚，入住1晚）",
        city: @city,
        budget: @budget,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        date_description: "入住：大后天（#{@check_in_date.strftime('%Y年%m月%d日')}）",
        nights: @nights,
        hint: "系统中有多家预算内酒店可选，选择价格≤#{@budget}元的酒店即可",
        eligible_hotels_count: eligible_hotels.count,
        budget_range: "≤#{@budget}元/晚"
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建
      add_assertion "订单已创建", weight: 15 do
        all_hotel_bookings = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_hotel_bookings).not_to be_empty, "未找到任何HotelBooking记录"
        @hotel_booking = all_hotel_bookings.first
        # Replaced by expect(all_hotel_bookings).not_to be_empty above, "未找到任何酒店订单记录"
      end
    
      return unless @hotel_booking
    
      # 断言2: 城市正确
      add_assertion "城市正确（广州）", weight: 15 do
        expect(@hotel_booking.hotel.city).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@hotel_booking.hotel.city}"
      end
    
      # 断言3: 入住日期正确
      add_assertion "入住日期正确（大后天）", weight: 15 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
      end
    
      # 断言4: 离店日期正确
      add_assertion "离店日期正确（大后天+1天，入住#{@nights}晚）", weight: 10 do
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "离店日期错误。期望: #{@check_out_date}（入住+#{@nights}天）, 实际: #{@hotel_booking.check_out_date}"
      end
    
      # 断言5: 房间数和人数正确
      add_assertion "房间数和人数正确（1间房，1成人，0儿童）", weight: 15 do
        expect(@hotel_booking.rooms_count).to eq(1),
          "房间数错误。期望: 1间, 实际: #{@hotel_booking.rooms_count}间"
        expect(@hotel_booking.adults_count).to eq(1),
          "成人数错误。期望: 1人, 实际: #{@hotel_booking.adults_count}人"
        expect(@hotel_booking.children_count).to eq(0),
          "儿童数错误。期望: 0人, 实际: #{@hotel_booking.children_count}人"
      end
    
      # 断言6: 价格符合预算（核心评分项）
      add_assertion "价格符合预算（≤#{@budget}元/晚）", weight: 30 do
        hotel_price = @hotel_booking.hotel.price
        expect(hotel_price <= @budget).to be_truthy,
          "价格超出预算。预算: ≤#{@budget}元, 实际: #{hotel_price}元"
      end
    end
  
    private
  
    def execution_state_data
      {
        city: @city,
        budget: @budget,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights
      }
    end
  
    def restore_from_state(data)
      @city = data['city']
      @budget = data['budget']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights']
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 随机选择一家符合预算的广州酒店
      target_hotel = Hotel.where(city: @city, data_version: 0)
                          .where('price <= ?', @budget)
                          .sample
    
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
        hotel_price: target_hotel.price,
        check_in_date: @check_in_date.to_s,
        user_email: user.email
      }
    end
    end
end
