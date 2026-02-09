# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例191: 预订2大1小家庭出行，总预算≤2000元
#
# 任务描述:
#   预订2大1小家庭出行，总预算≤2000元
#
# 评分标准:
#   - 创建了交通订单（2个成人票+1个儿童票） (20%)
#   - 创建了酒店订单 (15%)
#   - 出发/到达城市正确 (10%)
#   - 酒店城市正确 (10%)
#   - 总预算在2000元以内 (30%)
#   - 日期合理 (15%)
module V151V200
  class V191BookFamilyBudgetTripUnder2000Validator < BaseValidator
    self.validator_id = 'v191_book_family_budget_trip_under_2000_validator'
    self.task_id = 'e9100569-2f92-49f6-9c56-2eaa58616ddc'
    self.title = '预订3天后2大1小家庭出行，总预算≤2000元（2个成人票+1个儿童票）'
    self.description = '预订2大1小家庭出行，总预算≤2000元'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.tomorrow + 2.days
      @max_budget = 2000
      @adult_count = 2
      @child_count = 1
      
      # 查找低价交通
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .select { |t| t.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_trains).not_to be_empty,
        "数据包缺少#{@departure_city}→#{@arrival_city}的火车（#{@travel_date}）"
      
      # 查找经济型酒店
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).order(price: :asc).limit(20).to_a
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      
      {
        task: "请为2大1小家庭预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的行程（交通+住宿1晚），总预算≤#{@max_budget}元",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        passenger_info: '2个成人+1个儿童',
        max_budget: @max_budget,
        hint: "请预订2张成人票、1张儿童票（儿童票通常半价）和1间酒店，总价不超过#{@max_budget}元"
      }
    end
    
    def verify
      # 断言1: 创建了交通订单（2个成人票+1个儿童票） (20%)
      add_assertion "创建了交通订单（2个成人票+1个儿童票）", weight: 20 do
        all_train_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @train_bookings = all_train_bookings
        total_count = @train_bookings.size
        
        expect(total_count).to be >= 2, 
          "交通订单数量不足。期望: ≥2（至少2大1小），实际: #{total_count}"
      end
      
      return if @train_bookings.nil? || @train_bookings.empty?
      
      # 断言2: 创建了酒店订单 (15%)
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（#{@arrival_city}）"
      end
      
      return if @hotel_booking.nil?
      
      # 断言3: 出发/到达城市正确 (10%)
      add_assertion "出发/到达城市正确（#{@departure_city}→#{@arrival_city}）", weight: 10 do
        train = @train_bookings.first.train
        expect(train.departure_city).to eq(@departure_city)
        expect(train.arrival_city).to eq(@arrival_city)
      end
      
      # 断言4: 酒店城市正确 (10%)
      add_assertion "酒店城市正确（#{@arrival_city}）", weight: 10 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to eq(@arrival_city)
      end
      
      # 断言5: 总预算在2000元以内 (30%)
      add_assertion "总预算在#{@max_budget}元以内", weight: 30 do
        train_total = @train_bookings.sum(&:total_price)
        hotel_total = @hotel_booking.total_price
        actual_total = train_total + hotel_total
        
        expect(actual_total).to be <= @max_budget,
          "总价超预算。期望: ≤#{@max_budget}元, 实际: #{actual_total}元（火车#{train_total}+酒店#{hotel_total}）"
      end
      
      # 断言6: 日期合理 (15%)
      add_assertion "日期合理", weight: 15 do
        arrival_date = @train_bookings.first.train.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        expect([arrival_date, arrival_date + 1.day]).to include(checkin_date)
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择最便宜的火车
      cheapest_train = @available_trains.min_by(&:price_second_class)
      
      # 创建2个成人火车票
      2.times do |i|
        TrainBooking.create!(
          user: user,
          train: cheapest_train,
          passenger_name: i == 0 ? user.name : "张三",
          passenger_id_number: '110101199001011234',
          seat_type: 'second_class',
          contact_phone: '13800138000',
          total_price: cheapest_train.price_second_class,
          accept_terms: true,
          data_version: @data_version
        )
      end
      
      # 创建1个儿童火车票（半价）
      TrainBooking.create!(
        user: user,
        train: cheapest_train,
        passenger_name: "小明",
        passenger_id_number: '110101201801011234',
        seat_type: 'second_class',
        contact_phone: '13800138000',
        total_price: cheapest_train.price_second_class * 0.5,
        accept_terms: true,
        data_version: @data_version
      )
      
      # 找到最便宜的酒店
      cheapest_hotel = @available_hotels.first
      room = cheapest_hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      unless room
        room = HotelRoom.create!(
          hotel_id: cheapest_hotel.id,
          room_type: '标准双人间',
          bed_type: 'double',
          price: cheapest_hotel.price,
          original_price: cheapest_hotel.original_price,
          area: 25.0,
          max_guests: 3,
          has_window: true,
          available_rooms: 10,
          room_category: 'standard',
          data_version: 0
        )
      end
      
      arrival_date = cheapest_train.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: cheapest_hotel.id,
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
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date&.to_s,
        max_budget: @max_budget,
        adult_count: @adult_count,
        child_count: @child_count
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @max_budget = data['max_budget']
      @adult_count = data['adult_count']
      @child_count = data['child_count']
    end
  end
end
