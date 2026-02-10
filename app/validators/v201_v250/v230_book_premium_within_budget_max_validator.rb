# frozen_string_literal: true

require_relative '../base_validator'

# V230: 预订预算内服务最高档组合
#
# 任务描述:
#   用户有固定预算（如2000元），需要在预算内选择服务档次最高的组合（优先评分、设施）
#
# 评分标准:
#   - 创建了交通订单（航班或火车） (15%)
#   - 创建了酒店订单 (15%)
#   - 出行日期正确 (10%)
#   - 酒店入住日期正确 (10%)
#   - 乘客信息正确 (5%)
#   - 入住人信息正确 (5%)
#   - 总价格≤预算上限 (15%)
#   - 在预算内选择了评分/档次最高的组合 (20%)
#   - 订单状态有效 (5%)
module V201V250
  class V230BookPremiumWithinBudgetMaxValidator < BaseValidator
    self.validator_id = 'v230_book_premium_within_budget_max_validator'
    self.task_id = '6ff687ff-7f7f-7f9f-9f0f-8f1a2b3c4d5f'
    self.title = '给张三预订预算内最高档组合（交通+酒店，≤2000元）'
    self.description = '张三有固定预算2000元，想从广州去杭州出差，需要在预算内选择服务档次最高的组合，优先考虑酒店评分'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '广州'
      @destination_city = '杭州'
      @max_budget = 2000
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = Passenger.find_by!(user_id: demo_user.id, is_self: true, data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_passenger.name,
        id_number: demo_passenger.id_number,
        phone: demo_passenger.phone
      )
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).to_a
      
      @available_trains = Train.by_route(@departure_city, @destination_city)
        .where(data_version: 0)
        .to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0).to_a
      
      raise "未找到交通或酒店" if (@available_flights.empty? && @available_trains.empty?) || @available_hotels.empty?
      
      @travel_date = (@available_flights.first&.flight_date || @available_trains.first&.departure_time&.to_date || Date.current)
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 1.day
      
      # 计算预算内最高评分参考值
      best_quality_in_budget = 0
      @available_flights.each do |f|
        @available_hotels.each do |h|
          room = h.hotel_rooms.where(data_version: 0).first
          next unless room
          total = f.price + h.price
          next if total > @max_budget
          quality = h.rating  # 用酒店评分作为质量指标
          best_quality_in_budget = [best_quality_in_budget, quality].max
        end
      end
      
      @available_trains.each do |t|
        @available_hotels.each do |h|
          room = h.hotel_rooms.where(data_version: 0).first
          next unless room
          total = t.price_second_class + h.price
          next if total > @max_budget
          quality = h.rating
          best_quality_in_budget = [best_quality_in_budget, quality].max
        end
      end
      
      @reference_quality = best_quality_in_budget
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@destination_city}的交通和酒店（住1晚），总预算≤#{@max_budget}元，在预算内选择服务档次最高的组合（优先考虑酒店评分）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          travel_date: @travel_date,
          max_budget: "≤#{@max_budget}元",
          optimization: '预算内最高档次'
        },
        hint: "预算有限#{@max_budget}元，优先选择高评分酒店，交通可以选航班或火车。"
      }
    end
    
    def verify
      add_assertion "创建了交通订单（航班或火车）", weight: 15 do
        @flight_booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        @train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        @transport_booking = @flight_booking || @train_booking
        @transport_type = @flight_booking ? 'flight' : 'train'
        expect(@transport_booking).not_to be_nil, "未找到交通订单"
      end
      
      return if @transport_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "出行日期正确（#{@travel_date}）", weight: 10 do
        if @transport_type == 'flight'
          expect(@transport_booking.flight.flight_date).to eq(@travel_date),
            "航班日期错误。期望: #{@travel_date}, 实际: #{@transport_booking.flight.flight_date}"
        else
          train_date = @transport_booking.train.departure_time.to_date
          expect(train_date).to eq(@travel_date),
            "火车日期错误。期望: #{@travel_date}, 实际: #{train_date}"
        end
      end
      
      add_assertion "酒店入住日期正确（入住#{@check_in_date}，退房#{@check_out_date}）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "乘客信息正确（姓名、身份证、手机号）", weight: 5 do
        expect(@transport_booking.passenger_name).to eq(@passenger.name),
          "乘客姓名错误。期望: #{@passenger.name}, 实际: #{@transport_booking.passenger_name}"
        expect(@transport_booking.passenger_id_number).to eq(@passenger.id_number),
          "身份证号错误。期望: #{@passenger.id_number}, 实际: #{@transport_booking.passenger_id_number}"
        expect(@transport_booking.contact_phone).to eq(@passenger.phone),
          "联系电话错误。期望: #{@passenger.phone}, 实际: #{@transport_booking.contact_phone}"
      end
      
      add_assertion "入住人信息正确（姓名、手机号）", weight: 5 do
        demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
        expect(@hotel_booking.guest_name).to eq(demo_user.name),
          "入住人姓名错误。期望: #{demo_user.name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@passenger.phone),
          "入住人电话错误。期望: #{@passenger.phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "总价格≤#{@max_budget}元", weight: 15 do
        transport_price = @transport_booking.total_price
        hotel_price = @hotel_booking.total_price
        total_price = transport_price + hotel_price
        
        expect(total_price).to be <= @max_budget,
          "总价格超出预算。交通: #{transport_price}元, 酒店: #{hotel_price}元, 总计: #{total_price}元, 预算上限: #{@max_budget}元"
      end
      
      add_assertion "在预算内选择了评分最高或接近最高的组合", weight: 20 do
        hotel = @hotel_booking.hotel
        actual_quality = hotel.rating
        
        # 允许0.5星的偏差
        expect(actual_quality).to be >= @reference_quality - 0.5,
          "未选择预算内最高档次。预算内最高评分: #{@reference_quality}星, 实际选择: #{actual_quality}星"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@transport_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 在预算内找到评分最高的组合
      best_combo = nil
      best_quality = 0
      
      # 尝试航班组合
      @available_flights.each do |flight|
        @available_hotels.each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).first
          next unless room
          
          total = flight.price + room.price
          next if total > @max_budget
          
          quality = hotel.rating
          if quality > best_quality
            best_quality = quality
            best_combo = { type: :flight, transport: flight, hotel: hotel, room: room }
          end
        end
      end
      
      # 尝试火车组合
      @available_trains.each do |train|
        @available_hotels.each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).first
          next unless room
          
          total = train.price_second_class + room.price
          next if total > @max_budget
          
          quality = hotel.rating
          if quality > best_quality
            best_quality = quality
            best_combo = { type: :train, transport: train, hotel: hotel, room: room }
          end
        end
      end
      
      raise "未找到预算内的组合" if best_combo.nil?
      
      # 创建交通订单
      if best_combo[:type] == :flight
        Booking.create!(
          user: user,
          flight: best_combo[:transport],
          passenger_name: @passenger.name,
          passenger_id_number: @passenger.id_number,
          contact_phone: @passenger.phone,
          total_price: best_combo[:transport].price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      else
        TrainBooking.create!(
          user: user,
          train: best_combo[:transport],
          passenger_name: @passenger.name,
          passenger_id_number: @passenger.id_number,
          contact_phone: @passenger.phone,
          seat_type: 'second_class',
          ticket_count: 1,
          total_price: best_combo[:transport].price_second_class,
          status: 'paid',
          accept_terms: true,
          data_version: @data_version
        )
      end
      
      # 创建酒店订单
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel],
        hotel_room: best_combo[:room],
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: @passenger.phone,
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
        destination_city: @destination_city,
        travel_date: @travel_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        max_budget: @max_budget,
        reference_quality: @reference_quality,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        passenger_phone: @passenger.phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @travel_date = Date.parse(data['travel_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @max_budget = data['max_budget'].to_i
      @reference_quality = data['reference_quality'].to_f
      
      @passenger = OpenStruct.new(
        name: data['passenger_name'],
        id_number: data['passenger_id_number'],
        phone: data['passenger_phone']
      )
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @travel_date,
        data_version: 0
      ).to_a
      
      @available_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0).to_a
    end
  end
end
