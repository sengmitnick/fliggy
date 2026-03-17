# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例197: 给吴勇预订明天北京到上海的火车+火车站1公里内酒店
#
# 任务描述：
#   为吴勇预订明天从北京到上海的火车+火车站附近酒店（步行可达，便于赶车或到达后休息）
#
# 核心要求：
#   - 乘客：吴勇（1人）
#   - 出发日期：明天（Date.current + 1.day）
#   - 路线：北京 → 上海
#   - 住宿：1晚（入住日期=火车到达日期）
#   - 酒店位置：距离上海火车站 ≤ 1公里（步行可达）
#   - 价格策略：选择火车站附近的酒店和火车
#
# 业务流程：
#   1. 查询明天北京→上海的所有火车
#   2. 查询上海火车站附近的酒店（距离 ≤ 1公里）
#   3. 选择火车
#   4. 选择火车站酒店房间（整晚房）
#   5. 创建火车订单
#   6. 创建酒店订单（入住日期=火车到达日期，住1晚）
#
# 复杂度分析：
#   - 位置筛选：需要过滤出火车站附近的酒店（distance ≤ 1km）
#   - 距离判断：优先文本匹配（酒店名称/地址包含"火车站"/"车站"），备用distance字段
#   - 价格优化：选择火车站附近的酒店（重点是位置，不是价格）
#   - 注意事项：必须过滤room_category='overnight'，排除钟点房
#
# 评分标准（总分100分）：
#   1. 创建了火车订单(25分)
#   2. 创建了酒店订单(25分)
#   3. 酒店在火车站附近（≤1公里）(15分)
#   4. 出发/到达城市正确(10分)
#   5. 乘客和入住人信息正确（吴勇）(15分)
#   6. 日期合理(10分)
#
# 验证要点：
#   - 火车/酒店订单已创建
#   - 酒店距离火车站 ≤ 1公里
#   - 出发/到达城市正确（北京 → 上海）
#   - 乘客和入住人信息正确（吴勇）
#   - 入住日期为火车到达日期或次日
module V151V200
  class V197BookTrainAndStationVicinityHotelValidator < BaseValidator
    self.validator_id = 'v197_book_train_and_station_vicinity_hotel_validator'
    self.task_id = '23d8d144-0925-4316-8fec-88215475aef4'
    self.title = '给吴勇预订明天北京到上海的火车+火车站1公里内酒店'
    self.description = '帮吴勇订明天从北京到上海的火车，并预订火车站1公里内的酒店（步行可达）'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '吴勇')
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.current + 1.day  # 明天
      @max_distance = 1.0  # 公里
      
      # 查找火车
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .select { |t| t.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_trains).not_to be_empty,
        "数据包缺少#{@departure_city}→#{@arrival_city}的火车（#{@travel_date}）"
      
      # 查找火车站附近酒店（优先距离验证）
      # CRITICAL: 必须先用距离≤1km过滤，不能仅依赖名称
      @station_hotels = Hotel
        .where(city: @arrival_city, data_version: 0)
        .select { |h| h.distance.present? && h.distance.to_s.gsub(/[^0-9.]/, '').to_f <= @max_distance }
        .to_a
      
      if @station_hotels.empty?
        # 如果没有明确标记距离的酒店，才使用名称匹配作为备用
        @station_hotels = Hotel
          .where(city: @arrival_city, data_version: 0)
          .select { |h| is_near_station?(h) }
          .to_a
      end
      
      expect(@station_hotels).not_to be_empty,
        "数据包缺少#{@arrival_city}火车站附近（≤#{@max_distance}公里）的酒店"
      
      {
        task: "请为#{@passenger.name}预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的火车，并预订火车站#{@max_distance}公里内的酒店（步行可达）",
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
      
      # 断言3: 酒店在火车站附近（≤1公里） (15%)
      add_assertion "酒店在火车站附近（≤#{@max_distance}公里）", weight: 15 do
        hotel = @hotel_booking.hotel
        
        # CRITICAL: 必须验证distance字段 ≤ 1.0km
        if hotel.distance.present?
          distance_km = hotel.distance.to_s.gsub(/[^0-9.]/, '').to_f
          expect(distance_km).to be <= @max_distance,
            "酒店不在火车站附近。酒店: #{hotel.name}（距离#{distance_km}公里），要求: ≤#{@max_distance}公里"
        else
          # 如果没有distance字段，则检查是否为车站酒店（备用逻辑）
          is_station_hotel = is_near_station?(hotel)
          expect(is_station_hotel).to be(true),
            "酒店不在火车站附近。酒店: #{hotel.name}，未找到距离信息，且名称不包含'火车站'或'车站'"
        end
      end
      
      # 断言4: 出发/到达城市正确 (10%)
      add_assertion "出发/到达城市正确", weight: 10 do
        train = @train_booking.train
        hotel = @hotel_booking.hotel
        expect(train.departure_city).to eq(@departure_city)
        expect(train.arrival_city).to eq(@arrival_city)
        expect(hotel.city).to eq(@arrival_city)
      end
      
      # 断言5: 乘客和入住人信息正确（吴勇） (15%)
      add_assertion "乘客和入住人信息正确（#{@expected_passenger_name}）", weight: 15 do
        # 检查火车票乘客姓名
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "火车票乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        
        # 检查火车票联系人
        expect(@train_booking.contact_phone).to eq(@expected_phone),
          "火车票联系人电话错误。期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
        
        # 检查酒店入住人
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言6: 日期合理 (10%)
      add_assertion "日期合理", weight: 10 do
        arrival_date = @train_booking.train.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        expect([arrival_date, arrival_date + 1.day]).to include(checkin_date)
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '吴勇')  # 移除 data_version: 0
      
      # 选择火车
      train = @available_trains.min_by(&:price_second_class)
      
      # 创建火车订单
      TrainBooking.create!(
        user: user,
        train: train,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        seat_type: 'second_class',
        contact_phone: passenger.phone,
        total_price: train.price_second_class,
        accept_terms: true,
        data_version: @data_version
      )
      
      # 选择车站酒店
      station_hotel = @station_hotels.min_by(&:price)
      # CRITICAL: 必须过滤room_category='overnight'，排除钟点房
      room = station_hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      arrival_date = train.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: station_hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
        check_out_date: arrival_date + 1.day,
        guest_name: user.name,
        guest_phone: passenger.phone,
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
        max_distance: @max_distance,
        station_hotel_ids: @station_hotels&.map(&:id)
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '吴勇')  # 移除 data_version: 0
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @max_distance = data['max_distance']
      
      # 恢复station_hotels
      if data['station_hotel_ids']
        @station_hotels = Hotel.where(id: data['station_hotel_ids'], data_version: 0).to_a
      end
    end
  end
end
