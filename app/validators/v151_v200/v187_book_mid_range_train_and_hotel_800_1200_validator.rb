# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例187: 给张三预订明天北京到上海的火车和上海中档酒店（总预算800-1200元）
#
# 任务描述:
#   张三需要预订明天从北京到上海的火车和中档酒店，总预算800-1200元。
#   Agent需要搜索火车班次和中档酒店，计算总价保证在预算范围内，
#   帮助用户实现舒适且性价比高的出行组合。
#
# 业务流程（6个关键步骤）：
#   1. 搜索北京→上海的火车班次（明天出发）
#   2. 搜索上海的中档酒店（价格适中，舒适型住宿）
#   3. 计算火车（二等座）+酒店总价，确保800-1200元范围内
#   4. 预订符合预算的火车票（二等座）
#   5. 预订符合预算的中档酒店（入住=火车到达当天，退房=入住+1天）
#   6. 确保火车和酒店的乘客/入住人信息一致（张三）
#
# 复杂度分析（6个关键点）：
#   1. 需要查找火车班次并获取二等座价格
#   2. 需要搜索中档酒店（价格适中，不是极端低价也不是高端豪华）
#   3. 需要计算火车+酒店总价并满足预算约束（800-1200元）
#   4. 需要在符合预算的组合中优选性价比高的方案
#   5. 需要确保酒店入住日期在火车到达当天或次日
#   6. 需要确保火车和酒店的乘客/入住人信息一致
#   ❌ 不能一次性提供：需要先搜索火车→搜索酒店→计算总价→验证预算→预订
#
# 评分标准（9项，总计100分）：
#   - 创建了火车订单和酒店订单（20分）
#   - 火车到达上海（13分）
#   - 酒店位于上海（13分）
#   - 酒店入住日期合理（火车到达当天或次日）（13分）
#   - 总价在预算范围内（800-1200元）（20分）
#   - 火车乘客信息正确（张三）（3分）
#   - 火车联系电话正确（7分）
#   - 酒店入住人信息正确（张三）（8分）
#   - 火车出发日期正确（明天）（3分）
#
# API使用方法:
#   GET /api/tasks - 获取任务列表（包含本任务）
#   POST /api/tasks/:id/start - 创建训练会话（获取任务详情和data_version）
#   POST /api/verify/run - 提交验证结果（验证订单创建情况）
module V151V200
  class V187BookMidRangeTrainAndHotel8001200Validator < BaseValidator
    self.validator_id = 'v187_book_mid_range_train_and_hotel_800_1200_validator'
    self.task_id = '9551dc4b-e494-48e9-8ee2-6be8838706cb'
    self.title = '给张三预订明天北京到上海的火车和上海中档酒店（总预算800-1200元）'
    self.description = '帮张三预订明天从北京到上海的火车和中档酒店，总预算800-1200元'
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
      # 查找乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      # 定义出行信息和预算约束
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.current + 1.day  # 明天
      @min_budget = 800   # 预算下限
      @max_budget = 1200  # 预算上限
      
      # 查找火车班次（明天出发）
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .select { |t| t.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_trains).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}的火车"
      
      # 查找上海的酒店（中档价位）
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      
      # 查找符合预算的组合（火车二等座+酒店，总价800-1200元）
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
      
      # 选择最优组合（价格最接近预算上限的，性价比高）
      @selected_combo = @valid_combinations.max_by { |c| c[:total_price] }
      @check_in_date = @selected_combo[:train].arrival_time.to_date
      @check_out_date = @check_in_date + 1.day
      
      {
        task: "请为#{@passenger.name}预订#{@travel_date.strftime('%Y年%m月%d日')}（#{(@travel_date - Date.current).to_i}天后）" \
              "从#{@departure_city}到#{@arrival_city}的火车票，并在#{@arrival_city}预订中档酒店，总预算#{@min_budget}-#{@max_budget}元",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date.to_s,
          budget_min: @min_budget,
          budget_max: @max_budget,
          accommodation_type: "中档酒店"
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
      # 断言1: 创建了火车订单和酒店订单 (20%)
      add_assertion "创建了火车订单和酒店订单", weight: 20 do
        # 查询火车订单（使用LIKE模糊匹配城市名称）
        all_train_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where("trains.departure_city LIKE ? AND trains.arrival_city LIKE ?", "%#{@departure_city}%", "%#{@arrival_city}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @train_booking = all_train_bookings.first
        expect(@train_booking).not_to be_nil, "未找到火车订单（#{@departure_city}→#{@arrival_city}）"
        
        # 查询酒店订单（使用LIKE模糊匹配城市名称）
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
      
      # 断言2: 火车目的地正确 (13%)
      add_assertion "火车到达#{@arrival_city}", weight: 13 do
        train = @train_booking.train
        expect(train.arrival_city).to eq(@arrival_city),
          "火车到达城市错误。期望: #{@arrival_city}, 实际: #{train.arrival_city}"
      end
      
      # 断言3: 酒店位置正确 (13%)
      add_assertion "酒店位于#{@arrival_city}", weight: 13 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@arrival_city),
          "酒店城市错误。期望包含: #{@arrival_city}, 实际: #{hotel.city}"
      end
      
      # 断言4: 酒店入住日期合理（火车到达当天或次日） (13%)
      add_assertion "酒店入住日期合理（火车到达当天或次日）", weight: 13 do
        arrival_date = @train_booking.train.arrival_time.to_date
        expect(@hotel_booking.check_in_date).to be >= arrival_date,
          "入住日期早于火车到达日期。火车到达: #{arrival_date}, 入住日期: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_in_date).to be <= arrival_date + 1.day,
          "入住日期过晚。火车到达: #{arrival_date}, 入住日期: #{@hotel_booking.check_in_date}"
      end
      
      # 断言5: 总价在预算范围内（800-1200元，中档价位） (20%)
      add_assertion "总价在预算范围内（#{@min_budget}-#{@max_budget}元）", weight: 20 do
        train_price = @train_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = train_price + hotel_price
        
        expect(total_price).to be >= @min_budget,
          "总价低于预算下限，未达到中档标准。期望: ≥#{@min_budget}元, 实际: #{total_price}元（火车#{train_price}元+酒店#{hotel_price}元）"
        expect(total_price).to be <= @max_budget,
          "总价超出预算上限。期望: ≤#{@max_budget}元, 实际: #{total_price}元（火车#{train_price}元+酒店#{hotel_price}元）"
      end
      
      # 断言6: 火车乘客信息正确 (3%)
      add_assertion "火车乘客信息正确（#{@expected_passenger_name}）", weight: 3 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
      end
      
      # 断言7: 火车联系电话正确 (7%)
      add_assertion "火车联系电话正确（#{@expected_phone}）", weight: 7 do
        expect(@train_booking.contact_phone).to eq(@expected_phone),
          "联系电话错误。期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
      end
      
      # 断言8: 酒店入住人信息正确 (8%)
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 8 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言9: 火车出发日期正确 (3%)
      add_assertion "火车出发日期正确（#{@travel_date}）", weight: 3 do
        actual_date = @train_booking.train.departure_time.to_date
        expect(actual_date).to eq(@travel_date),
          "出发日期错误。期望: #{@travel_date}, 实际: #{actual_date}"
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
      # 查找用户信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建火车订单（二等座，符合预算约束）
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
      
      # 创建酒店订单（中档住宿，符合预算约束）
      hotel = @selected_combo[:hotel]
      room = @selected_combo[:room]
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @passenger.name,
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
        check_out_date: @check_out_date&.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
    
    # 从状态恢复实例变量（用于跨请求恢复状态）
    #
    # 从持久化数据恢复实例变量
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger_name = data['expected_passenger_name'] || '张三'
      @passenger = user.passengers.find_by!(name: passenger_name, data_version: 0)
      @expected_passenger_name = data['expected_passenger_name'] || @passenger.name
      @expected_phone = data['expected_phone'] || @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @min_budget = data['min_budget']
      @max_budget = data['max_budget']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      
      # 重建可用火车列表（明天出发）
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .select { |t| t.departure_time.to_date == @travel_date }
        .to_a
      
      # 重建可用酒店列表（中档价位）
      @available_hotels = Hotel
        .where("hotels.city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .to_a
      
      # 重建符合预算的组合（800-1200元）
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
      
      @selected_combo = @valid_combinations.max_by { |c| c[:total_price] } if @valid_combinations.any?
    end
  end
end
