# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例178: 预订中午前到达火车和提前入住酒店
#
# 任务描述:
#   用户需要预订上午到达（12点前）的火车，并预订支持提前入住的酒店
#
# 复杂度分析:
#   1. 需要筛选12点前到达的火车
#   2. 需要预订支持提前入住的酒店
#   3. 验证酒店入住日期与火车到达日期匹配
#
# 评分标准:
#   - 创建了火车订单 (20分)
#   - 火车到达时间正确（12点前） (20分)
#   - 创建了酒店订单 (20分)
#   - 酒店在到达城市 (20分)
#   - 酒店入住日期为火车到达当天 (20分)
module V151V200
  class V178BookNoonTrainAndEarlyCheckinHotelValidator < BaseValidator
    self.validator_id = 'v178_book_noon_train_and_early_checkin_hotel_validator'
    self.task_id = '86a07e7f-aa31-4d1d-a9c7-4d13777246bb'
    self.title = '给张三预订明天中午前到达北京到上海的火车，并预订提前入住酒店'
    self.description = '帮张三订明天从北京到上海的火车（12点前到达），并预订支持提前入住的酒店'
    self.timeout_seconds = 300
  
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '上海'
      @train_date = Date.current + 1.day  # 明天
      
      # 查找12点前到达的火车
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .by_date(@train_date)
        .select { |t| t.arrival_time.hour < 12 }
      
      expect(@available_trains).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}中午前到达的火车"
      
      # 查找上海的酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      
      @hotel_checkin_date = @train_date
      @hotel_checkout_date = @train_date + 1.day
      
      {
        task: "请为#{@passenger.name}预订#{@train_date.strftime('%Y年%m月%d日')}（#{(@train_date - Date.current).to_i}天后）从#{@departure_city}到#{@arrival_city}的火车（12点前到达），" \
              "并在#{@arrival_city}预订支持提前入住的酒店",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          train_date: @train_date.to_s,
          arrival_time: "12:00前",
          hotel_location: @arrival_city,
          hotel_checkin: "支持提前入住"
        },
        hint: "上午到达可以提前入住酒店休息，避免在大堂等待",
        statistics: {
          available_morning_trains: @available_trains.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 创建火车订单
      train = @available_trains.sort_by(&:arrival_time).first
      TrainBooking.create!(
        user: user,
        train: train,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'second_class',
        accept_terms: true,
        total_price: train.price_second_class,
        data_version: @data_version
      )
      
      # 创建酒店订单
      hotel = @available_hotels.first
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date,
        guest_name: @passenger.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
  
    def verify
      # 断言1: 创建了火车订单 (20%)
      add_assertion "创建了火车订单（#{@departure_city}→#{@arrival_city}）", weight: 20 do
        all_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @train_booking = all_bookings.first
        expect(@train_booking).not_to be_nil, "未找到火车订单"
      end
      
      return if @train_booking.nil?
      
      # 断言2: 火车到达时间正确（12点前） (18%)
      add_assertion "火车到达时间正确（12点前）", weight: 18 do
        arrival_hour = @train_booking.train.arrival_time.hour
        expect(arrival_hour).to be < 12, 
          "到达时间过晚。期望: 12:00前, 实际: #{@train_booking.train.arrival_time.strftime('%H:%M')}"
      end
      
      # 断言3: 创建了酒店订单 (15%)
      add_assertion "创建了酒店订单", weight: 15 do
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
      
      # 断言4: 酒店在到达城市 (15%)
      add_assertion "酒店位置正确（#{@arrival_city}）", weight: 15 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@arrival_city),
          "酒店城市错误。期望: #{@arrival_city}, 实际: #{hotel.city}"
      end
      
      # 断言5: 酒店入住日期为火车到达当天 (17%)
      add_assertion "酒店入住日期正确（火车到达当天）", weight: 17 do
        expect(@hotel_booking.check_in_date).to eq(@train_date),
          "入住日期错误。期望: #{@train_date}（火车到达当天）, 实际: #{@hotel_booking.check_in_date}"
        
        # 验证退房日期
        expect(@hotel_booking.check_out_date).to eq(@hotel_checkout_date),
          "退房日期错误。期望: #{@hotel_checkout_date}, 实际: #{@hotel_booking.check_out_date}"
      end
    
      # 断言6: 火车乘客信息正确（张三） (7%)
      add_assertion "火车乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "火车乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.contact_phone).to eq(@expected_phone),
          "火车联系电话错误。期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
      end
    
      # 断言7: 酒店入住人信息正确（张三） (8%)
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 8 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "酒店入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店联系电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        train_date: @train_date&.to_s,
        hotel_checkin_date: @hotel_checkin_date&.to_s,
        hotel_checkout_date: @hotel_checkout_date&.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date']) if data['train_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
      
      # 重新查询乘客信息（用于simulate阶段）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      # 重新查询可用火车和酒店（用于simulate阶段）
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .by_date(@train_date)
        .select { |t| t.arrival_time.hour < 12 }
      
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
    end
  end
end
