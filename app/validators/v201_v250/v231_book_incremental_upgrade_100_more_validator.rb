# frozen_string_literal: true

require_relative '../base_validator'

# V231: 预订增量升级（加100元升级服务）
#
# 任务描述:
#   用户先查找基础方案，然后加100元升级到更好服务（如从经济舱升商务舱、经济型酒店升高星酒店）
#
# 评分标准:
#   - 创建了火车订单 (15%)
#   - 创建了酒店订单 (15%)
#   - 出行日期正确 (5%)
#   - 酒店入住日期正确 (5%)
#   - 乘车人信息正确 (5%)
#   - 入住人信息正确 (5%)
#   - 总价比基础方案多约100元（±50元） (25%)
#   - 服务档次有明显提升（评分提高或舱位升级） (20%)
#   - 订单状态有效 (5%)
module V201V250
  class V231BookIncrementalUpgrade100MoreValidator < BaseValidator
    self.validator_id = 'v231_book_incremental_upgrade_100_more_validator'
    self.task_id = '7ff798ff-8f8f-8f0f-0f1f-9f2a3b4c5d6f'
    self.title = '张三想从成都去重庆，先查到最便宜的基础方案（火车+酒店），现在想加100元升级到更好服务，比如更高星级酒店或一等座'
    self.description = '张三想从成都去重庆，先查到最便宜的基础方案（火车+酒店），现在想加100元升级到更好服务，比如更高星级酒店或一等座'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '成都'
      @destination_city = '重庆'
      @upgrade_budget = 100
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = Passenger.find_by!(user_id: demo_user.id, is_self: true, data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_passenger.name,
        id_number: demo_passenger.id_number,
        phone: demo_passenger.phone
      )
      
      # 设置出行日期为后天
      @travel_date = Date.current + 2.days
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 1.day
      
      # 筛选指定日期的火车
      @available_trains = Train.by_route(@departure_city, @destination_city)
        .by_date(@travel_date)
        .where(data_version: 0)
        .order(price_second_class: :asc)
        .to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0)
        .order(price: :asc)
        .to_a
      
      raise "未找到交通或酒店" if @available_trains.empty? || @available_hotels.empty?
      
      # 计算基础方案价格（最便宜的组合：火车+酒店）
      min_transport_price = @available_trains.first.price_second_class
      
      min_hotel_room = @available_hotels.first.hotel_rooms.where(data_version: 0).order(price: :asc).first
      min_hotel_price = min_hotel_room ? min_hotel_room.price : Float::INFINITY
      
      @base_price = min_transport_price + min_hotel_price
      @target_price = @base_price + @upgrade_budget
      
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@destination_city}的火车和酒店（住1晚）。基础方案约#{@base_price.round}元（最便宜的火车+酒店），请在此基础上加#{@upgrade_budget}元（预算#{@target_price.round}元）升级到更好的服务（如更高星级酒店或一等座）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          travel_date: @travel_date,
          base_price: "约#{@base_price.round}元",
          target_price: "约#{@target_price.round}元",
          upgrade_budget: "+#{@upgrade_budget}元",
          purpose: '增量升级服务（火车+酒店）'
        },
        hint: "基础方案是最便宜的二等座火车+最便宜的酒店房间，加#{@upgrade_budget}元可以升级到更好的服务（如一等座或更高星级酒店）。"
      }
    end
    
    def verify
      add_assertion "创建了火车订单", weight: 15 do
        @train_booking = TrainBooking
          .joins(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@train_booking).not_to be_nil, "未找到火车订单"
      end
      
      return if @train_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "出行日期正确（#{@travel_date}）", weight: 5 do
        train_date = @train_booking.train.departure_time.to_date
        expect(train_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{train_date}"
      end
      
      add_assertion "酒店入住日期正确（入住#{@check_in_date}，退房#{@check_out_date}）", weight: 5 do
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
      
      add_assertion "总价比基础方案多约#{@upgrade_budget}元（允许±50元）", weight: 25 do
        train_price = @train_booking.total_price
        hotel_price = @hotel_booking.total_price
        actual_total = train_price + hotel_price
        
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
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@train_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 找到价格在目标范围内且档次提升的组合（仅火车）
      best_combo = nil
      best_rating_upgrade = 0
      min_hotel_rating = @available_hotels.first.rating
      
      # 尝试火车组合
      @available_trains.each do |train|
        @available_hotels.each do |hotel|
          room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
          next unless room
          
          total = train.price_second_class + room.price
          price_increase = total - @base_price
          
          next unless price_increase >= (@upgrade_budget - 50) && price_increase <= (@upgrade_budget + 50)
          
          rating_upgrade = hotel.rating - min_hotel_rating
          next unless rating_upgrade >= 0.1
          
          if rating_upgrade > best_rating_upgrade
            best_rating_upgrade = rating_upgrade
            best_combo = { train: train, hotel: hotel, room: room }
          end
        end
      end
      
      raise "未找到符合升级要求的组合" if best_combo.nil?
      
      # 创建火车订单
      TrainBooking.create!(
        user: user,
        train: best_combo[:train],
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
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
        base_price: @base_price,
        target_price: @target_price,
        upgrade_budget: @upgrade_budget,
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
      @base_price = data['base_price'].to_f
      @target_price = data['target_price'].to_f
      @upgrade_budget = data['upgrade_budget'].to_i
      
      @passenger = OpenStruct.new(
        name: data['passenger_name'],
        id_number: data['passenger_id_number'],
        phone: data['passenger_phone']
      )
      
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
