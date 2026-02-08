# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例197: 预订火车+火车站1公里内酒店
#
# 任务描述:
#   预订火车+火车站1公里内酒店（步行可达）
#
# 评分标准:
#   - 创建了火车订单 (25%)
#   - 创建了酒店订单 (25%)
#   - 酒店在火车站附近（≤1公里） (30%)
#   - 出发/到达城市正确 (10%)
#   - 日期合理 (10%)
module V151V200
  class V197BookTrainAndStationVicinityHotelValidator < BaseValidator
    self.validator_id = 'v197_book_train_and_station_vicinity_hotel_validator'
    self.task_id = '23d8d144-0925-4316-8fec-88215475aef4'
    self.title = '预订3天后火车+火车站1公里内酒店'
    self.description = '预订火车+火车站1公里内酒店（步行可达）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.tomorrow + 2.days
      @max_distance = 1.0  # 公里
      
      # 查找火车
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .select { |t| t.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_trains).not_to be_empty,
        "数据包缺少#{@departure_city}→#{@arrival_city}的火车（#{@travel_date}）"
      
      # 查找火车站附近酒店
      @station_hotels = Hotel
        .where(city: @arrival_city, data_version: 0)
        .select { |h| is_near_station?(h) }
        .to_a
      
      if @station_hotels.empty?
        # 如果没有明确标记的车站酒店，选择距离最近的
        @station_hotels = Hotel
          .where(city: @arrival_city, data_version: 0)
          .select { |h| h.distance && h.distance <= @max_distance }
          .to_a
      end
      
      expect(@station_hotels).not_to be_empty,
        "数据包缺少#{@arrival_city}火车站附近（≤#{@max_distance}公里）的酒店"
      
      {
        task: "请预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的火车，并预订火车站#{@max_distance}公里内的酒店（步行可达）",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        max_distance: @max_distance,
        hint: "选择火车站附近的酒店，方便步行到达"
      }
    end
    
    def verify
      # 断言1: 创建了火车订单 (25%)
      add_assertion "创建了火车订单", weight: 25 do
        @train_booking = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@train_booking).not_to be_nil, "未找到火车订单"
      end
      
      return if @train_booking.nil?
      
      # 断言2: 创建了酒店订单 (25%)
      add_assertion "创建了酒店订单", weight: 25 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言3: 酒店在火车站附近（≤1公里） (30%)
      add_assertion "酒店在火车站附近（≤#{@max_distance}公里）", weight: 30 do
        hotel = @hotel_booking.hotel
        is_station_hotel = is_near_station?(hotel) ||
                          (hotel.distance && hotel.distance <= @max_distance)
        
        expect(is_station_hotel).to be(true),
          "酒店不在火车站附近。酒店: #{hotel.name}（距离#{hotel.distance}公里），要求: ≤#{@max_distance}公里"
      end
      
      # 断言4: 出发/到达城市正确 (10%)
      add_assertion "出发/到达城市正确", weight: 10 do
        train = @train_booking.train
        hotel = @hotel_booking.hotel
        expect(train.departure_city).to eq(@departure_city)
        expect(train.arrival_city).to eq(@arrival_city)
        expect(hotel.city).to eq(@arrival_city)
      end
      
      # 断言5: 日期合理 (10%)
      add_assertion "日期合理", weight: 10 do
        arrival_date = @train_booking.train.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        expect([arrival_date, arrival_date + 1.day]).to include(checkin_date)
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择火车
      train = @available_trains.min_by(&:price_second_class)
      
      # 创建火车订单
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
      
      # 选择车站酒店
      station_hotel = @station_hotels.min_by(&:price)
      room = station_hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      arrival_date = train.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: station_hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
        check_out_date: arrival_date + 1.day,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
    
    private
    
    def is_near_station?(hotel)
      return true if hotel.hotel_type&.include?('火车站')
      return true if hotel.hotel_type&.include?('车站')
      return true if hotel.name&.include?('火车站')
      return true if hotel.name&.include?('车站')
      return true if hotel.address&.include?('火车站')
      return true if hotel.address&.include?('车站')
      return true if hotel.features&.include?('火车站')
      return true if hotel.features&.include?('车站')
      false
    end
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date&.to_s,
        max_distance: @max_distance
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @max_distance = data['max_distance']
    end
  end
end
