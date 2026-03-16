# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例224: 帮张三预订后天杭州→上海火车票（二等座）+上海经济型酒店（后天入住1晚），每项≤300元
#
# 任务描述:
#   张三后天需要从杭州到上海办事，预算比较紧。
#   需要预订火车票（二等座）和上海经济型酒店住1晚，每项都不超过300元。
#   Agent 需要创建1个火车票订单和1个酒店订单，确保火车票价格≤300元，酒店单晚价格≤300元。
#
# 业务流程（8个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 搜索杭州→上海火车票（后天出发）
#   3. 筛选符合预算的火车票（二等座价格≤300元）
#   4. 创建火车票订单（座位类型=二等座，出行日期=后天）
#   5. 搜索上海经济型酒店（price≤300元）
#   6. 筛选酒店房间（room_category='overnight'，排除钟点房）
#   7. 创建酒店订单（入住日期=火车日期，入住1晚）
#   8. 验证两个订单均符合预算要求（单项≤300元）
#
# 复杂度分析（8个关键点）：
#   1. 需要理解火车票+酒店组合预订场景
#   2. 需要明确火车路线（杭州→上海，后天出发）
#   3. 需要筛选经济型酒店（hotel.price≤300元）
#   4. 需要理解"每项不超过300元"预算约束（火车票≤300元 AND 酒店≤300元，两个独立约束）
#   5. 需要选择二等座座位类型（seat_type = 'second_class'）
#   6. 需要筛选符合预算的火车票（price_second_class≤300元）
#   7. 需要筛选符合预算的酒店房间（room.price≤300元，room_category='overnight'）
#   8. 需要使用受益人信息作为乘客和入住人信息
#   ❌ 不能一次性提供所有信息：需要分别查询火车和酒店数据，筛选符合预算的选项，分步骤创建订单。
#
# 评分标准（9项，总计100分）：
#   1. 创建了火车票订单（15分）
#   2. 创建了酒店订单（15分）
#   3. 火车票价格≤300元（15分）
#   4. 酒店单晚价格≤300元（15分）
#   5. 出行日期正确（后天）（10分）
#   6. 入住日期正确（入住=火车日期，退房=火车日期+1天）（10分）
#   7. 乘车人信息正确（张三的姓名、身份证号、手机号）（10分）
#   8. 入住人信息正确（张三的姓名、手机号）（5分）
#   9. 订单状态有效（pending/paid/completed）（5分）
#
# 使用方法:
#   rake validator:simulate_single[v224_book_budget_combo_under_500_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V224BookBudgetComboUnder500Validator < BaseValidator
    self.validator_id = 'v224_book_budget_combo_under_500_validator'
    self.task_id = '1ff132ff-2f2f-2f4f-4f5f-3f6a7b8c9d0f'
    self.title = '帮张三预订后天杭州→上海火车票（二等座）+上海经济型酒店（后天入住1晚），每项≤300元'
    self.description = '张三想后天从杭州去上海办事，预算比较紧，需要预订火车票和经济型酒店，每项都不超过300元'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '杭州'
      @arrival_city = '上海'
      @travel_date = Date.current + 2.days
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 1.day
      @max_item_price = 300
      
      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_phone = @passenger.phone
      
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a.select { |t| t.price_second_class <= @max_item_price }
      
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).to_a.select do |h|
        h.price <= @max_item_price
      end
      
      raise "未找到符合预算的火车或酒店" if @available_trains.empty? || @available_hotels.empty?
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@arrival_city}的火车票，并预订#{@arrival_city}经济型酒店。要求火车票和酒店单项均≤300元。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          max_item_price: "单项≤#{@max_item_price}元",
          purpose: '经济实惠'
        },
        hint: "选择价格≤300元的火车票和酒店。"
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
      
      add_assertion "火车票价格≤#{@max_item_price}元", weight: 15 do
        price = @train_booking.total_price
        expect(price).to be <= @max_item_price,
          "火车票价格超标。期望: ≤#{@max_item_price}元, 实际: #{price}元"
      end
      
      add_assertion "酒店单晚价格≤#{@max_item_price}元", weight: 15 do
        price = @hotel_booking.hotel.price
        expect(price).to be <= @max_item_price,
          "酒店价格超标。期望: ≤#{@max_item_price}元/晚, 实际: #{price}元/晚"
      end
      
      add_assertion "出行日期正确（#{@travel_date}，后天）", weight: 10 do
        train_date = @train_booking.train.departure_time.to_date
        expect(train_date).to eq(@travel_date),
          "火车出行日期错误。期望: #{@travel_date}（后天）, 实际: #{train_date}"
      end
      
      add_assertion "入住日期正确（入住#{@check_in_date}，退房#{@check_out_date}）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "乘车人信息正确（张三）", weight: 10 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "乘车人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘车人身份证错误。期望: #{@expected_passenger_id}, 实际: #{@train_booking.passenger_id_number}"
        expect(@train_booking.contact_phone).to eq(@expected_phone),
          "联系电话错误。期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
      end
      
      add_assertion "入住人信息正确（张三）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@train_booking.status).to be_in(['pending', 'paid', 'completed']),
          "火车票订单状态异常。实际状态: #{@train_booking.status}"
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "酒店订单状态异常。实际状态: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择最便宜的组合
      train = @available_trains.min_by(&:price_second_class)
      hotel = @available_hotels.min_by(&:price)
      room = hotel.hotel_rooms.where(data_version: 0).first
      
      TrainBooking.create!(
        user: user,
        train: train,
        passenger_name: @expected_passenger_name,
        passenger_id_number: @expected_passenger_id,
        contact_phone: @expected_phone,
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: train.price_second_class,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @expected_passenger_name,
        guest_phone: @expected_phone,
        room_count: 1,
        total_price: hotel.price,
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
        max_item_price: @max_item_price,
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
      @max_item_price = data['max_item_price']
      
      # Restore expected values from state
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_phone = data['expected_phone']
      
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a.select { |t| t.price_second_class <= @max_item_price }
      
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).to_a.select do |h|
        h.price <= @max_item_price
      end
    end
  end
end
