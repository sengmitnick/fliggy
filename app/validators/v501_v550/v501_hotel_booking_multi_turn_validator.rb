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
    
    # 处理用户消息并返回 Agent 响应
    # 在多轮对话中，这个方法会被调用来获取 Agent 的回复
    def process_user_message(message)
      # 在实际实现中，这里应该调用真实的 Agent API
      # 目前返回模拟响应用于测试框架
      
      # 简单的规则引擎模拟 Agent 行为
      if @current_turn == 1
        # 第一轮：询问详细需求
        "好的，我来帮您预订酒店。请问您的入住日期和离店日期是什么时候？"
      elsif message.include?('入住') || message.include?('日期')
        # 第二轮：确认预算和偏好
        "明白了，入住日期是#{@check_in_date}，离店日期是#{@check_out_date}。您提到预算#{@budget}元，对酒店位置或设施有特殊要求吗？"
      elsif message.include?('位置') || message.include?('性价比')
        # 第三轮：推荐酒店
        hotel = Hotel.where(data_version: 0)
                     .by_city(@city)
                     .where('price <= ?', @budget)
                     .order(rating: :desc)
                     .first
        
        if hotel
          "我为您找到了#{hotel.name}，每晚#{hotel.price}元，#{hotel.star_level}星级，评分#{hotel.rating}。是否需要我帮您预订？"
        else
          "抱歉，暂时没有找到符合条件的酒店。要不要调整一下预算或城市？"
        end
      elsif message.include?('预订') || message.include?('确认')
        # 第四轮：执行预订
        user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
        hotel = Hotel.where(data_version: 0)
                     .by_city(@city)
                     .where('price <= ?', @budget)
                     .order(rating: :desc)
                     .first
        
        if hotel
          hotel_room = hotel.hotel_rooms.first
          
          booking = HotelBooking.create!(
            user_id: user.id,
            hotel_id: hotel.id,
            hotel_room_id: hotel_room&.id,
            check_in_date: @check_in_date,
            check_out_date: @check_out_date,
            total_price: hotel.price,
            data_version: @data_version
          )
          
          "预订成功！您的订单号是#{booking.id}，#{hotel.name}，入住日期#{@check_in_date}，离店日期#{@check_out_date}，总价#{hotel.price}元。"
        else
          "抱歉，预订失败，未找到合适的酒店。"
        end
      else
        # 其他情况：提示用户
        "我需要了解您的入住日期和预算，才能帮您找到合适的酒店。"
      end
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
