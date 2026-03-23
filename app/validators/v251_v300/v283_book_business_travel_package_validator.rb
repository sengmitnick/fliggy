# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例283: 帮张三预订3天后深圳→上海航班（MU5304，16:45到达）+上海丽思卡尔顿酒店（当天入住2晚）+机场接机（16:45，送至陆家嘴金融区接送服务点）
#
# 任务描述:
#   张三计划3天后从深圳出差到上海，需要分别预订三个独立的订单：
#   1. 航班订单（Booking）：深圳→上海，3天后出发
#   2. 酒店订单（HotelBooking）：上海城区商务酒店，入住3天后、2晚
#   3. 接机订单（Transfer）：上海机场→接机目的地
#   ⚠️ 重要：这是三个完全独立的订单，不是酒店套餐（HotelPackage），不要使用HotelPackageOrder。
#   Agent 需要理解商务出差的完整流程，在符合条件的航班、酒店、接机服务中分别选择合适的产品，并确保三者的城市、日期、时间一致性。
#
# 业务流程（9个关键步骤）：
#   1. 搜索深圳到上海的3天后的航班
#   2. 选择合适的航班（出发日期 = Date.current + 3.days）
#   3. 填写乘机人信息（张三）并预订航班
#   4. 搜索上海城区的商务酒店
#   5. 选择高档商务酒店（按价格降序排序）
#   6. 填写入住信息（入住日期 = 3天后，退房日期 = 5天后）并预订酒店
#   7. 选择接机服务（上海机场→酒店）
#   8. 填写接机时间（航班到达时间）和送达地址（已预订的酒店地址）
#   9. 提交接机订单
#
# 复杂度分析（8个关键点）：
#   1. 需要理解多模块业务组合：航班 + 酒店 + 接机三个独立模块的订单创建
#   2. 需要理解城市匹配逻辑：航班目的地 = 酒店城市 = 接机出发地（都是上海）
#   3. 需要理解日期计算：出发日期 = 3天后，返回日期 = 5天后，酒店入住2晚
#   4. 需要理解时间衔接：接机时间 = 航班到达时间，酒店入住日期 = 航班出发日期
#   5. 需要理解地址关联：接机送达地址 = 已预订的酒店地址
#   6. 需要理解信息一致性：所有订单的联系人信息均为张三及其电话号码
#   7. 需要理解接机服务类型：选择 'from_airport'（从机场到酒店）
#   8. 需要理解订单依赖关系：必须先预订航班（获取到达时间）和酒店（获取地址）后，才能填写接机信息
#   ❌ 不能随机选择：必须精确匹配城市、日期、联系人信息
#
# 评分标准（11项，总计100分）：
#   - 创建了航班预订（10分）
#   - 创建了酒店预订（10分）
#   - 创建了接机订单（5分）
#   - 航班号正确（MU5304）（10分）
#   - 酒店名称正确（上海丽思卡尔顿酒店）（10分）
#   - 航班和酒店城市匹配（都是上海）（5分）
#   - 航班乘机人信息正确（张三）（15分）
#   - 酒店入住人信息正确（张三）（10分）
#   - 航班出发日期正确（3天后）（5分）
#   - 酒店入住/退房日期正确（3天后入住，5天后退房）（5分）
#   - 接机时间和地址正确（16:45到达后20-40分钟，送至陆家嘴金融区接送服务点）（15分）
module V251V300
  class V283BookBusinessTravelPackageValidator < BaseValidator
    self.validator_id = 'v283_book_business_travel_package_validator'
    self.task_id = '0c50dfc5-f31e-459a-b5bf-22f355a7cbce'
    self.title = '帮张三预订3天后深圳→上海航班（MU5304，16:45到达）+上海丽思卡尔顿酒店（当天入住2晚）+机场接机（16:45，送至陆家嘴金融区接送服务点）'
    self.description = '帮张三预订3天后深圳→上海航班（MU5304，16:45到达）+上海丽思卡尔顿酒店（当天入住2晚）+机场接机（16:45，送至陆家嘴金融区接送服务点）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @destination_city = '上海'
      @departure_date = Date.current + 3.days
      @return_date = @departure_date + 2.days
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      if user.balance < 3000
        user.update!(balance: 5000)
      end
      
      {
        task: "请给张三预订商务出差行程，分别完成以下三个订单：\n1. 使用Booking模型创建航班订单：从#{@departure_city}到#{@destination_city}，#{@departure_date.strftime('%Y年%-m月%-d日')}出发\n2. 使用HotelBooking模型创建酒店订单：#{@destination_city}城区商务酒店，#{@departure_date.strftime('%Y年%-m月%-d日')}入住，#{@return_date.strftime('%Y年%-m月%-d日')}退房\n3. 使用Transfer模型创建接机订单：#{@destination_city}机场接机服务\n⚠️ 重要提示：这不是HotelPackage套餐订单，是三个独立的普通订单（Booking + HotelBooking + Transfer）",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        return_date: @return_date.to_s,
        hint: "预订航班、商务酒店和机场接机服务，形成完整的出差方案"
      }
    end
    
    def verify
      add_assertion "创建了航班预订", weight: 10 do
        @booking = Booking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@booking).not_to be_nil, "未找到航班预订"
      end
      
      add_assertion "创建了酒店预订", weight: 10 do
        @hotel_booking = HotelBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到酒店预订"
      end
      
      add_assertion "创建了接机订单", weight: 5 do
        @transfer = Transfer
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@transfer).not_to be_nil, "未找到接机订单"
      end
      
      return unless @booking && @hotel_booking && @transfer
      
      add_assertion "航班号正确（MU5304）", weight: 10 do
        flight = @booking.flight
        expected_flight_number = 'MU5304'
        expect(flight.flight_number).to eq(expected_flight_number),
          "航班号错误。期望: #{expected_flight_number}，实际: #{flight.flight_number}"
      end
      
      add_assertion "酒店名称正确（上海丽思卡尔顿酒店）", weight: 10 do
        hotel = @hotel_booking.hotel
        expected_hotel_name = '上海丽思卡尔顿酒店'
        expect(hotel.name).to eq(expected_hotel_name),
          "酒店名称错误。期望: #{expected_hotel_name}，实际: #{hotel.name}"
      end
      
      add_assertion "接机时间和地址正确（16:45到达后20-40分钟，送至陆家嘴金融区接送服务点）", weight: 15 do
        flight = @booking.flight
        expected_location = '陆家嘴金融区接送服务点'
        
        # 验证送达地址 = 陆家嘴金融区接送服务点
        expect(@transfer.location_to).to eq(expected_location),
          "送达地址错误。期望: #{expected_location}（数据库中的接机目的地），实际: #{@transfer.location_to}"
        
        # 验证接机时间在航班到达后20-40分钟
        arrival_time = flight.arrival_time
        actual_pickup = @transfer.pickup_datetime
        return if arrival_time.nil? || actual_pickup.nil?  # Guard clause
        
        time_after_arrival = ((actual_pickup - arrival_time) / 60.0).round
        
        expect(time_after_arrival >= 20 && time_after_arrival <= 40).to be(true),
          "接机时间不合理。航班到达: #{arrival_time.strftime('%H:%M')}，接机时间: #{actual_pickup.strftime('%H:%M')}，间隔: #{time_after_arrival}分钟（期望20-40分钟）"
      end
      
      add_assertion "航班和酒店城市匹配", weight: 5 do
        flight = @booking.flight
        hotel = @hotel_booking.hotel
        expect(flight.destination_city).to eq(hotel.city),
          "航班目的地与酒店城市不匹配。航班目的地: #{flight.destination_city}, 酒店城市: #{hotel.city}"
      end
      
      add_assertion "航班乘机人信息正确（张三）", weight: 15 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘机人姓名错误。期望: #{@expected_passenger_name}（张三），实际: #{@booking.passenger_name}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "乘机人联系电话错误。期望: #{@expected_contact_phone}，实际: #{@booking.contact_phone}"
      end
      
      add_assertion "酒店入住人信息正确（张三）", weight: 10 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}（张三），实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_contact_phone),
          "入住人联系电话错误。期望: #{@expected_contact_phone}，实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "航班出发日期正确", weight: 5 do
        flight = @booking.flight
        booking_date = flight.departure_time.to_date
        expect(booking_date).to eq(@departure_date),
          "航班出发日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（3天后），实际: #{booking_date.strftime('%Y-%m-%d')}"
      end
      
      add_assertion "酒店入住/退房日期正确", weight: 5 do
        expect(@hotel_booking.check_in_date).to eq(@departure_date),
          "入住日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（3天后），实际: #{@hotel_booking.check_in_date.strftime('%Y-%m-%d')}"
        expect(@hotel_booking.check_out_date).to eq(@return_date),
          "退房日期错误。期望: #{@return_date.strftime('%Y-%m-%d')}（5天后），实际: #{@hotel_booking.check_out_date.strftime('%Y-%m-%d')}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 预订航班（选择指定航班号 MU5304）
      flight = Flight
        .where(departure_city: @departure_city, destination_city: @destination_city, flight_number: 'MU5304', data_version: 0)
        .by_date(@departure_date)
        .first!
      booking = Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        passenger_id_number: zhangsan.id_number,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 预订酒店
      hotel = Hotel.where(city: @destination_city, data_version: 0).order(price: :desc).first!
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @departure_date,
        check_out_date: @return_date,
        guest_name: zhangsan.name,
        guest_phone: zhangsan.phone,
        payment_method: '花呗',
        total_price: hotel.price * (@return_date - @departure_date).to_i,
        status: 'pending',
        data_version: @data_version
      )
      
      # 预订接机服务（使用数据库中的目的地）
      transfer_location = TransferLocation.find_by!(name: '陆家嘴金融区接送服务点', data_version: 0)
      transfer_package = TransferPackage.where(data_version: 0).order(price: :asc).first!
      Transfer.create!(
        user_id: user.id,
        transfer_package_id: transfer_package.id,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: "#{@destination_city}机场",
        location_to: transfer_location.name,
        pickup_datetime: flight.arrival_time + 30.minutes,  # 接机时间 = 航班到达后30分钟
        passenger_name: zhangsan.name,
        passenger_phone: zhangsan.phone,
        luggage_count: 1,
        total_price: transfer_package.price,
        discount_amount: 0,
        status: 'pending',
        driver_status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date&.to_s,
        return_date: @return_date&.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @return_date = Date.parse(data['return_date']) if data['return_date']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
