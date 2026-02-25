# frozen_string_literal: true

require_relative '../base_validator'

# V218: 预订火车票+酒店（总预算≤800元）
#
# 任务描述:
#   用户需要预订火车票+酒店，总预算≤800元
#
# 评分标准:
#   - 创建了火车票订单 (20%)
#   - 创建了酒店订单 (20%)
#   - 总价格≤800元 (40%)
#   - 订单状态有效 (20%)
module V201V250
  class V218BookTrainAndHotelBudget800Validator < BaseValidator
    self.validator_id = 'v218_book_train_and_hotel_budget_800_validator'
    self.task_id = 'c3d4e5f6-7a8b-9c0d-1e2f-3a4b5c6d7e8f'
    self.title = '帮张三订后天从上海到杭州的火车票+酒店（当晚入住1晚），总预算不超过800元'
    self.description = '帮张三订后天从上海到杭州的火车票+酒店（当晚入住1晚），总预算不超过800元'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @arrival_city = '杭州'
      @travel_date = Date.current + 2.days
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 1.day
      @max_budget = 800
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_name = @passenger.name
      @expected_id_number = @passenger.id_number
      @expected_phone = @passenger.phone
      
      # 查找可用火车
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      # 查找可用酒店
      @available_hotels = Hotel.where(
        city: @arrival_city,
        data_version: 0
      ).order(price: :asc)
      
      raise "未找到符合条件的火车或酒店" if @available_trains.empty? || @available_hotels.empty?
      
      # 检查是否有组合满足预算
      cheapest_train = @available_trains.first.price_second_class
      cheapest_hotel_room = @available_hotels.first.hotel_rooms.where(data_version: 0).order(price: :asc).first
      cheapest_combo = cheapest_train + (cheapest_hotel_room ? cheapest_hotel_room.price : Float::INFINITY)
      raise "最便宜的组合(#{cheapest_combo}元)超出预算#{@max_budget}元" if cheapest_combo > @max_budget
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@arrival_city}的火车票，并预订#{@arrival_city}的酒店（当晚入住1晚）。总预算不超过#{@max_budget}元。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          hotel_city: @arrival_city,
          check_in_date: @check_in_date,
          nights: 1,
          max_budget: @max_budget
        },
        hint: "需要综合考虑火车票和酒店的价格，确保总价不超过#{@max_budget}元。优先选择性价比高的组合。"
      }
    end
    
    def verify
      add_assertion "创建了火车票订单", weight: 20 do
        all_train_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @train_booking = all_train_bookings.first
        expect(@train_booking).not_to be_nil, "未找到从#{@departure_city}到#{@arrival_city}的火车票订单"
      end
      
      return if @train_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 20 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_hotel_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@arrival_city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "火车出行日期正确（#{@travel_date.strftime('%m月%d日')}）", weight: 10 do
        expect(@train_booking.train.departure_time.to_date).to eq(@travel_date),
          "火车出行日期错误。期望: #{@travel_date}（后天）, 实际: #{@train_booking.train.departure_time.to_date}"
      end
      
      add_assertion "酒店入住日期正确（#{@check_in_date.strftime('%m月%d日')}）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（火车当天）, 实际: #{@hotel_booking.check_in_date}"
      end
      
      add_assertion "总价格≤#{@max_budget}元", weight: 20 do
        train_price = @train_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = train_price + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。火车票: #{train_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      add_assertion "乘客/入住人信息正确（张三）", weight: 10 do
        expect(@train_booking.passenger_name).to eq(@expected_guest_name),
          "火车票乘客姓名错误。期望: #{@expected_guest_name}, 实际: #{@train_booking.passenger_name}"
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "酒店入住人姓名错误。期望: #{@expected_guest_name}, 实际: #{@hotel_booking.guest_name}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@train_booking.status).to be_in(['pending', 'paid', 'completed']),
          "火车票订单状态异常。实际状态: #{@train_booking.status}"
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "酒店订单状态异常。实际状态: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到预算内的最佳组合
      best_combo = nil
      best_value = 0
      
      @available_trains.first(10).each do |train|
        @available_hotels.first(10).each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
          next unless room
          
          total = train.price_second_class + room.price
          next if total > @max_budget
          
          # 计算性价比（剩余预算越多越好）
          value_score = @max_budget - total
          
          if best_combo.nil? || value_score > best_value
            best_combo = { train: train, hotel: hotel, room: room }
            best_value = value_score
          end
        end
      end
      
      raise "未找到符合预算的组合" if best_combo.nil?
      
      # 创建火车票订单
      TrainBooking.create!(
        user: user,
        train: best_combo[:train],
        passenger_name: @expected_guest_name,
        passenger_id_number: @expected_id_number,
        contact_phone: @expected_phone,
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: best_combo[:train].price_second_class,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      # 创建酒店订单
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel],
        hotel_room_id: best_combo[:room].id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @expected_guest_name,
        guest_phone: @expected_phone,
        payment_method: '花呗',
        total_price: best_combo[:room].price,
        status: 'paid',
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
        expected_guest_name: @expected_guest_name,
        expected_id_number: @expected_id_number,
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
      @expected_guest_name = data['expected_guest_name']
      @expected_id_number = data['expected_id_number']
      @expected_phone = data['expected_phone']
      
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @available_hotels = Hotel.where(
        city: @arrival_city,
        data_version: 0
      ).order(price: :asc)
    end
  end
end
