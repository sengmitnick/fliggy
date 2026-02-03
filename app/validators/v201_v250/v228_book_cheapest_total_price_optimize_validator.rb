# frozen_string_literal: true

require_relative '../base_validator'

# V228: 预订往返交通+酒店（总价最低组合）
#
# 任务描述:
#   用户需要预订往返交通+酒店，选择总价最低的组合
#
# 评分标准:
#   - 创建了去程交通订单 (15%)
#   - 创建了返程交通订单 (15%)
#   - 创建了酒店订单 (15%)
#   - 选择了总价最低或接近最低的组合 (40%)
#   - 订单状态有效 (15%)
module V201V250
  class V228BookCheapestTotalPriceOptimizeValidator < BaseValidator
    self.validator_id = 'v228_book_cheapest_total_price_optimize_validator'
    self.task_id = 'b2c3d4e5-6f7a-8b9c-0d1e-2f3a4b5c6d7e'
    self.title = '预订往返交通+酒店（总价最低组合）'
    self.description = '用户需要预订往返交通+酒店，选择总价最低的组合'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '北京'
      @outbound_date = Date.today + 3.days
      @return_date = @outbound_date + 2.days
      @check_in_date = @outbound_date
      @check_out_date = @return_date
      
      # 查找去程航班（可以选择火车或航班）
      @outbound_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @outbound_date,
        data_version: 0
      ).order(price: :asc)
      
      @outbound_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@outbound_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      # 查找返程航班/火车
      @return_flights = Flight.where(
        departure_city: @destination_city,
        destination_city: @departure_city,
        flight_date: @return_date,
        data_version: 0
      ).order(price: :asc)
      
      @return_trains = Train.by_route(@destination_city, @departure_city)
        .by_date(@return_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      # 查找酒店
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).order(price: :asc)
      
      raise "未找到符合条件的交通或酒店" if (@outbound_flights.empty? && @outbound_trains.empty?) || 
                                           (@return_flights.empty? && @return_trains.empty?) || 
                                           @available_hotels.empty?
      
      {
        task: "请预订#{@outbound_date.strftime('%Y年%m月%d日')}（3天后）从#{@departure_city}到#{@destination_city}的往返交通（#{@return_date.strftime('%Y年%m月%d日')}返回），并预订#{@destination_city}的酒店（住2晚）。请选择总价最低的组合（可以是航班或火车）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          outbound_date: @outbound_date,
          return_date: @return_date,
          check_in_date: @check_in_date,
          nights: 2,
          optimization: '总价最低'
        },
        hint: "需要计算【去程交通+返程交通+酒店2晚】的总价，选择最便宜的组合。可以混合选择航班和火车。"
      }
    end
    
    def verify
      add_assertion "创建了去程交通订单", weight: 15 do
        # 查找航班或火车订单
        @outbound_flight_booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        @outbound_train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        @outbound_booking = @outbound_flight_booking || @outbound_train_booking
        expect(@outbound_booking).not_to be_nil, "未找到从#{@departure_city}到#{@destination_city}的去程交通订单"
      end
      
      return if @outbound_booking.nil?
      
      add_assertion "创建了返程交通订单", weight: 15 do
        @return_flight_booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @destination_city, destination_city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        @return_train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @destination_city, arrival_city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        @return_booking = @return_flight_booking || @return_train_booking
        expect(@return_booking).not_to be_nil, "未找到从#{@destination_city}到#{@departure_city}的返程交通订单"
      end
      
      return if @return_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 15 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_hotel_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@destination_city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "选择了总价最低或接近最低的组合（前20%）", weight: 40 do
        outbound_price = @outbound_booking.total_price
        return_price = @return_booking.total_price
        hotel_price = @hotel_booking.total_price
        actual_total = outbound_price + return_price + hotel_price
        
        # 计算理论最低价格
        min_outbound = [@outbound_flights.first&.price || Float::INFINITY,
                        @outbound_trains.first&.price_second_class || Float::INFINITY].min
        min_return = [@return_flights.first&.price || Float::INFINITY,
                      @return_trains.first&.price_second_class || Float::INFINITY].min
        min_hotel_room = @available_hotels.first.hotel_rooms.where(data_version: 0).order(price: :asc).first
        min_hotel_price = min_hotel_room ? min_hotel_room.price * 2 : Float::INFINITY
        
        theoretical_min = min_outbound + min_return + min_hotel_price
        
        # 允许20%的偏差（考虑到可能的优化选择）
        acceptable_max = theoretical_min * 1.2
        
        expect(actual_total).to be <= acceptable_max,
          "总价未达到最优。实际总价: #{actual_total}元（去程#{outbound_price}+返程#{return_price}+酒店#{hotel_price}）, 理论最低: #{theoretical_min}元, 可接受上限: #{acceptable_max}元"
      end
      
      add_assertion "订单状态有效", weight: 15 do
        expect(@outbound_booking.status).to be_in(['pending', 'paid', 'completed']),
          "去程订单状态异常。实际状态: #{@outbound_booking.status}"
        expect(@return_booking.status).to be_in(['pending', 'paid', 'completed']),
          "返程订单状态异常。实际状态: #{@return_booking.status}"
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "酒店订单状态异常。实际状态: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到最便宜的组合
      best_combo = nil
      best_price = Float::INFINITY
      
      # 遍历去程选择（航班或火车）
      outbound_options = []
      @outbound_flights.first(5).each { |f| outbound_options << { type: :flight, item: f, price: f.price } }
      @outbound_trains.first(5).each { |t| outbound_options << { type: :train, item: t, price: t.price_second_class } }
      
      # 遍历返程选择
      return_options = []
      @return_flights.first(5).each { |f| return_options << { type: :flight, item: f, price: f.price } }
      @return_trains.first(5).each { |t| return_options << { type: :train, item: t, price: t.price_second_class } }
      
      # 遍历酒店选择
      hotel_options = @available_hotels.first(5).map do |hotel|
        room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
        next unless room
        { hotel: hotel, room: room, price: room.price * 2 }  # 2晚
      end.compact
      
      # 找最便宜组合
      outbound_options.each do |outbound|
        return_options.each do |ret|
          hotel_options.each do |hotel_opt|
            total = outbound[:price] + ret[:price] + hotel_opt[:price]
            if total < best_price
              best_price = total
              best_combo = { outbound: outbound, return: ret, hotel: hotel_opt }
            end
          end
        end
      end
      
      raise "未找到符合条件的组合" if best_combo.nil?
      
      # 创建去程订单
      if best_combo[:outbound][:type] == :flight
        Booking.create!(
          user: user,
          flight: best_combo[:outbound][:item],
          passenger_name: user.name,
          passenger_id_number: '110101199001011234',
          contact_phone: '13800138000',
          total_price: best_combo[:outbound][:item].price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      else
        TrainBooking.create!(
          user: user,
          train: best_combo[:outbound][:item],
          passenger_name: user.name,
          passenger_id_number: '110101199001011234',
          contact_phone: '13800138000',
          seat_type: 'second_class',
          ticket_count: 1,
          total_price: best_combo[:outbound][:item].price_second_class,
          status: 'paid',
          accept_terms: true,
          data_version: @data_version
        )
      end
      
      # 创建返程订单
      if best_combo[:return][:type] == :flight
        Booking.create!(
          user: user,
          flight: best_combo[:return][:item],
          passenger_name: user.name,
          passenger_id_number: '110101199001011234',
          contact_phone: '13800138000',
          total_price: best_combo[:return][:item].price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      else
        TrainBooking.create!(
          user: user,
          train: best_combo[:return][:item],
          passenger_name: user.name,
          passenger_id_number: '110101199001011234',
          contact_phone: '13800138000',
          seat_type: 'second_class',
          ticket_count: 1,
          total_price: best_combo[:return][:item].price_second_class,
          status: 'paid',
          accept_terms: true,
          data_version: @data_version
        )
      end
      
      # 创建酒店订单
      HotelBooking.create!(
        user: user,
        hotel: best_combo[:hotel][:hotel],
        hotel_room_id: best_combo[:hotel][:room].id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: best_combo[:hotel][:room].price * 2,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        outbound_date: @outbound_date.to_s,
        return_date: @return_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @outbound_date = Date.parse(data['outbound_date'])
      @return_date = Date.parse(data['return_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      
      @outbound_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @outbound_date,
        data_version: 0
      ).order(price: :asc)
      
      @outbound_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@outbound_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @return_flights = Flight.where(
        departure_city: @destination_city,
        destination_city: @departure_city,
        flight_date: @return_date,
        data_version: 0
      ).order(price: :asc)
      
      @return_trains = Train.by_route(@destination_city, @departure_city)
        .by_date(@return_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
      
      @available_hotels = Hotel.where(
        city: @destination_city,
        data_version: 0
      ).order(price: :asc)
    end
  end
end
