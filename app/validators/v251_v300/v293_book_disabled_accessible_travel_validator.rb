# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例293: 帮王芳预订2天后从广州到上海的健康养生出行（航班+带游泳池的酒店）
#
# 任务描述:
#   王芳计划2天后从广州到上海进行健康养生之旅，需要放松身心。
#   Agent 需要分别预订两个独立订单：
#   1. 航班订单（Booking）：广州→上海，2天后出发
#   2. 酒店订单（HotelBooking）：上海带游泳池的酒店，入住2天后、2晚
#   ⚠️ 重要：这是两个完全独立的订单，不是套餐。
#   Agent 需要理解健康养生出行的需求，选择有游泳池设施的酒店。
#
# 业务流程（6个关键步骤）：
#   1. 搜索广州到上海的2天后的航班
#   2. 选择合适的航班（出发日期 = Date.current + 2.days）
#   3. 填写乘机人信息（王芳）并预订航班
#   4. 搜索上海城区带游泳池的酒店
#   5. 选择有游泳池设施的酒店（facilities字段包含"游泳池"）
#   6. 填写入住信息（入住日期 = 2天后，退房日期 = 4天后）并预订酒店
#
# 复杂度分析（6个关键点）：
#   1. 需要理解双模块业务组合：航班 + 酒店两个独立模块的订单创建
#   2. 需要理解城市匹配逻辑：航班目的地 = 酒店城市（都是上海）
#   3. 需要理解日期计算：出发日期 = 2天后，返回日期 = 4天后，酒店入住2晚
#   4. 需要理解时间衔接：酒店入住日期 = 航班出发日期
#   5. 需要理解信息一致性：所有订单的联系人信息均为王芳及其电话号码
#   6. 需要理解酒店设施筛选：选择facilities字段包含"游泳池"的酒店
#   ❌ 不能随机选择：必须精确匹配城市、日期、联系人信息和酒店设施
#
# 评分标准（5项，总计100分）：
#   - 创建了航班预订（30分）
#   - 创建了带游泳池的酒店预订（30分）
#   - 乘客信息正确（王芳）（15分）
#   - 航班和酒店城市匹配（都是上海）（15分）
#   - 订单状态正确（10分）
module V251V300
  class V293BookDisabledAccessibleTravelValidator < BaseValidator
    self.validator_id = 'v293_book_disabled_accessible_travel_validator'
    self.task_id = '5a979b48-b8b5-425a-ae5d-8f4b27ee1d4d'
    self.title = '帮王芳预订2天后从广州到上海的健康养生出行（航班+带游泳池的酒店）'
    self.description = '帮王芳预订2天后从广州到上海的健康养生出行（航班+带游泳池的酒店）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '广州'
      @destination_city = '上海'
      @departure_date = Date.current + 2.days
      @return_date = @departure_date + 2.days
      
      # 预查询乘客信息（王芳）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @wangfang.name
      @expected_passenger_id_number = @wangfang.id_number
      @expected_contact_phone = @wangfang.phone
      
      if user.balance < 3000
        user.update!(balance: 5000)
      end
      
      {
        task: "请给王芳预订健康养生出行方案，分别完成以下两个订单：\n1. 使用Booking模型创建航班订单：从#{@departure_city}到#{@destination_city}，#{@departure_date.strftime('%Y年%-m月%-d日')}出发\n2. 使用HotelBooking模型创建酒店订单：#{@destination_city}带游泳池的酒店，#{@departure_date.strftime('%Y年%-m月%-d日')}入住，#{@return_date.strftime('%Y年%-m月%-d日')}退房\n⚠️ 重要提示：这不是套餐订单，是两个独立的普通订单（Booking + HotelBooking）",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        return_date: @return_date.to_s,
        hint: "预订航班和带游泳池的酒店，让身心得到放松"
      }
    end
    
    def verify
      add_assertion "创建了航班预订", weight: 30 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, 
          "未找到从#{@departure_city}到#{@destination_city}的航班预订"
        
        @booking = all_bookings.first
      end
      
      return unless @booking  # Guard clause
      
      add_assertion "创建了带游泳池的酒店预订", weight: 30 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_hotel_bookings).not_to be_empty, 
          "未找到#{@destination_city}的酒店预订"
        
        @hotel_booking = all_hotel_bookings.first
        
        # 验证酒店有游泳池设施
        hotel_facilities = @hotel_booking.hotel.facilities || ''
        expect(hotel_facilities).to include('游泳池'),
          "预订的酒店没有游泳池设施。酒店: #{@hotel_booking.hotel.name}，设施: #{hotel_facilities}"
      end
      
      add_assertion "乘客信息正确（王芳）", weight: 15 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}（王芳），实际: #{@booking.passenger_name}"
        expect(@booking.passenger_id_number).to eq(@expected_passenger_id_number),
          "乘客身份证号错误。期望: #{@expected_passenger_id_number}，实际: #{@booking.passenger_id_number}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}，实际: #{@booking.contact_phone}"
      end
      
      return unless @hotel_booking  # Guard clause
      
      add_assertion "航班和酒店城市匹配（#{@destination_city}）", weight: 15 do
        flight = @booking.flight
        hotel = @hotel_booking.hotel
        expect(flight.destination_city).to eq(hotel.city),
          "航班目的地与酒店城市不匹配。航班目的地: #{flight.destination_city}，酒店城市: #{hotel.city}"
      end
      
      add_assertion "订单状态正确", weight: 10 do
        valid_booking_statuses = ['pending', 'paid', 'confirmed']
        valid_hotel_statuses = ['pending', 'paid', 'confirmed']
        
        expect(valid_booking_statuses).to include(@booking.status),
          "航班订单状态错误: #{@booking.status}"
        expect(valid_hotel_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 1. 预订航班
      flight = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).by_date(@departure_date).order(price: :asc).first!
      
      Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: wangfang.name,
        contact_phone: wangfang.phone,
        passenger_id_number: wangfang.id_number,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 预订带游泳池的酒店（选择有游泳池设施的酒店）
      hotel = Hotel.where(city: @destination_city, data_version: 0)
                   .where("facilities LIKE ?", "%游泳池%")
                   .first!
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @departure_date,
        check_out_date: @return_date,
        guest_name: wangfang.name,
        guest_phone: wangfang.phone,
        payment_method: '花呗',
        total_price: hotel.price * (@return_date - @departure_date).to_i,
        status: 'pending',
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
        expected_passenger_id_number: @expected_passenger_id_number,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @return_date = Date.parse(data['return_date']) if data['return_date']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id_number = data['expected_passenger_id_number']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
