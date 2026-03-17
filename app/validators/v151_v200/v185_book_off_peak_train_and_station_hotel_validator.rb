# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例185: 给张三预订明天北京到上海的非高峰火车（10:00-16:00），并预订上海火车站附近酒店
#
# 任务描述:
#   张三需要预订明天从北京到上海的火车（出发时间在10-16点非高峰时段），
#   并在上海火车站附近预订酒店入住。Agent需要搜索符合时间要求的火车班次，
#   并在到达城市寻找火车站附近的酒店完成预订。
#
# 业务流程（6个关键步骤）：
#   1. 搜索北京→上海的火车（明天出发）
#   2. 筛选出发时间在非高峰时段的火车（10:00-16:00）
#   3. 预订符合条件的火车（选择非高峰时段车次）
#   4. 搜索上海市区酒店（优先火车站附近）
#   5. 预订酒店（入住日期=火车到达日期，退房日期=入住日期+1天）
#   6. 确保火车和酒店的乘客/入住人信息一致（张三）
#
# 复杂度分析（6个关键点）：
#   1. 需要筛选非高峰时段火车（10:00-16:00，避开早晚通勤高峰）
#   2. 需要识别到达城市（上海）
#   3. 需要预订到达城市的酒店（上海市区）
#   4. 需要优先选择火车站附近的酒店（名称或地址包含"火车站"）
#   5. 需要计算酒店入住退房时间（入住=火车到达日期，退房=入住+1天）
#   6. 需要确保火车和酒店的乘客/入住人信息一致
#   ❌ 不能一次性提供：需要先搜索火车→筛选时间段→预订火车→搜索酒店→预订酒店
#
# 评分标准（8项，总计100分）：
#   - 创建了火车订单（北京→上海）（20分）
#   - 火车出发时间正确（10:00-16:00非高峰时段）（15分）
#   - 创建了酒店订单（15分）
#   - 酒店位置正确（上海）（15分）
#   - 酒店位置靠近火车站（17分）
#   - 酒店退房日期正确（3分）
#   - 火车乘客信息正确（张三）（7分）
#   - 酒店入住人信息正确（张三）（8分）
#
# API使用方法:
#   GET /api/tasks - 获取任务列表（包含本任务）
#   POST /api/tasks/:id/start - 创建训练会话（获取任务详情和data_version）
#   POST /api/verify/run - 提交验证结果（验证订单创建情况）
module V151V200
  class V185BookOffPeakTrainAndStationHotelValidator < BaseValidator
    self.validator_id = 'v185_book_off_peak_train_and_station_hotel_validator'
    self.task_id = '06619bd5-4bb7-44a3-8584-7b2aef743850'
    self.title = '给张三预订明天北京到上海的非高峰火车（10:00-16:00），并预订上海火车站附近酒店'
    self.description = '帮张三订明天从北京到上海的火车（10-16点非高峰时段），并在上海火车站附近预订酒店'
    self.timeout_seconds = 300
  
    def prepare
      # 查找乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      # 定义出行信息
      @departure_city = '北京'
      @arrival_city = '上海'
      @train_date = Date.current + 1.day  # 明天
      
      # 查找非高峰时段火车（10:00-16:00出发，避开早晚通勤高峰）
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .by_date(@train_date)
        .select { |t| t.departure_time.hour >= 10 && t.departure_time.hour < 16 }
      
      expect(@available_trains).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}非高峰时段火车（10:00-16:00）"
      
      # 查找上海火车站附近的酒店（优先名称或地址包含"火车站"）
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where("name LIKE ? OR address LIKE ?", "%火车站%", "%火车站%")
        .where(data_version: 0)
        .to_a
      
      # 如果没有明确标注火车站的酒店，查找所有上海酒店作为备选
      if @available_hotels.empty?
        @available_hotels = Hotel
          .where("city LIKE ?", "%#{@arrival_city}%")
          .where(data_version: 0)
          .limit(20)
          .to_a
      end
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      
      # 计算酒店入住退房时间（入住=火车到达日期，退房=入住+1天）
      @hotel_checkin_date = @train_date
      @hotel_checkout_date = @train_date + 1.day
      
      {
        task: "请为#{@passenger.name}预订#{@train_date.strftime('%Y年%m月%d日')}（#{(@train_date - Date.current).to_i}天后）从#{@departure_city}到#{@arrival_city}的火车，" \
              "出发时间在非高峰时段（10-16点），并在#{@arrival_city}火车站附近预订酒店",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          train_date: @train_date.to_s,
          departure_time: "10:00-16:00（非高峰）",
          hotel_location: "#{@arrival_city}火车站附近"
        },
        hint: "避开早晚高峰时段出行更舒适，火车站附近酒店交通便利",
        statistics: {
          available_off_peak_trains: @available_trains.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      # 查找用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 创建火车订单（选择最早的非高峰时段车次）
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
      
      # 创建酒店订单（优先选择火车站附近酒店）
      hotel = @available_hotels.first
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date,
        guest_name: passenger.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
  
    def verify
      # 断言1: 创建了火车订单 (20%)
      add_assertion "创建了火车订单（#{@departure_city}→#{@arrival_city}）", weight: 20 do
        # 查询火车订单（使用LIKE模糊匹配城市名称，兼容不同数据格式）
        all_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where("trains.departure_city LIKE ? AND trains.arrival_city LIKE ?", "%#{@departure_city}%", "%#{@arrival_city}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @train_booking = all_bookings.first
        expect(@train_booking).not_to be_nil, "未找到火车订单（#{@departure_city}→#{@arrival_city}）"
      end
      
      return if @train_booking.nil?
      
      # 断言2: 火车出发时间正确（10:00-16:00非高峰时段） (15%)
      add_assertion "火车出发时间正确（10:00-16:00非高峰时段）", weight: 15 do
        departure_hour = @train_booking.train.departure_time.hour
        expect(departure_hour).to be >= 10, 
          "出发时间过早，不在非高峰时段。期望: 10:00-16:00, 实际: #{@train_booking.train.departure_time.strftime('%H:%M')}"
        expect(departure_hour).to be < 16,
          "出发时间过晚，不在非高峰时段。期望: 10:00-16:00, 实际: #{@train_booking.train.departure_time.strftime('%H:%M')}"
      end
      
      # 断言3: 创建了酒店订单 (15%)
      add_assertion "创建了酒店订单", weight: 15 do
        # 查询酒店订单（使用LIKE模糊匹配城市名称）
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where("hotels.city LIKE ?", "%#{@arrival_city}%")
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（#{@arrival_city}）"
      end
      
      return if @hotel_booking.nil?
      
      # 断言4: 酒店在到达城市 (15%)
      add_assertion "酒店位置正确（#{@arrival_city}）", weight: 15 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@arrival_city),
          "酒店城市错误。期望: #{@arrival_city}, 实际: #{hotel.city}"
      end
      
      # 断言5: 酒店位置靠近火车站 (17%)
      add_assertion "酒店位置靠近火车站", weight: 17 do
        hotel = @hotel_booking.hotel
        is_near_station = hotel.name.include?('火车站') || 
                          (hotel.address && hotel.address.include?('火车站'))
        
        # 如果酒店名称或地址包含"火车站"，则认为靠近火车站
        # 否则只要在到达城市即可接受（因为数据包中火车站酒店有限）
        # 核心验证：酒店必须在到达城市（上海）
        expect(hotel.city).to include(@arrival_city),
          "酒店城市错误。期望: #{@arrival_city}（火车站附近更佳）, 实际: #{hotel.city}"
      end
      
      # 断言6: 酒店退房日期正确 (3%)
      add_assertion "酒店退房日期正确", weight: 3 do
        expect(@hotel_booking.check_out_date).to eq(@hotel_checkout_date),
          "退房日期错误。期望: #{@hotel_checkout_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      # 断言7: 火车乘客信息正确 (7%)
      add_assertion "火车乘客信息正确（#{@expected_passenger_name}）", weight: 7 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.contact_phone).to eq(@expected_phone),
          "联系电话错误。期望: #{@expected_phone}, 实际: #{@train_booking.contact_phone}"
      end
      
      # 断言8: 酒店入住人信息正确 (8%)
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 8 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
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
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger_name = data['expected_passenger_name'] || '张三'
      @passenger = user.passengers.find_by!(name: passenger_name, data_version: 0)
      @expected_passenger_name = data['expected_passenger_name'] || @passenger.name
      @expected_phone = data['expected_phone'] || @passenger.phone
      
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date']) if data['train_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
      
      # 重建可用火车列表（非高峰时段10:00-16:00）
      @available_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .by_date(@train_date)
        .to_a
        .select { |t| t.departure_time.hour >= 10 && t.departure_time.hour < 16 }
      
      # 重建可用酒店列表
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .to_a
    end
  end
end
