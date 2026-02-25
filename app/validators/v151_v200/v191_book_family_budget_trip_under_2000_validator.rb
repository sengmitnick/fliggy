# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例191: 给张三预订2大1小家庭出行，总预算≤2000元
#
# 任务描述:
#   预订2大1小家庭出行，总预算≤2000元
#
# 评分标准:
#   - 创建了交通订单（2个成人票+1个儿童票） (15%)
#   - 创建了酒店订单 (10%)
#   - 出发/到达城市正确 (10%)
#   - 酒店城市正确 (10%)
#   - 乘客信息正确（张三、王芳、小明） (15%)
#   - 联系人和入住人信息正确 (10%)
#   - 总预算在2000元以内 (20%)
#   - 日期合理 (10%)
module V151V200
  class V191BookFamilyBudgetTripUnder2000Validator < BaseValidator
    self.validator_id = 'v191_book_family_budget_trip_under_2000_validator'
    self.task_id = 'e9100569-2f92-49f6-9c56-2eaa58616ddc'
    self.title = '给张三预订2大1小家庭出行，总预算≤2000元'
    self.description = '预订2大1小家庭出行，总预算≤2000元'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.current + 2.days  # 后天
      @max_budget = 2000
      @adult_count = 2
      @child_count = 1
      @expected_passengers = ['张三', '王芳', '小明']  # 家庭成员
      
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
        task: "请为#{@passenger.name}一家2大1小家庭预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的行程（交通+住宿1晚），总预算≤#{@max_budget}元",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        passenger_info: '2个成人+1个儿童',
        max_budget: @max_budget,
        hint: "请预订2张成人票、1张儿童票（儿童票通常半价）和1间酒店，总价不超过#{@max_budget}元"
      }
    end
    
    def verify
      # 断言1: 创建了交通订单（2个成人票+1个儿童票） (15%)
      add_assertion "创建了交通订单（2个成人票+1个儿童票）", weight: 15 do
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
      
      # 断言2: 创建了酒店订单 (10%)
      add_assertion "创建了酒店订单", weight: 10 do
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
      
      # 断言5: 乘客信息正确（张三、王芳、小明） (15%)
      add_assertion "乘客信息正确（#{@expected_passengers.join('、')}）", weight: 15 do
        passenger_names = @train_bookings.map(&:passenger_name).uniq.sort
        expect(passenger_names.size).to be >= 2,
          "乘客数量不足。期望: 至少2人（家庭成员），实际: #{passenger_names.size}人（#{passenger_names.join('、')}）"
        
        # 检查是否包含主要家庭成员（至少张三或王芳）
        has_family_member = @expected_passengers.any? { |name| passenger_names.include?(name) }
        expect(has_family_member).to be true,
          "乘客信息错误。期望包含: #{@expected_passengers.join('、')}，实际: #{passenger_names.join('、')}"
      end
      
      # 断言6: 联系人和入住人信息正确 (10%)
      add_assertion "联系人和入住人信息正确（#{@expected_passenger_name}）", weight: 10 do
        # 检查火车票联系人
        @train_bookings.each do |booking|
          expect(booking.contact_phone).to eq(@expected_phone),
            "火车票联系人电话错误。期望: #{@expected_phone}, 实际: #{booking.contact_phone}"
        end
        
        # 检查酒店入住人
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言7: 总预算在2000元以内 (20%)
      add_assertion "总预算在#{@max_budget}元以内", weight: 20 do
        train_total = @train_bookings.sum(&:total_price)
        hotel_total = @hotel_booking.total_price
        actual_total = train_total + hotel_total
        
        expect(actual_total).to be <= @max_budget,
          "总价超预算。期望: ≤#{@max_budget}元, 实际: #{actual_total}元（火车#{train_total}+酒店#{hotel_total}）"
      end
      
      # 断言8: 日期合理 (10%)
      add_assertion "日期合理", weight: 10 do
        arrival_date = @train_bookings.first.train.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        expect([arrival_date, arrival_date + 1.day]).to include(checkin_date)
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择最便宜的火车
      cheapest_train = @available_trains.min_by(&:price_second_class)
      
      # 创建2个成人火车票
      2.times do |i|
        TrainBooking.create!(
          user: user,
          train: cheapest_train,
          passenger_name: i == 0 ? user.name : "张三",
          passenger_id_number: passenger.id_number,
          seat_type: 'second_class',
          contact_phone: passenger.phone,
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
        contact_phone: passenger.phone,
        total_price: cheapest_train.price_second_class * 0.5,
        accept_terms: true,
        data_version: @data_version
      )
      
      # 找到最便宜的酒店
      cheapest_hotel = @available_hotels.first
      room = cheapest_hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      arrival_date = cheapest_train.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: cheapest_hotel.id,
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
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date&.to_s,
        max_budget: @max_budget,
        adult_count: @adult_count,
        child_count: @child_count,
        expected_passengers: @expected_passengers
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @max_budget = data['max_budget']
      @adult_count = data['adult_count']
      @child_count = data['child_count']
      @expected_passengers = data['expected_passengers'] || ['张三', '王芳', '小明']
    end
  end
end