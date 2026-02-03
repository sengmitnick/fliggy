# frozen_string_literal: true

require_relative '../base_validator'

# V231: 预订增量升级（加100元升级服务）
#
# 任务描述:
#   用户先查找基础方案，然后加100元升级到更好服务（如从经济舱升商务舱、经济型酒店升高星酒店）
#
# 评分标准:
#   - 创建了交通订单 (20%)
#   - 创建了酒店订单 (20%)
#   - 总价比基础方案多约100元（±50元） (30%)
#   - 服务档次有明显提升（评分提高或舱位升级） (20%)
#   - 订单状态有效 (10%)
module V201V250
  class V231BookIncrementalUpgrade100MoreValidator < BaseValidator
    self.validator_id = 'v231_book_incremental_upgrade_100_more_validator'
    self.task_id = '7ff798ff-8f8f-8f0f-0f1f-9f2a3b4c5d6f'
    self.title = '预订增量升级（加100元升级服务）'
    self.description = '用户先查找基础方案，然后加100元升级到更好服务（如从经济舱升商务舱、经济型酒店升高星酒店）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '成都'
      @destination_city = '重庆'
      @travel_date = Date.today + 1.day
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 1.day
      @upgrade_budget = 100
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @travel_date,
        data_version: 0
      ).order(price: :asc).to_a
      
      @available_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
        .to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0)
        .order(price: :asc)
        .to_a
      
      raise "未找到交通或酒店" if (@available_flights.empty? && @available_trains.empty?) || @available_hotels.empty?
      
      # 计算基础方案价格（最便宜的组合）
      min_transport_price = [
        @available_flights.first&.price || Float::INFINITY,
        @available_trains.first&.price_second_class || Float::INFINITY
      ].min
      
      min_hotel_room = @available_hotels.first.hotel_rooms.where(data_version: 0).order(price: :asc).first
      min_hotel_price = min_hotel_room ? min_hotel_room.price : Float::INFINITY
      
      @base_price = min_transport_price + min_hotel_price
      @target_price = @base_price + @upgrade_budget
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@destination_city}的交通和酒店（住1晚）。基础方案约#{@base_price.round}元，请在此基础上加#{@upgrade_budget}元（预算#{@target_price.round}元）升级到更好的服务（如更高星级酒店或更快交通）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          travel_date: @travel_date,
          base_price: "约#{@base_price.round}元",
          target_price: "约#{@target_price.round}元",
          upgrade_budget: "+#{@upgrade_budget}元",
          purpose: '增量升级服务'
        },
        hint: "基础方案是最便宜的组合，加#{@upgrade_budget}元可以升级到更好的服务。"
      }
    end
    
    def verify
      add_assertion "创建了交通订单", weight: 20 do
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
        expect(@transport_booking).not_to be_nil, "未找到交通订单"
      end
      
      return if @transport_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "总价比基础方案多约#{@upgrade_budget}元（允许±50元）", weight: 30 do
        transport_price = @transport_booking.total_price
        hotel_price = @hotel_booking.total_price
        actual_total = transport_price + hotel_price
        
        price_increase = actual_total - @base_price
        
        expect(price_increase).to be >= @upgrade_budget - 50,
          "升级金额不足。基础方案: #{@base_price.round}元, 实际总价: #{actual_total.round}元, 增加: #{price_increase.round}元, 期望增加: #{@upgrade_budget}元（±50元）"
        expect(price_increase).to be <= @upgrade_budget + 50,
          "升级金额过多。基础方案: #{@base_price.round}元, 实际总价: #{actual_total.round}元, 增加: #{price_increase.round}元, 期望增加: #{@upgrade_budget}元（±50元）"
      end
      
      add_assertion "服务档次有明显提升", weight: 20 do
        hotel = @hotel_booking.hotel
        min_hotel = @available_hotels.first
        
        rating_upgrade = hotel.rating - min_hotel.rating
        
        expect(rating_upgrade).to be >= 0.1,
          "酒店档次提升不明显。基础酒店: #{min_hotel.name}（#{min_hotel.rating}星）, 实际选择: #{hotel.name}（#{hotel.rating}星）, 提升: #{rating_upgrade}星"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@transport_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到价格在目标范围内且档次提升的组合
      best_combo = nil
      best_rating_upgrade = 0
      min_hotel_rating = @available_hotels.first.rating
      
      # 尝试航班组合
      @available_flights.first(5).each do |flight|
        @available_hotels.first(10).each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).first
          next unless room
          
          total = flight.price + room.price
          price_increase = total - @base_price
          
          # 检查是否在升级预算范围内（±50元）
          next unless price_increase >= (@upgrade_budget - 50) && price_increase <= (@upgrade_budget + 50)
          
          rating_upgrade = hotel.rating - min_hotel_rating
          next unless rating_upgrade >= 0.1
          
          if rating_upgrade > best_rating_upgrade
            best_rating_upgrade = rating_upgrade
            best_combo = { type: :flight, transport: flight, hotel: hotel, room: room }
          end
        end
      end
      
      # 尝试火车组合
      @available_trains.first(5).each do |train|
        @available_hotels.first(10).each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).first
          next unless room
          
          total = train.price_second_class + room.price
          price_increase = total - @base_price
          
          next unless price_increase >= (@upgrade_budget - 50) && price_increase <= (@upgrade_budget + 50)
          
          rating_upgrade = hotel.rating - min_hotel_rating
          next unless rating_upgrade >= 0.1
          
          if rating_upgrade > best_rating_upgrade
            best_rating_upgrade = rating_upgrade
            best_combo = { type: :train, transport: train, hotel: hotel, room: room }
          end
        end
      end
      
      raise "未找到符合升级要求的组合" if best_combo.nil?
      
      # 创建交通订单
      if best_combo[:type] == :flight
        Booking.create!(
          user: user,
          flight: best_combo[:transport],
          passenger_name: user.name,
          passenger_id_number: '110101199001011234',
          contact_phone: '13800138000',
          total_price: best_combo[:transport].price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      else
        TrainBooking.create!(
          user: user,
          train: best_combo[:transport],
          passenger_name: user.name,
          passenger_id_number: '110101199001011234',
          contact_phone: '13800138000',
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
        guest_phone: '13800138000',
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
        base_price: @base_price,
        target_price: @target_price,
        upgrade_budget: @upgrade_budget
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @travel_date = Date.parse(data['travel_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @base_price = data['base_price'].to_f
      @target_price = data['target_price'].to_f
      @upgrade_budget = data['upgrade_budget'].to_i
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @travel_date,
        data_version: 0
      ).order(price: :asc).to_a
      
      @available_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
        .to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0)
        .order(price: :asc)
        .to_a
    end
  end
end
