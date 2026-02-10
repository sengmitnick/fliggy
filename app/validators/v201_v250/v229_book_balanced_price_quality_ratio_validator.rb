# frozen_string_literal: true

require_relative '../base_validator'

# V229: 预订价格质量平衡最佳组合
#
# 任务描述:
#   用户需要预订火车票+酒店，价格/质量平衡最佳（性价比）
#
# 评分标准:
#   - 创建了火车票订单 (15%)
#   - 创建了酒店订单 (15%)
#   - 出行日期正确 (10%)
#   - 酒店入住日期正确 (10%)
#   - 乘车人信息正确 (5%)
#   - 入住人信息正确 (5%)
#   - 组合性价比较优 (35%)
#   - 订单状态有效 (5%)
module V201V250
  class V229BookBalancedPriceQualityRatioValidator < BaseValidator
    self.validator_id = 'v229_book_balanced_price_quality_ratio_validator'
    self.task_id = '4ff465ff-5f5f-5f7f-7f8f-6f9a0b1c2d3f'
    self.title = '给张三预订价格质量平衡最佳组合（后天火车+酒店）'
    self.description = '张三后天要从上海去杭州出差，需要预订火车票和酒店住1晚，希望综合考虑价格、时长、酒店评分等因素，选择性价比平衡最佳的组合'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @arrival_city = '杭州'
      @travel_date = Date.today + 2.days
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 1.day
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = Passenger.find_by!(user_id: demo_user.id, is_self: true, data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_passenger.name,
        id_number: demo_passenger.id_number,
        phone: demo_passenger.phone
      )
      
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a
      
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).to_a
      
      raise "未找到火车或酒店" if @available_trains.empty? || @available_hotels.empty?
      
      # 计算性价比参考值（理论最佳）
      train_scores = @available_trains.map do |t|
        duration_score = 100.0 / (t.duration / 60.0 + 1)  # 时长越短越好
        price_score = 100.0 / (t.price_second_class + 1)  # 价格越低越好
        (duration_score + price_score) / 2.0
      end
      
      hotel_scores = @available_hotels.map do |h|
        quality_score = h.rating * 20  # 评分转换为分数
        price_score = 100.0 / (h.price + 1)  # 价格越低越好
        (quality_score + price_score) / 2.0
      end
      
      @reference_train_score = train_scores.max
      @reference_hotel_score = hotel_scores.max
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@arrival_city}的火车票+酒店，要求价格和质量平衡最佳，追求性价比。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          travel_date: @travel_date,
          priority: '性价比平衡',
          purpose: '价格质量兼顾'
        },
        hint: "综合考虑价格、时长、评分等因素，选择性价比最佳的组合。"
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
      
      add_assertion "乘车人信息正确（姓名、身份证、手机号）", weight: 5 do
        expect(@train_booking.passenger_name).to eq(@passenger.name),
          "乘客姓名错误。期望: #{@passenger.name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.passenger_id_number).to eq(@passenger.id_number),
          "身份证号错误。期望: #{@passenger.id_number}, 实际: #{@train_booking.passenger_id_number}"
        expect(@train_booking.contact_phone).to eq(@passenger.phone),
          "联系电话错误。期望: #{@passenger.phone}, 实际: #{@train_booking.contact_phone}"
      end
      
      add_assertion "入住人信息正确（姓名、手机号）", weight: 5 do
        demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
        expect(@hotel_booking.guest_name).to eq(demo_user.name),
          "入住人姓名错误。期望: #{demo_user.name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@passenger.phone),
          "入住人电话错误。期望: #{@passenger.phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "组合性价比较优", weight: 35 do
        train = @train_booking.train
        hotel = @hotel_booking.hotel
        
        # 计算实际选择的性价比分数
        train_duration_score = 100.0 / (train.duration / 60.0 + 1)
        train_price_score = 100.0 / (train.price_second_class + 1)
        actual_train_score = (train_duration_score + train_price_score) / 2.0
        
        hotel_quality_score = hotel.rating * 20
        hotel_price_score = 100.0 / (hotel.price + 1)
        actual_hotel_score = (hotel_quality_score + hotel_price_score) / 2.0
        
        # 允许20%的误差
        expect(actual_train_score).to be >= @reference_train_score * 0.8,
          "火车票性价比不佳。参考最佳: #{@reference_train_score.round(1)}, 实际: #{actual_train_score.round(1)}"
        expect(actual_hotel_score).to be >= @reference_hotel_score * 0.8,
          "酒店性价比不佳。参考最佳: #{@reference_hotel_score.round(1)}, 实际: #{actual_hotel_score.round(1)}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@train_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 计算每个火车的性价比分数
      train_with_scores = @available_trains.map do |t|
        duration_score = 100.0 / (t.duration / 60.0 + 1)
        price_score = 100.0 / (t.price_second_class + 1)
        score = (duration_score + price_score) / 2.0
        { train: t, score: score }
      end
      best_train = train_with_scores.max_by { |ts| ts[:score] }[:train]
      
      # 计算每个酒店的性价比分数
      hotel_with_scores = @available_hotels.map do |h|
        quality_score = h.rating * 20
        price_score = 100.0 / (h.price + 1)
        score = (quality_score + price_score) / 2.0
        { hotel: h, score: score }
      end
      best_hotel = hotel_with_scores.max_by { |hs| hs[:score] }[:hotel]
      room = best_hotel.hotel_rooms.where(data_version: 0).first
      
      TrainBooking.create!(
        user: user,
        train: best_train,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        seat_type: 'second_class',
        ticket_count: 1,
        total_price: best_train.price_second_class,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      HotelBooking.create!(
        user: user,
        hotel: best_hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: @passenger.phone,
        room_count: 1,
        total_price: best_hotel.price,
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
        reference_train_score: @reference_train_score,
        reference_hotel_score: @reference_hotel_score,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        passenger_phone: @passenger.phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @reference_train_score = data['reference_train_score'].to_f
      @reference_hotel_score = data['reference_hotel_score'].to_f
      
      @passenger = OpenStruct.new(
        name: data['passenger_name'],
        id_number: data['passenger_id_number'],
        phone: data['passenger_phone']
      )
      
      @available_trains = Train.by_route(@departure_city, @arrival_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .to_a
      
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).to_a
    end
  end
end
