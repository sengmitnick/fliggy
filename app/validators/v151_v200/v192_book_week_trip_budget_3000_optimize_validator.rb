# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例192: 预订7天行程，总预算≤3000元
#
# 任务描述:
#   预订7天行程（往返+住宿），总预算≤3000元
#
# 评分标准:
#   - 创建了去程交通订单 (15%)
#   - 创建了返程交通订单 (15%)
#   - 创建了酒店订单（7晚） (15%)
#   - 出发/到达城市正确 (10%)
#   - 乘客和入住人信息正确（李四） (15%)
#   - 总预算在3000元以内 (20%)
#   - 日期合理 (10%)
module V151V200
  class V192BookWeekTripBudget3000OptimizeValidator < BaseValidator
    self.validator_id = 'v192_book_week_trip_budget_3000_optimize_validator'
    self.task_id = 'a91aa487-9ae2-4ef6-83e2-44b428900100'
    self.title = '给李四预订4天后从北京到上海的往还+7晚住宿（总预算≤3000元）'
    self.description = '帮李四订4天后从北京到上海的7天行程（往返交通+住宿7晚），总预算不超过3000元'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '上海'
      @go_date = Date.current + 4.days  # 4天后
      @return_date = @go_date + 7.days
      @max_budget = 3000
      @stay_nights = 7
      
      # 查找去程火车
      @available_go_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .select { |t| t.departure_time.to_date == @go_date }
        .to_a
      
      expect(@available_go_trains).not_to be_empty,
        "数据包缺少#{@departure_city}→#{@arrival_city}的火车（#{@go_date}）"
      
      # 查找返程火车
      @available_return_trains = Train
        .where(departure_city: @arrival_city, arrival_city: @departure_city, data_version: 0)
        .select { |t| t.departure_time.to_date == @return_date }
        .to_a
      
      expect(@available_return_trains).not_to be_empty,
        "数据包缺少#{@arrival_city}→#{@departure_city}的返程火车（#{@return_date}）"
      
      # 查找经济型酒店
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).order(price: :asc).limit(20).to_a
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      
      {
        task: "请为#{@passenger.name}预订#{@go_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的7天行程（往返交通+住宿7晚），总预算≤#{@max_budget}元",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        go_date: @go_date.strftime('%Y-%m-%d'),
        return_date: @return_date.strftime('%Y-%m-%d'),
        stay_nights: @stay_nights,
        max_budget: @max_budget,
        hint: "需要预订去程、返程交通和7晚酒店，总价不超过#{@max_budget}元"
      }
    end
    
    def verify
      # 断言1: 创建了去程交通订单 (15%)
      add_assertion "创建了去程交通订单（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        @go_booking = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@go_booking).not_to be_nil, "未找到去程交通订单"
      end
      
      return if @go_booking.nil?
      
      # 断言2: 创建了返程交通订单 (15%)
      add_assertion "创建了返程交通订单（#{@arrival_city}→#{@departure_city}）", weight: 15 do
        @return_booking = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @arrival_city, arrival_city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@return_booking).not_to be_nil, "未找到返程交通订单"
      end
      
      # 断言3: 创建了酒店订单（7晚） (15%)
      add_assertion "创建了酒店订单（7晚）", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
        
        nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(nights).to eq(@stay_nights),
          "住宿天数错误。期望: #{@stay_nights}晚, 实际: #{nights}晚"
      end
      
      return if @hotel_booking.nil?
      
      # 断言4: 出发/到达城市正确 (10%)
      add_assertion "出发/到达城市正确", weight: 10 do
        go_train = @go_booking.train
        expect(go_train.departure_city).to eq(@departure_city)
        expect(go_train.arrival_city).to eq(@arrival_city)
      end
      
      # 断言5: 乘客和入住人信息正确（李四） (15%)
      add_assertion "乘客和入住人信息正确（#{@expected_passenger_name}）", weight: 15 do
        # 检查火车票乘客姓名
        expect(@go_booking.passenger_name).to eq(@expected_passenger_name),
          "去程乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@go_booking.passenger_name}"
        
        if @return_booking
          expect(@return_booking.passenger_name).to eq(@expected_passenger_name),
            "返程乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@return_booking.passenger_name}"
        end
        
        # 检查火车票联系人
        expect(@go_booking.contact_phone).to eq(@expected_phone),
          "火车票联系人电话错误。期望: #{@expected_phone}, 实际: #{@go_booking.contact_phone}"
        
        # 检查酒店入住人
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言6: 总预算在3000元以内 (20%)
      add_assertion "总预算在#{@max_budget}元以内", weight: 20 do
        go_price = @go_booking.total_price
        return_price = @return_booking ? @return_booking.total_price : 0
        hotel_price = @hotel_booking.total_price
        actual_total = go_price + return_price + hotel_price
        
        expect(actual_total).to be <= @max_budget,
          "总价超预算。期望: ≤#{@max_budget}元, 实际: #{actual_total}元（去程#{go_price}+返程#{return_price}+酒店#{hotel_price}）"
      end
      
      # 断言7: 日期合理 (10%)
      add_assertion "日期合理", weight: 10 do
        arrival_date = @go_booking.train.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        expect([arrival_date, arrival_date + 1.day]).to include(checkin_date)
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      
      # 选择最便宜的去程火车
      go_train = @available_go_trains.min_by(&:price_second_class)
      TrainBooking.create!(
        user: user,
        train: go_train,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        seat_type: 'second_class',
        contact_phone: passenger.phone,
        total_price: go_train.price_second_class,
        accept_terms: true,
        data_version: @data_version
      )
      
      # 选择最便宜的返程火车
      return_train = @available_return_trains.min_by(&:price_second_class)
      TrainBooking.create!(
        user: user,
        train: return_train,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        seat_type: 'second_class',
        contact_phone: passenger.phone,
        total_price: return_train.price_second_class,
        accept_terms: true,
        data_version: @data_version
      )
      
      # 找到最便宜的酒店
      cheapest_hotel = @available_hotels.first
      room = cheapest_hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      arrival_date = go_train.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: cheapest_hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
        check_out_date: arrival_date + @stay_nights.days,
        guest_name: user.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price * @stay_nights,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        go_date: @go_date&.to_s,
        return_date: @return_date&.to_s,
        max_budget: @max_budget,
        stay_nights: @stay_nights
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @go_date = Date.parse(data['go_date']) if data['go_date']
      @return_date = Date.parse(data['return_date']) if data['return_date']
      @max_budget = data['max_budget']
      @stay_nights = data['stay_nights']
    end
  end
end
