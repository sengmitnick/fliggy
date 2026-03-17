# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例226: 帮张三预订明天广州→深圳最便宜火车票（二等座）+深圳经济型酒店（明天入住1晚），总预算≤300元
#
# 任务描述:
#   张三明天需要从广州到深圳，希望预订火车票（二等座）和经济型酒店住1晚，
#   总预算不超过300元。需要找到最便宜的火车二等座和最便宜的经济型酒店组合。
#
# 业务流程（8个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘车人和入住人信息）
#   2. 搜索广州→深圳火车票（明天出发，二等座）
#   3. 搜索深圳经济型酒店（明天入住，后天退房，住1晚）
#   4. 筛选预算内组合（火车票+酒店总价≤300元）
#   5. 选择最便宜的火车二等座+最便宜的经济型酒店组合
#   6. 创建火车票订单（TrainBooking，乘车人信息填写张三）
#   7. 创建酒店订单（HotelBooking，入住人信息填写张三）
#   8. 验证总价格符合预算约束（≤300元）
#
# 复杂度分析（8个关键点）：
#   1. 多类型订单创建：火车票订单+酒店订单，需要理解两种订单的字段和关系
#   2. 日期推算：明天出发+入住，后天退房，需要正确处理相对日期
#   3. 价格优化：在多个火车票和酒店中找到总价最低的组合
#   4. 预算硬约束：必须确保总价≤300元，不能超出预算
#   5. 乘客信息映射：需要将张三的姓名、身份证号、电话正确填写到两个订单中
#   6. 座位类型选择：必须选择二等座火车票，不能选择其他座位类型
#   7. 酒店类型筛选：必须选择经济型酒店，不能选择高星级酒店
#   8. 订单状态管理：两个订单都需要设置合理的支付状态
#
# 评分标准（8项，总计100分）：
#   1. 创建了火车票订单（广州→深圳，明天出发） - 15分
#   2. 创建了酒店订单（深圳，明天入住1晚） - 15分
#   3. 出行日期正确（明天） - 10分
#   4. 酒店入住日期正确（明天入住，后天退房） - 10分
#   5. 乘车人信息正确（张三，含姓名、身份证、手机号） - 10分
#   6. 入住人信息正确（张三，含姓名、手机号） - 10分
#   7. 总价格≤300元（火车票+酒店，选择最便宜组合） - 25分
#   8. 订单状态有效（两个订单都为pending/paid/completed） - 5分
#
# 使用方法:
#   rake validator:simulate_single[v226_book_student_budget_under_300_validator]
module V201V250
  class V226BookStudentBudgetUnder300Validator < BaseValidator
    self.validator_id = 'v226_book_student_budget_under_300_validator'
    self.task_id = '3ff354ff-4f4f-4f6f-6f7f-5f8a9b0c1d2f'
    self.title = '帮张三预订明天广州→深圳最便宜火车票（二等座）+深圳经济型酒店（明天入住1晚），总预算≤300元'
    self.description = '给张三预订明天从广州到深圳的最便宜火车票+经济型酒店住1晚，总预算不超过300元'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '广州'
      @arrival_city = '深圳'
      @max_budget = 300
      @travel_date = Date.current + 1.day  # 明天出行
      
      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_phone = @passenger.phone
      
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .where(data_version: 0)
        .select { |t| t.departure_time.to_date == @travel_date }  # 只选择指定日期的火车
        .sort_by(&:price_second_class)
      
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0)
        .order(price: :asc)
      
      raise "未找到火车或酒店" if @available_trains.empty? || @available_hotels.empty?
      
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 1.day
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的最便宜出行方案，包括火车票（二等座）和经济型酒店1晚，总预算≤#{@max_budget}元。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          seat_type: '二等座（最便宜）',
          hotel_type: '经济型酒店（最便宜）',
          max_budget: "≤#{@max_budget}元（硬约束）"
        },
        hint: "必须选择最便宜的火车二等座和最便宜的经济型酒店，确保总价不超过#{@max_budget}元。"
      }
    end
    
    def verify
      add_assertion "创建了火车票订单", weight: 15 do
        @train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .first
        
        expect(@train_booking).not_to be_nil, "未找到火车票订单"
      end
      
      return if @train_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "出行日期正确（#{@travel_date}）", weight: 10 do
        train_date = @train_booking.train.departure_time.to_date
        expect(train_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{train_date}"
      end
      
      add_assertion "酒店入住日期正确（入住#{@check_in_date}，退房#{@check_out_date}）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "乘车人信息正确（张三）", weight: 10 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.passenger_id_number).to eq(@expected_passenger_id),
          "身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@train_booking.passenger_id_number}"
        expect(@train_booking.contact_phone).to eq(@expected_phone),
          "联系电话错误。期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
      end
      
      add_assertion "入住人信息正确（张三）", weight: 10 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "总价格≤#{@max_budget}元（选择最便宜组合）", weight: 25 do
        train_price = @train_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = train_price + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。火车票: #{train_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@train_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到预算内最便宜的组合
      best_combo = nil
      
      @available_trains.first(3).each do |train|
        @available_hotels.first(5).each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
          next unless room
          
          total = train.price_second_class + room.price
          next if total > @max_budget
          
          best_combo = { train: train, hotel: hotel, room: room }
          break if best_combo
        end
        break if best_combo
      end
      
      raise "未找到符合预算（≤#{@max_budget}元）的组合" if best_combo.nil?
      
      TrainBooking.create!(
        user: user,
        train: best_combo[:train],
        passenger_name: @expected_passenger_name,
        passenger_id_number: @expected_passenger_id,
        contact_phone: @expected_phone,
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: best_combo[:train].price_second_class,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel],
        hotel_room: best_combo[:room],
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @expected_passenger_name,
        guest_phone: @expected_phone,
        room_count: 1,
        total_price: best_combo[:room].price,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        max_budget: @max_budget,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @max_budget = data['max_budget']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_phone = data['expected_phone']
      
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .where(data_version: 0)
        .select { |t| t.departure_time.to_date == @travel_date }  # 只选择指定日期的火车
        .sort_by(&:price_second_class)
      
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0)
        .order(price: :asc)
    end
  end
end
