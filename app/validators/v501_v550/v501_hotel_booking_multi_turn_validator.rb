# frozen_string_literal: true

require_relative '../base_validator'
require_relative '../multi_turn_base_validator'

# 验证用例501: 酒店预订多轮对话 (AI Simul User)
#
# 任务描述:
#   用户模糊描述需求，AI助手通过反问获取信息后完成酒店预订
#   使用 AI 驱动的模拟用户进行多轮对话测试
#
# 评分标准:
#   - 创建了酒店订单 (30%)
#   - 酒店城市正确 (20%)
#   - 价格在预算范围内 (25%)
#   - 入住日期正确 (25%)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/0b2d6f73-3d61-4dab-84da-4de740b906a3/start
#   
#   # AI Agent 与 Simul User 进行多轮对话...
#   
#   # 验证结果
#   POST /api/verify/run
module V501V550
  class V501HotelBookingMultiTurnValidator < MultiTurnBaseValidator
    self.validator_id = 'v501_hotel_booking_multi_turn_validator'
    self.task_id = '0b2d6f73-3d61-4dab-84da-4de740b906a3'
    self.title = '酒店预订多轮对话'
    self.description = '用户模糊描述需求，AI助手通过反问获取信息后完成酒店预订'
    self.timeout_seconds = 300
    self.max_turns = 10
    
    # 准备阶段：设置任务参数
    def prepare
      @city = '上海'
      @budget = 500
      @check_in_date = 3.days.from_now.to_date
      @check_out_date = 4.days.from_now.to_date
      
      # 返回任务信息
      {
        task: initial_task_goal,
        city: @city,
        budget: @budget,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        hint: "用户会逐步提供信息，请通过提问获取完整需求"
      }
    end
    
    # 定义初始任务目标（模糊描述）
    # 这是 Simul User 的第一句话，应该是一个模糊的需求描述
    # 具体信息（城市、预算、日期）由 AI 在后续对话中逐步提供
    def initial_task_goal
      today = Time.current.to_date
      "今天是#{today.year}年#{today.month}月#{today.day}日，我想订个酒店"
    end
    
    # 提供用户背景信息
    def user_context
      {
        city: @city,
        budget: @budget,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        preferences: '性价比高，地理位置方便'
      }
    end
    
    # 验证阶段：检查任务是否完成
    def verify
      # 断言1: 创建了酒店订单
      add_assertion "创建了酒店订单", weight: 30 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何酒店订单"
        
        @hotel_bookings = all_bookings
        expect(@hotel_bookings.size).to be >= 1, "订单数量不足"
      end
      
      return if @hotel_bookings.nil? || @hotel_bookings.empty?
      
      # 断言2: 酒店城市正确
      add_assertion "酒店城市正确（#{@city}）", weight: 20 do
        @hotel_bookings.each do |booking|
          hotel_city = booking.hotel.city
          # 支持"上海"和"上海市"互相匹配
          base_city = @city.gsub(/市.*$/, '')
          expect([hotel_city, hotel_city.gsub(/市.*$/, '')]).to include(base_city),
            "酒店城市错误。期望: #{@city}, 实际: #{hotel_city}"
        end
      end
      
      # 断言3: 价格在预算范围内
      add_assertion "价格在预算范围内（≤#{@budget}元）", weight: 25 do
        @hotel_bookings.each do |booking|
          price = booking.total_price || booking.hotel.price
          expect(price).to be <= @budget,
            "价格超出预算。预算: #{@budget}元, 实际: #{price}元"
        end
      end
      
      # 断言4: 入住日期正确
      add_assertion "入住日期正确（#{@check_in_date}）", weight: 25 do
        @hotel_bookings.each do |booking|
          expect(booking.check_in_date).to eq(@check_in_date),
            "入住日期错误。期望: #{@check_in_date}, 实际: #{booking.check_in_date}"
        end
      end
    end
    
    # 模拟用户操作：直接创建符合条件的酒店订单
    # 注意：此方法用于 rake validator:simulate 测试
    # 在生产环境中，实际订单通过多轮对话 API 创建
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 根据任务条件查找符合要求的酒店和房间
      # 注意：需要同时考虑酒店和房间的价格
      hotels = Hotel.where(city: @city, data_version: 0)
      
      target_hotel = nil
      target_hotel_room = nil
      
      # 遍历酒店，找到第一个有符合预算房间的酒店
      hotels.shuffle.each do |hotel|
        room = HotelRoom.where(hotel_id: hotel.id)
                        .where(room_category: 'overnight')
                        .where('price <= ?', @budget)
                        .order(:price)
                        .first
        
        if room
          target_hotel = hotel
          target_hotel_room = room
          break
        end
      end
      
      raise "未找到符合条件的酒店房间（城市: #{@city}, 预算: ≤#{@budget}元）" unless target_hotel && target_hotel_room
      
      # 创建酒店订单
      hotel_booking = HotelBooking.create!(
        hotel_id: target_hotel.id,
        hotel_room_id: target_hotel_room.id,
        user_id: user.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        total_price: target_hotel_room.price,
        payment_method: '花呗',
        status: 'pending',
        guest_name: user.email.split('@').first,
        guest_phone: '13800138000',
        data_version: @data_version
      )
      
      {
        action: 'create_hotel_booking',
        booking_id: hotel_booking.id,
        hotel_name: target_hotel.name,
        room_price: target_hotel_room.price,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        user_email: user.email
      }
    end
    
    private
    
    # 保存执行状态数据
    def execution_state_data
      {
        city: @city,
        budget: @budget,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s
      }
    end
    
    # 从状态恢复实例变量
    def restore_from_state(data)
      @city = data['city']
      @budget = data['budget']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
    end
  end
end
