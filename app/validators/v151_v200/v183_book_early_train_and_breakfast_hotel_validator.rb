# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例183: 给王芳预订明天北京到上海的早班火车，并预订今晚北京含早餐酒店
#
# 任务描述:
#   王芳需要明天早上从北京坐早班火车到上海（6-8点出发），
#   为了保证出行顺利不错过火车，需要今晚（今天晚上）入住北京酒店。Agent需要搜索早班火车并预订，
#   然后预订今晚的北京酒店（需含早餐，方便明早用餐后赶车）。
#
# 业务流程（6个关键步骤）：
#   1. 搜索北京→上海的火车票（明天6-8点出发）
#   2. 筛选早班火车（出发时间在 6:00-8:00 范围内）
#   3. 预订火车票（乘客王芳）
#   4. 搜索北京的酒店（位置必须在北京，4星级以上，含早餐房型）
#   5. 选择含早餐的房型（room_type包含“早”字）
#   6. 预订今晚的北京酒店（入住日期=今天，退房日期=明天火车当天）
#
# 复杂度分析（6个关键点）：
#   1. 需要筛选早班火车（出发时间在 6:00-8:00 范围内）
#   2. 需要理解时间逻辑：明天早班火车 → 今晚入住酒店
#   3. 需要识别出发城市（北京）作为酒店位置
#   4. 需要筛选含早餐的酒店房型（room_type包含“早”字）
#   5. 需要验证酒店入住日期是今天（火车前一晚）
#   6. 需要确保火车和酒店的乘客/入住人信息一致
#   ❌ 不能一次性提供：需要先搜索火车→筛选早班车→预订火车→理解时间→搜索今晚北京酒店→筛选含早餐房型→预订
#
# 评分标准（8项，总计100分）：
#   - 创建了火车订单（北京→上海）（18分）
#   - 火车出发时间正确（明天6-8点）（15分）
#   - 创建了北京酒店订单（15分）
#   - 酒店位置正确（必须在北京）（15分）
#   - 酒店入住时间正确（今晚，火车前一晚）（15分）
#   - 酒店含早餐（7分）
#   - 火车乘客信息正确（王芳）（7分）
#   - 酒店入住人信息正确（王芳）（8分）
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v183_book_early_train_and_breakfast_hotel_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V183BookEarlyTrainAndBreakfastHotelValidator < BaseValidator
    self.validator_id = 'v183_book_early_train_and_breakfast_hotel_validator'
    self.task_id = '2f272b8e-e252-4a44-82fc-bb22b88361f7'
    self.title = '给王芳预订明天北京到上海的早班火车，并预订今晚北京含早餐酒店'
    self.description = '帮王芳订明天早上从北京到上海的火车（6-8点出发），并在今晚（前一晚）预订北京含早餐的酒店'
    self.timeout_seconds = 300
  
    def prepare
      # 查询用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      # 设置基本参数
      @departure_city = '北京'
      @arrival_city = '上海'
      @train_date = Date.current + 1.day  # 明天
      
      # 查找早班火车（6-8点出发）
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .by_date(@train_date)
        .select { |t| t.departure_time.hour >= 6 && t.departure_time.hour < 8 }
      
      expect(@available_trains).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}早班火车（6-8点）"
      
      # 查找北京的4星级以上酒店（含早餐房型）
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@departure_city}%")
        .where("star_level >= ?", 4)
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@departure_city}的4星级以上酒店"
      
      # 计算酒店入住退房日期
      @hotel_checkin_date = @train_date - 1.day  # 今晚入住（火车前一晚）
      @hotel_checkout_date = @train_date  # 明天退房（火车当天）
      
      {
        task: "请为#{@passenger.name}预订#{@train_date.strftime('%Y年%m月%d日')}（明天）从#{@departure_city}到#{@arrival_city}的早班火车（6-8点出发），" \
              "并在#{@hotel_checkin_date.strftime('%Y年%m月%d日')}（今晚）预订#{@departure_city}含早餐的酒店",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          train_date: @train_date.to_s,
          departure_time: "6:00-8:00",
          hotel_location: @departure_city,
          hotel_checkin: @hotel_checkin_date.to_s,
          breakfast: "含早餐"
        },
        hint: "明天早班火车需要今晚入住酒店，明早享用早餐后出发",
        statistics: {
          available_early_trains: @available_trains.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      # 查询用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 创建火车订单（选择最早的早班火车）
      train = @available_trains.sort_by(&:departure_time).first
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
      
      # 创建酒店订单（优先选择含早餐的房型）
      hotel = @available_hotels.first
      # 筛选含早餐的房型（room_type包含“早”字）
      room = hotel.hotel_rooms.where(data_version: 0).where("room_type LIKE ?", "%早%").order(price: :asc).first!
      
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
      # 断言1: 创建了火车订单 (18%)
      add_assertion "创建了火车订单（#{@departure_city}→#{@arrival_city}）", weight: 18 do
        # 查询北京→上海的火车订单（过滤出出发城市和目的地）
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
      
      # 断言2: 火车出发时间正确（6-8点） (15%)
      add_assertion "火车出发时间正确（6-8点）", weight: 15 do
        departure_hour = @train_booking.train.departure_time.hour
        expect(departure_hour).to be >= 6, 
          "出发时间过早。期望: 6:00-8:00, 实际: #{@train_booking.train.departure_time.strftime('%H:%M')}"
        expect(departure_hour).to be < 8,
          "出发时间过晚。期望: 6:00-8:00, 实际: #{@train_booking.train.departure_time.strftime('%H:%M')}"
      end
      
      # 断言3: 创建了北京酒店订单 (15%)
      add_assertion "创建了北京酒店订单", weight: 15 do
        # 查询北京的酒店订单（使用LIKE模糊匹配城市名）
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where("hotels.city LIKE ?", "%#{@departure_city}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到北京酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言4: 酒店位置在北京（出发城市） (15%)
      add_assertion "酒店位置正确（必须在#{@departure_city}）", weight: 15 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@departure_city),
          "酒店城市错误。期望: #{@departure_city}, 实际: #{hotel.city}"
      end
      
      # 断言5: 酒店入住时间正确（今晚，火车前一晚） (15%)
      add_assertion "酒店入住时间正确（今晚）", weight: 15 do
        # 验证入住日期 = 今天（火车出发日前一天）
        expect(@hotel_booking.check_in_date).to eq(@hotel_checkin_date),
          "入住日期错误。期望: #{@hotel_checkin_date}（今晚，火车前一晚）, 实际: #{@hotel_booking.check_in_date}"
      end
      
      # 断言6: 酒店含早餐 (7%)
      add_assertion "酒店含早餐", weight: 7 do
        # 验证房型room_type包含“早”字
        room = @hotel_booking.hotel_room
        expect(room.room_type).to match(/早/),
          "房型未包含早餐。期望: 含早餐房型, 实际: #{room.room_type}"
      end
    
      # 断言7: 火车乘客信息正确（王芳） (7%)
      add_assertion "火车乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "火车乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.contact_phone).to eq(@expected_phone),
          "火车联系电话错误。期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
      end
    
      # 断言8: 酒店入住人信息正确（王芳） (8%)
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
        .select { |t| t.departure_time.hour >= 6 && t.departure_time.hour < 8 }
      
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@departure_city}%")
        .where("star_level >= ?", 4)
        .where(data_version: 0)
        .limit(20)
        .to_a
    end
  end
end
