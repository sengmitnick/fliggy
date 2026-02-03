# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例183: 预订早班火车和含早餐酒店
#
# 任务描述:
#   用户需要预订早班火车（6-8点出发），并预订前一晚含早餐的酒店
#
# 复杂度分析:
#   1. 需要筛选早班火车（6-8点出发）
#   2. 需要预订含早餐的酒店
#   3. 需要预订前一晚入住
#   4. 验证酒店提供早餐服务
#
# 评分标准:
#   - 创建了火车订单 (20分)
#   - 火车出发时间正确（6-8点） (20分)
#   - 创建了酒店订单 (20分)
#   - 酒店在出发城市 (20分)
#   - 酒店入住前一晚 (15分)
#   - 酒店含早餐 (5分)
module V151V200
  class V183BookEarlyTrainAndBreakfastHotelValidator < BaseValidator
    self.validator_id = 'v183_book_early_train_and_breakfast_hotel_validator'
    self.task_id = '2f272b8e-e252-4a44-82fc-bb22b88361f7'
    self.title = '预订早班火车和含早餐酒店'
    self.description = '用户需要预订早班火车（6-8点出发），并预订前一晚含早餐的酒店'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @train_date = Date.tomorrow + 2.days
      
      # 查找早班火车（6-8点出发）
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .by_date(@train_date)
        .select { |t| t.departure_time.hour >= 6 && t.departure_time.hour < 8 }
      
      expect(@available_trains).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}早班火车（6-8点）"
      
      # 查找北京的酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@departure_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@departure_city}的酒店"
      
      @hotel_checkin_date = @train_date - 1.day  # 前一晚入住
      @hotel_checkout_date = @train_date  # 火车当天退房
      
      {
        task: "请预订#{@train_date.strftime('%Y年%m月%d日')}（#{(@train_date - Date.today).to_i}天后）从#{@departure_city}到#{@arrival_city}的早班火车（6-8点出发），" \
              "并在#{@hotel_checkin_date.strftime('%Y年%m月%d日')}（前一晚）预订#{@departure_city}含早餐的酒店",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          train_date: @train_date.to_s,
          departure_time: "6:00-8:00",
          hotel_location: @departure_city,
          hotel_checkin: @hotel_checkin_date.to_s,
          breakfast: "含早餐"
        },
        hint: "早班火车需要前一晚入住酒店，并享用早餐后出发",
        statistics: {
          available_early_trains: @available_trains.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建火车订单
      train = @available_trains.sort_by(&:departure_time).first
      TrainBooking.create!(
        user: user,
        train: train,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        accept_terms: true,
        total_price: train.price_second_class,
        data_version: @data_version
      )
      
      # 创建酒店订单（含早餐）
      hotel = @available_hotels.first
      # 优先查找含早餐的房型
      room = hotel.hotel_rooms.where(data_version: 0).where("room_type LIKE ?", "%早%").order(price: :asc).first
      
      unless room
        room = HotelRoom.create!(
          hotel_id: hotel.id,
          room_type: '标准双人间（含早）',
          bed_type: 'double',
          area: 25.0,
          max_guests: 2,
          price: 350.0,
          original_price: 450.0,
          has_window: true,
          available_rooms: 10,
          data_version: 0
        )
      end
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date,
        guest_name: user.name,
        guest_phone: '13800138000',
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
      
      # 断言2: 火车出发时间正确（6-8点） (20%)
      add_assertion "火车出发时间正确（6-8点）", weight: 20 do
        departure_hour = @train_booking.train.departure_time.hour
        expect(departure_hour).to be >= 6, 
          "出发时间过早。期望: 6:00-8:00, 实际: #{@train_booking.train.departure_time.strftime('%H:%M')}"
        expect(departure_hour).to be < 8,
          "出发时间过晚。期望: 6:00-8:00, 实际: #{@train_booking.train.departure_time.strftime('%H:%M')}"
      end
      
      # 断言3: 创建了酒店订单 (20%)
      add_assertion "创建了酒店订单", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where(hotels: { city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言4: 酒店在出发城市 (20%)
      add_assertion "酒店位置正确（#{@departure_city}）", weight: 20 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@departure_city),
          "酒店城市错误。期望: #{@departure_city}, 实际: #{hotel.city}"
      end
      
      # 断言5: 酒店入住前一晚 (15%)
      add_assertion "酒店入住前一晚", weight: 15 do
        expect(@hotel_booking.check_in_date).to eq(@hotel_checkin_date),
          "入住日期错误。期望: #{@hotel_checkin_date}（火车前一晚）, 实际: #{@hotel_booking.check_in_date}"
      end
      
      # 断言6: 酒店含早餐 (5%)
      add_assertion "酒店含早餐", weight: 5 do
        room = @hotel_booking.hotel_room
        expect(room.room_type).to match(/早/),
          "房型未包含早餐。期望: 含早餐房型, 实际: #{room.room_type}"
      end
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        train_date: @train_date&.to_s,
        hotel_checkin_date: @hotel_checkin_date&.to_s,
        hotel_checkout_date: @hotel_checkout_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date']) if data['train_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
    end
  end
end
