# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例189: 预订总价最低的交通+酒店组合
#
# 任务描述:
#   预订总价最低的往返交通+酒店组合
#
# 评分标准:
#   - 创建了交通订单和酒店订单 (20%)
#   - 出发/到达城市正确 (15%)
#   - 酒店城市正确 (10%)
#   - 日期合理 (15%)
#   - 总价最低或接近最低价（允许5%误差） (40%)
module V151V200
  class V189BookCheapestComboOptimizeTotalPriceValidator < BaseValidator
    self.validator_id = 'v189_book_cheapest_combo_optimize_total_price_validator'
    self.task_id = 'bba54fa4-35b4-4a29-942d-dd4d80abcd6d'
    self.title = '预订后天总价最低的交通+酒店组合（1人）'
    self.description = '预订总价最低的往返交通+酒店组合'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.tomorrow + 1.day
      @stay_nights = 2
      
      # 查找所有交通选项（航班+火车）
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select { |f| f.departure_time.to_date == @travel_date }
        .to_a
      
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .select { |t| t.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_flights.any? || @available_trains.any?).to be_truthy,
        "数据包缺少#{@departure_city}→#{@arrival_city}的交通工具（#{@travel_date}）"
      
      # 边界检查: 至少有一个类别包含多个选项，以便优化比较
      if @available_flights.size == 1 && @available_trains.empty?
        puts "警告: 仅有1个航班选项，无法进行价格优化比较"
      elsif @available_trains.size == 1 && @available_flights.empty?
        puts "警告: 仅有1个火车选项，无法进行价格优化比较"
      end
      
      # 查找所有酒店
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).to_a
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      expect(@available_hotels.size).to be >= 2,
        "数据包中酒店数量不足（仅#{@available_hotels.size}家），无法进行价格优化比较。至少需要2家酒店。"
      
      # 计算最低组合价格
      @min_combo_price = calculate_min_combo_price
      
      {
        task: "请预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的往返交通+住宿#{@stay_nights}晚，要求总价最低",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        stay_nights: @stay_nights,
        optimization_target: '总价最低',
        hint: "系统中有#{@available_flights.size}个航班、#{@available_trains.size}个火车车次、#{@available_hotels.size}家酒店可选，请选择总价最低的组合"
      }
    end
    
    def verify
      # 断言1: 创建了交通订单和酒店订单 (20%)
      add_assertion "创建了交通订单和酒店订单", weight: 20 do
        # 查询航班订单
        @flight_booking = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        # 查询火车订单
        @train_booking = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        has_transportation = @flight_booking.present? || @train_booking.present?
        expect(has_transportation).to be(true), "未找到交通订单（#{@departure_city}→#{@arrival_city}）"
        
        # 查询酒店订单
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（#{@arrival_city}）"
      end
      
      return if (@flight_booking.nil? && @train_booking.nil?) || @hotel_booking.nil?
      
      # 断言2: 出发/到达城市正确 (15%)
      add_assertion "出发/到达城市正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        if @flight_booking
          flight = @flight_booking.flight
          expect(flight.departure_city).to eq(@departure_city)
          expect(flight.destination_city).to eq(@arrival_city)
        elsif @train_booking
          train = @train_booking.train
          expect(train.departure_city).to eq(@departure_city)
          expect(train.arrival_city).to eq(@arrival_city)
        end
      end
      
      # 断言3: 酒店城市正确 (10%)
      add_assertion "酒店城市正确（#{@arrival_city}）", weight: 10 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to eq(@arrival_city)
      end
      
      # 断言4: 日期合理 (15%)
      add_assertion "日期合理", weight: 15 do
        if @flight_booking
          arrival_date = @flight_booking.flight.arrival_time.to_date
        elsif @train_booking
          arrival_date = @train_booking.train.arrival_time.to_date
        end
        
        checkin_date = @hotel_booking.check_in_date
        expect([arrival_date, arrival_date + 1.day]).to include(checkin_date),
          "入住日期不合理。交通到达: #{arrival_date}, 酒店入住: #{checkin_date}"
      end
      
      # 断言5: 总价最低或接近最低价（允许5%误差） (40%)
      add_assertion "总价最低或接近最低价（允许5%误差）", weight: 40 do
        transportation_price = @flight_booking ? @flight_booking.total_price.to_f : @train_booking.total_price.to_f
        hotel_price = @hotel_booking.total_price.to_f
        actual_total = transportation_price + hotel_price
        
        allowed_max = @min_combo_price.to_f * 1.05
        expect(actual_total).to be <= allowed_max,
          "总价不是最优。期望: ≤#{allowed_max.round(2)}元（最低价#{@min_combo_price.to_f.round(2)}+5%误差）, 实际: #{actual_total.round(2)}元"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到最低价的交通工具
      cheapest_transport = find_cheapest_transportation
      
      # 找到最低价的酒店
      cheapest_hotel = @available_hotels.min_by(&:price)
      
      # 创建交通订单
      if cheapest_transport[:type] == :flight
        flight = cheapest_transport[:data]
        Booking.create!(
          user: user,
          flight_id: flight.id,
          passenger_name: user.name,
          passenger_id_number: '110101199001011234',
          contact_phone: '13800138000',
          total_price: flight.price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
        arrival_date = flight.arrival_time.to_date
      else
        train = cheapest_transport[:data]
        TrainBooking.create!(
          user: user,
          train: train,
          passenger_name: user.name,
          passenger_id_number: '110101199001011234',
          seat_type: 'second_class',
          contact_phone: '13800138000',
          total_price: train.price_second_class,
          accept_terms: true,
          data_version: @data_version
        )
        arrival_date = train.arrival_time.to_date
      end
      
      # 创建酒店订单
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      # 选择整晚房最低价的酒店
      cheapest_hotel = @available_hotels.min_by do |hotel|
        hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').minimum(:price) || Float::INFINITY
      end
      
      room = cheapest_hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
      unless room
        room = HotelRoom.create!(
          hotel_id: cheapest_hotel.id,
          room_type: '标准双人间',
          bed_type: 'double',
          price: cheapest_hotel.price,
          original_price: cheapest_hotel.original_price,
          area: 25.0,
          max_guests: 2,
          has_window: true,
          available_rooms: 10,
          room_category: 'standard',
          data_version: 0
        )
      end
      
      HotelBooking.create!(
        user: user,
        hotel_id: cheapest_hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
        check_out_date: arrival_date + @stay_nights.days,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: room.price * @stay_nights,
        data_version: @data_version
      )
    end
    
    private
    
    def calculate_min_combo_price
      min_flight_price = @available_flights.any? ? @available_flights.min_by(&:price).price.to_f : Float::INFINITY
      min_train_price = @available_trains.any? ? @available_trains.min_by(&:price_second_class).price_second_class.to_f : Float::INFINITY
      min_transport = [min_flight_price, min_train_price].min
      
      # CRITICAL: 使用整晚房最低价，不是Hotel.price（可能是钟点房）
      min_hotel_overnight_price = @available_hotels.map do |hotel|
        hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').minimum(:price) || Float::INFINITY
      end.min
      
      min_transport + (min_hotel_overnight_price * @stay_nights)
    end
    
    def find_cheapest_transportation
      min_flight_price = @available_flights.any? ? @available_flights.min_by(&:price).price.to_f : Float::INFINITY
      min_train_price = @available_trains.any? ? @available_trains.min_by(&:price_second_class).price_second_class.to_f : Float::INFINITY
      
      if min_flight_price <= min_train_price
        { type: :flight, data: @available_flights.min_by(&:price) }
      else
        { type: :train, data: @available_trains.min_by(&:price_second_class) }
      end
    end
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date&.to_s,
        stay_nights: @stay_nights,
        min_combo_price: @min_combo_price
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @stay_nights = data['stay_nights']
      @min_combo_price = data['min_combo_price']
    end
  end
end
