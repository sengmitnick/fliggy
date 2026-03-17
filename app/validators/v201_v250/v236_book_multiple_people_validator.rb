# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例236: 帮张三、王芳、小明、李四这4个人订5天后从北京到三亚的机票和酒店，要4张机票和2个房间，住3晚
#
# 任务描述:
#   张三、王芳、小明、李四4人家庭需要5天后从北京去三亚旅游，需要预订4张机票和2个房间，住3晚。
#   Agent需要创建4个航班订单（每人1张票）和1个酒店订单（2个房间），确保日期一致。
#
# 业务流程（7个关键步骤）：
#   1. 明确受益人信息（张三、王芳、小明、李四4人，张三为联系人）
#   2. 搜索5天后从北京到三亚的航班
#   3. 为4位乘客分别创建航班订单（使用各自的乘客信息）
#   4. 搜索三亚酒店
#   5. 选择合适的房间
#   6. 创建酒店订单（2个房间，住3晚）
#   7. 确认航班和酒店日期匹配（航班日期=入住日期）
#
# 复杂度分析（6个关键点）：
#   1. 需要理解多人出行场景，为每位乘客创建独立的航班订单
#   2. 需要准确计算航班日期（5天后）和酒店入住/退房日期
#   3. 需要查询4位乘客的个人信息（姓名、身份证号、电话）
#   4. 需要创建4个航班订单（每人1张票），共计4张机票
#   5. 需要创建1个酒店订单并设置room_count=2（2个房间）
#   6. 需要确保航班日期和酒店入住日期匹配
#   ❌ 不能只创建1个航班订单（必须为每位乘客创建独立订单）
#   ✅ 正确：创建1个酒店订单，设置rooms_count=2（系统实际使用的字段）
#   ❌ 不能创建2个酒店订单（应该是1个订单设置rooms_count=2）
#   ❌ 不能使用room_count字段（那是后来添加的冗余字段，系统不用）
#
# 评分标准（9项，总计100分）：
#   1. 创建了航班订单（15分）
#   2. 乘客数量正确（≥4人）（15分）- 核心业务逻辑
#   3. 航班日期正确（5天后）（5分）
#   4. 联系电话正确（张三电话）（5分）
#   5. 创建了酒店订单（15分）
#   6. 房间数量正确（≥2间）（15分）- 核心业务逻辑
#   7. 酒店入住日期和时长正确（5天后入住，住3晚）（10分）
#   8. 入住人电话正确（张三电话）（5分）
#   9. 订单状态有效（15分）
#
# 使用方法:
#   rake validator:simulate_single[v236_book_multiple_people_validator]
module V201V250
  class V236BookMultiplePeopleValidator < BaseValidator
    self.validator_id = 'v236_book_multiple_people_validator'
    self.task_id = '2ff2e3ff-3f3f-3f5f-5f6f-4f7a8b9c0d1f'
    self.title = '帮张三、王芳、小明、李四这4个人订5天后从北京到三亚的机票和酒店，要4张机票和2个房间，住3晚'
    self.description = '帮张三、王芳、小明、李四这4个人订5天后从北京到三亚的机票和酒店，要4张机票和2个房间，住3晚'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '三亚'
      @travel_date = Date.current + 5.days
      @check_in_date = @travel_date
      @check_out_date = @check_in_date + 3.days
      @passenger_count = 4  # 4人家庭
      @room_count = 2  # 2个房间
      @nights = 3
      
      # 查询demo_user和4位乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = demo_user.passengers.find_by!(name: '张三', data_version: 0)
      @wangfang = demo_user.passengers.find_by!(name: '王芳', data_version: 0)
      @xiaoming = demo_user.passengers.find_by!(name: '小明', data_version: 0)
      @lisi = demo_user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_contact_phone = @zhangsan.phone
      @expected_passenger_names = [@zhangsan.name, @wangfang.name, @xiaoming.name, @lisi.name]
      
      # 查询可用航班（按价格排序）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @travel_date,
        data_version: 0
      ).order(:price).to_a
      
      raise "未找到#{@travel_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@destination_city}的航班" if @available_flights.empty?
      
      # 查询可用酒店和房间（按酒店评分和房间价格排序）
      @available_hotels = Hotel.joins(:hotel_rooms)
        .where(city: @destination_city, data_version: 0)
        .where(hotel_rooms: { data_version: 0, room_category: 'overnight' })
        .distinct
        .order('hotels.rating DESC')
        .to_a
      
      raise "未找到#{@destination_city}的可用酒店" if @available_hotels.empty?
      
      {
        task: "请为张三、王芳、小明、李四4人预订#{@travel_date.strftime('%Y年%m月%d日')}（5天后）从#{@departure_city}到#{@destination_city}的航班（#{@passenger_count}张机票）和酒店（#{@room_count}个房间，住#{@nights}晚）。张三为联系人。",
        requirements: {
          beneficiaries: '张三、王芳、小明、李四',
          contact: '张三',
          departure_city: @departure_city,
          destination_city: @destination_city,
          travel_date: @travel_date.to_s,
          flight_tickets: "#{@passenger_count}张机票",
          hotel_rooms: "#{@room_count}个房间",
          nights: @nights,
          purpose: '家庭出行'
        },
        hint: "需要为4位乘客分别创建航班订单（共#{@passenger_count}张票），然后创建1个酒店订单（设置room_count=#{@room_count}）。",
        statistics: {
          available_flights: @available_flights.count,
          flight_price_range: {
            min: @available_flights.minimum(:price),
            max: @available_flights.maximum(:price)
          },
          cheapest_flight: @available_flights.first&.flight_number,
          available_hotels: @available_hotels.count,
          top_hotel: @available_hotels.first&.name,
          passengers: @expected_passenger_names.join('、')
        }
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 15 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @flight_bookings = all_bookings
        expect(@flight_bookings).not_to be_empty, "未找到从#{@departure_city}到#{@destination_city}的航班订单"
      end
      
      return if @flight_bookings.empty?
      
      add_assertion "乘客数量正确（≥#{@passenger_count}人）（核心要求）", weight: 15 do
        # 统计订单数量（每个订单代表一张机票）
        total_passengers = @flight_bookings.size
        
        expect(total_passengers).to be >= @passenger_count,
          "乘客数量不足。要求: ≥#{@passenger_count}人（张三、王芳、小明、李四），实际: #{total_passengers}人"
      end
      
      add_assertion "航班日期正确（#{@travel_date.strftime('%m月%d日')}，5天后）", weight: 5 do
        @flight_bookings.each do |booking|
          expect(booking.flight.flight_date).to eq(@travel_date),
            "航班日期错误。期望: #{@travel_date}（5天后），实际: #{booking.flight.flight_date}"
        end
      end
      
      add_assertion "联系电话正确（张三）", weight: 5 do
        @flight_bookings.each do |booking|
          expect(booking.contact_phone).to eq(@expected_contact_phone),
            "联系电话错误。期望: #{@expected_contact_phone}（张三），实际: #{booking.contact_phone}"
        end
      end
      
      add_assertion "创建了酒店订单", weight: 15 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_bookings = all_hotel_bookings
        expect(@hotel_bookings).not_to be_empty, "未找到#{@destination_city}的酒店订单"
      end
      
      return if @hotel_bookings.empty?
      
      add_assertion "房间数量正确（≥#{@room_count}间）（核心要求）", weight: 15 do
        # 使用 rooms_count 字段（系统实际使用的字段：前端表单、控制器、模型验证都用这个）
        total_rooms = @hotel_bookings.sum(&:rooms_count)
        
        expect(total_rooms).to be >= @room_count,
          "房间数量不足。要求: ≥#{@room_count}间（4人家庭需要2个房间），实际: #{total_rooms}间"
      end
      
      add_assertion "酒店入住日期和时长正确（#{@check_in_date.strftime('%m月%d日')}入住，住#{@nights}晚）", weight: 10 do
        @hotel_bookings.each do |booking|
          expect(booking.check_in_date).to eq(@check_in_date),
            "入住日期错误。期望: #{@check_in_date}（5天后，与航班日期一致），实际: #{booking.check_in_date}"
          expect(booking.check_out_date).to eq(@check_out_date),
            "退房日期错误。期望: #{@check_out_date}（8天后），实际: #{booking.check_out_date}"
        end
      end
      
      add_assertion "入住人电话正确（张三）", weight: 5 do
        @hotel_bookings.each do |booking|
          expect(booking.guest_phone).to eq(@expected_contact_phone),
            "入住人电话错误。期望: #{@expected_contact_phone}（张三），实际: #{booking.guest_phone}"
        end
      end
      
      add_assertion "订单状态有效", weight: 15 do
        @flight_bookings.each do |booking|
          expect(booking.status).to be_in(['pending', 'paid', 'completed']),
            "航班订单状态无效。实际: #{booking.status}"
        end
        @hotel_bookings.each do |booking|
          expect(booking.status).to be_in(['pending', 'paid', 'completed']),
            "酒店订单状态无效。实际: #{booking.status}"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passengers = [@zhangsan, @wangfang, @xiaoming, @lisi]
      
      # 选择一个航班，为每位乘客创建独立订单（共4张票）
      flight = @available_flights.first
      raise "未找到从#{@departure_city}到#{@destination_city}的可用航班" if flight.nil?
      
      passengers.each do |passenger|
        Booking.create!(
          user: user,
          flight: flight,
          passenger_name: passenger.name,
          passenger_id_number: passenger.id_number,
          contact_phone: @expected_contact_phone,
          total_price: flight.price,
          accept_terms: true,
          status: 'paid',
          data_version: @data_version
        )
      end
      
      # 选择一个酒店，创建1个订单（设置room_count=2）
      hotel = @available_hotels.first
      raise "未找到#{@destination_city}的可用酒店" if hotel.nil?
      
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(:price).first
      raise "未找到#{hotel.name}的可用房间" if room.nil?
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @zhangsan.name,
        guest_phone: @expected_contact_phone,
        rooms_count: @room_count,  # 使用 rooms_count（系统实际使用的字段）
        adults_count: @passenger_count,
        total_price: room.price * @room_count * @nights,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        travel_date: @travel_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        passenger_count: @passenger_count,
        room_count: @room_count,
        nights: @nights,
        expected_contact_phone: @expected_contact_phone,
        expected_passenger_names: @expected_passenger_names,
        zhangsan_id: @zhangsan.id,
        wangfang_id: @wangfang.id,
        xiaoming_id: @xiaoming.id,
        lisi_id: @lisi.id
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @travel_date = Date.parse(data['travel_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @passenger_count = data['passenger_count']
      @room_count = data['room_count']
      @nights = data['nights']
      @expected_contact_phone = data['expected_contact_phone']
      @expected_passenger_names = data['expected_passenger_names']
      
      # 恢复乘客对象引用
      @zhangsan = Passenger.find(data['zhangsan_id'])
      @wangfang = Passenger.find(data['wangfang_id'])
      @xiaoming = Passenger.find(data['xiaoming_id'])
      @lisi = Passenger.find(data['lisi_id'])
      
      # 恢复航班查询结果（按价格排序）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @travel_date,
        data_version: 0
      ).order(:price).to_a
      
      # 恢复酒店查询结果（按评分排序，筛选有过夜房间）
      @available_hotels = Hotel.joins(:hotel_rooms)
        .where(city: @destination_city, data_version: 0)
        .where(hotel_rooms: { data_version: 0, room_category: 'overnight' })
        .distinct
        .order('hotels.rating DESC')
        .to_a
    end
  end
end
