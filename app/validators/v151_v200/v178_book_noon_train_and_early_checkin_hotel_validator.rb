# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例178: 给张三预订明天中午前到达的北京到上海火车，并预订支持提前入住的酒店（火车12:00前到达，如G90 06:30→11:00）
#
# 任务描述:
#   张三明天从北京坐火车到上海，需要中午前到达（12:00前，例如G90 06:30→11:00、G92 06:50→11:20）。
#   因为上午到达，需要预订支持提前入住的酒店，可以到了直接办理入住不用在大堂等待。
#   需要创建2个订单：
#   1. 火车订单（明天北京→上海，12:00前到达）
#   2. 酒店订单（明天入住上海酒店，支持提前入住）
#
# 业务流程:
#   1. 搜索并预订明天中午前到达的北京到上海火车（12:00前，例如G90 06:30出发11:00到达）
#   2. 记录火车到达日期（明天）
#   3. 预订上海的酒店（支持提前入住服务）
#   4. 入住日期：明天（火车到达当天，上午到达可以直接入住）
#   5. 退房日期：后天（入住后的第二天）
#   6. 乘客和入住人均为张三
#
# 复杂度分析:
#   1. 需要搜索并预订中午前到达的火车（12:00前，排除跨夜火车）
#   2. 需要理解"提前入住"的场景（上午到达即可办理入住，不用等下午2点）
#   3. 需要选择支持提前入住服务的酒店
#   4. 需要协调两个订单的日期关系（酒店入住日=火车到达日=明天）
#   ❌ 不能一次性提供：需要先查询上午到达的火车→确定火车到达日期（明天）→查找支持提前入住的酒店→预订火车→预订酒店
#
# 评分标准（总分100分）:
#   1. 创建了火车订单（明天北京→上海） (20分)
#   2. 火车到达时间正确（12:00前） (18分)
#   3. 创建了酒店订单 (15分)
#   4. 酒店位置正确（上海） (15分)
#   5. 酒店入住日期正确（火车到达当天） (12分)
#   6. 火车乘客信息正确（张三） (6分)
#   7. 酒店入住人信息正确（张三） (6分)
#   8. 酒店支持提前入住 (5分)
#   9. 预订的是整晚房间（非钟点房） (3分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v178_book_noon_train_and_early_checkin_hotel_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V178BookNoonTrainAndEarlyCheckinHotelValidator < BaseValidator
    self.validator_id = 'v178_book_noon_train_and_early_checkin_hotel_validator'
    self.task_id = '86a07e7f-aa31-4d1d-a9c7-4d13777246bb'
    self.title = '给张三预订明天中午前12:00到达的北京到上海火车（如G90 06:30→11:00），并预订支持提前入住的酒店'
    self.description = '帮张三订明天从北京到上海的火车（中午前12点到达，例如G90早上06:30起飞11:00到达），因为上午就到了，需要预订上海支持提前入住的酒店，可以到了直接办理入住不用在大堂等待'
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
      
      # 查找上海支持提前入住的酒店
      @available_hotels = Hotel
        .joins(:hotel_policy)
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(hotel_policies: { early_checkin_available: true })
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}支持提前入住的酒店"
      
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
      
      # 断言5: 酒店入住日期为火车到达当天 (12%)
      add_assertion "酒店入住日期正确（火车到达当天）", weight: 12 do
        expect(@hotel_booking.check_in_date).to eq(@train_date),
          "入住日期错误。期望: #{@train_date}（火车到达当天）, 实际: #{@hotel_booking.check_in_date}"
        
        # 验证退房日期
        expect(@hotel_booking.check_out_date).to eq(@hotel_checkout_date),
          "退房日期错误。期望: #{@hotel_checkout_date}, 实际: #{@hotel_booking.check_out_date}"
      end
    
      # 断言6: 火车乘客信息正确（张三） (6%)
      add_assertion "火车乘客信息正确（#{@expected_passenger_name}）", weight: 6 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "火车乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.contact_phone).to eq(@expected_phone),
          "火车联系电话错误。期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
      end
    
      # 断言7: 酒店入住人信息正确（张三） (6%)
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 6 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "酒店入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店联系电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言8: 酒店支持提前入住 (5%)
      add_assertion "酒店支持提前入住", weight: 5 do
        hotel = @hotel_booking.hotel
        hotel_policy = hotel.hotel_policy
        expect(hotel_policy).not_to be_nil, "酒店缺少政策信息"
        expect(hotel_policy.early_checkin_available).to eq(true),
          "酒店不支持提前入住。酒店: #{hotel.name}, early_checkin_available: #{hotel_policy.early_checkin_available}"
      end
      
      # 断言9: 预订的是整晚房间（非钟点房） (3%)
      add_assertion "预订的是整晚房间（非钟点房）", weight: 3 do
        room = @hotel_booking.hotel_room
        expect(room).not_to be_nil, "未找到酒店房间信息"
        expect(room.room_category).to eq('overnight'),
          "房间类型错误。期望: 整晚房(overnight), 实际: #{room.room_category}"
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
        .joins(:hotel_policy)
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(hotel_policies: { early_checkin_available: true })
        .where(data_version: 0)
        .limit(20)
        .to_a
    end
  end
end
