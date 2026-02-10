# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例187: 预订火车+中档酒店，总预算800-1200元
#
# 任务描述:
#   预订火车+中档酒店，总预算800-1200元
#
# 评分标准:
#   - TODO: 定义评分标准
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v187_book_mid_range_train_and_hotel_800_1200_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V187BookMidRangeTrainAndHotel8001200Validator < BaseValidator
    self.validator_id = 'v187_book_mid_range_train_and_hotel_800_1200_validator'
    self.task_id = '9551dc4b-e494-48e9-8ee2-6be8838706cb'
    self.title = '预订火车+中档酒店，总预算800-1200元'
    self.description = '预订火车+中档酒店，总预算800-1200元'
    self.timeout_seconds = 300
    
    # 准备阶段：设置任务参数
    #
    # 返回任务信息给 Agent（必须包含 task 字段）
    #
    # Example:
    #   def prepare
    #     @city = '深圳'
    #     @budget = 500
    #     
    #     {
    #       task: "请预订#{@city}的酒店，预算≤#{@budget}元",
    #       city: @city,
    #       budget: @budget,
    #       hint: "系统中有多家酒店可选，请选择性价比最高的"
    #     }
    #   end
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.current + 1.day  # 明天 + 1.day
      @min_budget = 800
      @max_budget = 1200
      
      # 查找火车票
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .select { |t| t.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_trains).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}的火车"
      
      # 查找酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      
      # 查找符合预算的组合（火车二等座+酒店）
      @valid_combinations = []
      @available_trains.each do |train|
        @available_hotels.each do |hotel|
          rooms = hotel.hotel_rooms.where(data_version: 0).to_a
          next if rooms.empty?
          
          cheapest_room = rooms.min_by(&:price)
          total = train.price_second_class + cheapest_room.price
          
          if total >= @min_budget && total <= @max_budget
            @valid_combinations << {
              train: train,
              hotel: hotel,
              room: cheapest_room,
              total_price: total
            }
          end
        end
      end
      
      expect(@valid_combinations).not_to be_empty, 
        "数据包缺少符合预算的火车+酒店组合（#{@min_budget}-#{@max_budget}元）"
      
      # 选择最优组合（价格最接近预算上限的）
      @selected_combo = @valid_combinations.max_by { |c| c[:total_price] }
      @check_in_date = @selected_combo[:train].arrival_time.to_date
      @check_out_date = @check_in_date + 1.day
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（#{(@travel_date - Date.current).to_i}天后）" \
              "从#{@departure_city}到#{@arrival_city}的火车票，并预订当地酒店，总预算#{@min_budget}-#{@max_budget}元",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date.to_s,
          budget_min: @min_budget,
          budget_max: @max_budget
        },
        hint: "选择二等座火车票+中档酒店，控制总价在预算内，优先选择性价比高的组合",
        statistics: {
          available_trains: @available_trains.count,
          available_hotels: @available_hotels.count,
          valid_combinations: @valid_combinations.count
        }
      }
    end
    
    # 验证阶段：检查任务是否完成
    #
    # 使用 add_assertion 添加断言（必须指定 weight 权重，总和为 100）
    def verify
      # 断言1: 创建了火车订单和酒店订单 (25%)
      add_assertion "创建了火车订单和酒店订单", weight: 25 do
        all_train_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @train_booking = all_train_bookings.first
        expect(@train_booking).not_to be_nil, "未找到火车订单（#{@departure_city}→#{@arrival_city}）"
        
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where("hotels.city LIKE ?", "%#{@arrival_city}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_hotel_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（#{@arrival_city}）"
      end
      
      return if @train_booking.nil? || @hotel_booking.nil?
      
      # 断言2: 火车目的地正确 (15%)
      add_assertion "火车到达#{@arrival_city}", weight: 15 do
        train = @train_booking.train
        expect(train.arrival_city).to eq(@arrival_city),
          "火车到达城市错误。期望: #{@arrival_city}, 实际: #{train.arrival_city}"
      end
      
      # 断言3: 酒店位置正确 (15%)
      add_assertion "酒店位于#{@arrival_city}", weight: 15 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@arrival_city),
          "酒店城市错误。期望包含: #{@arrival_city}, 实际: #{hotel.city}"
      end
      
      # 断言4: 酒店入住日期合理（火车到达当天或次日） (15%)
      add_assertion "酒店入住日期合理（火车到达当天或次日）", weight: 15 do
        arrival_date = @train_booking.train.arrival_time.to_date
        expect(@hotel_booking.check_in_date).to be >= arrival_date,
          "入住日期早于火车到达日期。火车到达: #{arrival_date}, 入住日期: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_in_date).to be <= arrival_date + 1.day,
          "入住日期过晚。火车到达: #{arrival_date}, 入住日期: #{@hotel_booking.check_in_date}"
      end
      
      # 断言5: 总价在预算范围内（800-1200元） (30%)
      add_assertion "总价在预算范围内（#{@min_budget}-#{@max_budget}元）", weight: 30 do
        train_price = @train_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = train_price + hotel_price
        
        expect(total_price).to be >= @min_budget,
          "总价低于预算下限。期望: ≥#{@min_budget}元, 实际: #{total_price}元（火车#{train_price}元+酒店#{hotel_price}元）"
        expect(total_price).to be <= @max_budget,
          "总价超出预算上限。期望: ≤#{@max_budget}元, 实际: #{total_price}元（火车#{train_price}元+酒店#{hotel_price}元）"
      end
    end
    
    # 模拟 AI Agent 操作
    #
    # 此方法模拟 AI Agent 如何完成任务（用于自动化测试）
    #
    # Example:
    #   def simulate
    #     user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    #     
    #     hotel = Hotel.where(city: @city, data_version: 0)
    #                  .where('price <= ?', @budget)
    #                  .order(rating: :desc)
    #                  .first
    #     
    #     HotelBooking.create!(
    #       user_id: user.id,
    #       hotel_id: hotel.id,
    #       check_in_date: @check_in_date,
    #       total_price: hotel.price
    #     )
    #   end
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建火车订单（二等座）
      train = @selected_combo[:train]
      TrainBooking.create!(
        user: user,
        train: train,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        seat_type: 'second_class',
        contact_phone: @passenger.phone,
        total_price: train.price_second_class,
        accept_terms: true,
        data_version: @data_version
      )
      
      # 创建酒店订单
      hotel = @selected_combo[:hotel]
      room = @selected_combo[:room]
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: @passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
    
    private
    
    # 保存执行状态数据（用于跨请求恢复状态）
    #
    # 返回需要持久化的实例变量数据
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date&.to_s,
        min_budget: @min_budget,
        max_budget: @max_budget,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s
      }
    end
    
    # 从状态恢复实例变量（用于跨请求恢复状态）
    #
    # 从持久化数据恢复实例变量
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '刘强', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @min_budget = data['min_budget']
      @max_budget = data['max_budget']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
    end
  end
end
