# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例199: 给李四预订明天上海CBD商务酒店+机场接送服务（北京→上海航班明天上午10点到达，浦东机场T1→CBD商圈酒店）
#
# 任务描述:
#   李四明天从北京坐飞机到上海（CA1831航班，明天上午10点到达浦东T1），需要预订CBD商务酒店，
#   并预订机场接送服务（从浦东机场接到酒店）。
#   Agent 需要通过搜索CA1831航班确定到达机场位置和到达时间，然后预订接机服务
#
# 核心要求:
#   - 酒店类型：商务型酒店（CBD/高星级≥4星/高价格≥500元）
#   - 酒店位置：上海市内（CBD商务区优先）
#   - 接送服务：机场接机服务（from_airport = 从机场接到酒店）
#   - 航班信息：CA1831（北京→上海），明天上午10点到达浦东机场T1
#   - 上车点：浦东机场T1（通过航班搜索确定）
#   - 下车点：酒店地址（CBD商圈酒店）
#   - 接机时间：明天上午10点（与航班到达时间匹配）
#
# 业务流程:
#   1. 用户选择"接我"服务（from_airport = 从机场接到目的地）
#   2. 搜索CA1831航班（北京→上海），确定到达机场（浦东机场T1）和到达时间（10:00）
#   3. 查找上海CBD商务型酒店（高星级≥4星 或 高价格≥500元）
#   4. 创建酒店订单（入住日期：明天）
#   5. 创建机场接机订单
#   6. 上车点：浦东机场T1接机处（location_from，通过CA1831航班搜索确定）
#   7. 下车点：酒店地址（location_to，CBD商圈酒店）
#   8. 接机时间：明天上午10点（pickup_datetime，与CA1831航班到达时间匹配）
#
# 复杂度分析:
#   - 数据查询：航班、酒店、接送服务（3个模型）
#   - 业务逻辑：酒店订单 + 接送服务订单（2个订单）
#   - 航班搜索：需要搜索CA1831航班（北京→上海），确定到达机场位置（浦东T1）和到达时间（10:00）
#   - 酒店筛选：必须是商务型（星级≥4星 或 价格≥500元）
#   - 服务类型：必须理解"接机"含义（from_airport）
#   - 时间匹配：接机时间必须与航班到达时间接近
#   - 地点动态：上车点需要通过航班搜索确定（不能写死），下车点需要明确到酒店地址
#   ❌ 不能一次性提供：需要先搜索CA1831航班→确定机场和到达时间→查找酒店→预订酒店→预订接机服务
#
# 评分标准（总分100分）：
#   1. 创建了酒店订单(20分)
#   2. 创建了接送服务订单(20分)
#   3. 酒店为商务型（CBD/星级≥4星/价格≥500元）(15分)
#   4. 服务类型正确（airport_pickup + from_airport）(10分)
#   5. 上车点正确（浦东机场，通过CA1831航班搜索确定）(10分)
#   6. 下车点明确（酒店地址，非空且合理）(10分)
#   7. 乘客和入住人信息正确（李四）(5分)
#   8. 接机时间与CA1831航班到达时间匹配（明天上午10点左右）(10分)
module V151V200
  class V199BookCbdBusinessHotelAndAirportShuttleValidator < BaseValidator
    self.validator_id = 'v199_book_cbd_business_hotel_and_airport_shuttle_validator'
    self.task_id = '1b8f7359-8e4c-4e2f-a7c8-ff25c53c02a3'
    self.title = '给李四预订明天上海CBD商务酒店+机场接送服务（北京→上海CA1831航班，浦东机场T1→CBD商圈酒店，明天上午10点）'
    self.description = '帮李四订明天上海CBD的商务酒店+机场接送服务（CA1831航班，浦东T1→CBD商圈酒店，明天上午10点）'
    self.timeout_seconds = 300
    
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @city = '上海'
      @check_in_date = Date.current + 1.day  # 明天
      @service_type = 'from_airport'  # 机场接机服务
      @transfer_type = 'airport_pickup'
      
      # 航班信息
      @departure_city = '北京'  # 航班出发城市
      @arrival_city = '上海'  # 航班到达城市
      @flight_number = 'CA1831'  # 航班号（明确告诉用户应该选哪趟航班）
      @flight_date = @check_in_date.strftime('%Y-%m-%d')  # 明天
      @arrival_airport = '浦东T1'  # 到达机场（通过航班搜索确定）
      @arrival_time = '10:00'  # 到达时间
      @pickup_datetime = Date.current + 1.day + 10.hours  # 明天上午10点
      
      @location_from = '浦东T1接机处'  # 上车点（通过航班搜索确定）
      @dropoff_location = 'CBD商圈酒店'  # 下车点（CBD商务区酒店）
      @location_to = @dropoff_location  # 下车点 = 目的地
      
      # 查找商务型酒店（高星级或高价格）
      @available_hotels = Hotel
        .where(city: @city, data_version: 0)
        .select { |h| is_business_hotel?(h) }
        .to_a
      
      # 如果没有明确的商务型酒店，则按价格降序选择（价格高的认为是商务型）
      if @available_hotels.empty?
        @available_hotels = Hotel.where(city: @city, data_version: 0).order(price: :desc).to_a
      end
      
      expect(@available_hotels).not_to be_empty,
        "数据包缺少#{@city}的商务型酒店"
      
      {
        task: "请为#{@passenger.name}预订#{@check_in_date.strftime('%m月%d日')}#{@city}CBD的商务酒店，并预订机场接机服务（从机场送到酒店）",
        scenario: "#{@passenger.name}明天从#{@departure_city}坐飞机到#{@arrival_city}（#{@flight_number}航班，明天上午10:00到达浦东T1），需要在机场接机送到CBD酒店",
        flight_info: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          flight_number: @flight_number,
          arrival_airport: @arrival_airport,
          arrival_time: @arrival_time
        },
        city: @city,
        check_in_date: @check_in_date.strftime('%Y-%m-%d'),
        service_type: "机场接机（from_airport）",
        pickup_location: "#{@location_from}（上车点，通过#{@flight_number}航班搜索确定）",
        dropoff_location: "#{@dropoff_location}（下车点，目的地酒店）",
        pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
        flow_hint: "1. 搜索#{@flight_number}航班（#{@departure_city}→#{@arrival_city}，明天上午10:00到达浦东T1） → 2. 确认到达机场（浦东T1）和到达时间（10:00） → 3. 查找CBD商务酒店（≥4星或≥500元） → 4. 预订酒店 → 5. 选择接机服务 → 6. 上车点=浦东T1 → 7. 下车点=酒店地址 → 8. 接机时间=明天上午10点",
        hint: "搜索#{@flight_number}航班确定到达浦东T1上午10点，选择CBD高星级或高价格酒店（≥4星或≥500元），预订接机服务"
      }
    end
    
    def verify
      # 断言1: 创建了酒店订单 (20%)
      add_assertion "创建了酒店订单", weight: 20 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到酒店订单（#{@city}）"
        @hotel_booking = all_bookings.first
      end
      
      # 断言2: 创建了接送服务订单 (20%)
      add_assertion "创建了接送服务订单", weight: 20 do
        all_transfers = Transfer
          .where(data_version: @data_version)
          .where(transfer_type: @transfer_type)
          .where(service_type: @service_type)
          .order(created_at: :desc)
          .to_a
        
        expect(all_transfers).not_to be_empty, "未找到机场接机订单记录"
        @transfer = all_transfers.first
      end
      
      return if @hotel_booking.nil? || @transfer.nil?
      
      # 断言3: 酒店为商务型（CBD/星级≥4星/价格≥500元） (15%)
      add_assertion "酒店为商务型（CBD/星级≥4星/价格≥500元）", weight: 15 do
        hotel = @hotel_booking.hotel
        is_business = is_business_hotel?(hotel)
        
        expect(is_business).to be(true),
          "酒店不是商务型。酒店: #{hotel.name}（星级: #{hotel.star_level}, 价格: #{hotel.price}元，" \
          "类型: #{hotel.hotel_type}，区域: #{hotel.region}）。期望：星级≥4星 或 价格≥500元 或 包含CBD/商务关键词"
      end
      
      # 断言4: 服务类型正确（airport_pickup + from_airport） (10%)
      add_assertion "服务类型正确（airport_pickup + from_airport）", weight: 10 do
        expect(@transfer.transfer_type).to eq(@transfer_type),
          "服务类型错误。期望: #{@transfer_type}（机场接送），实际: #{@transfer.transfer_type}"
        expect(@transfer.service_type).to eq(@service_type),
          "具体服务类型错误。期望: #{@service_type}（从机场接），实际: #{@transfer.service_type}"
      end
      
      # 断言5: 上车点正确（浦东机场，通过CA1831航班搜索确定） (10%)
      add_assertion "上车点正确（浦东机场，通过#{@flight_number}航班搜索确定）", weight: 10 do
        location_from = @transfer.location_from.to_s
        
        # 验证上车点包含"浦东"关键词（通过CA1831航班搜索确定到达浦东机场）
        expect(location_from).to include('浦东'),
          "上车点错误（缺少浦东）。期望包含: 浦东机场T1接机处（通过#{@flight_number}航班搜索确定），实际: #{location_from}"
      end
      
      # 断言6: 下车点明确（酒店地址，非空且合理） (10%)
      add_assertion "下车点明确（酒店地址，非空且合理）", weight: 10 do
        location_to = @transfer.location_to.to_s
        
        # 验证下车点不为空
        expect(location_to).not_to be_empty,
          "下车点为空。应填写酒店地址或CBD商圈"
        
        # 验证下车点长度合理（至少4个字符，避免只填"酒店"等过于简单的内容）
        expect(location_to.length).to be >= 4,
          "下车点过于简单。实际: #{location_to}，期望：酒店具体地址或CBD商圈名称"
      end
      
      # 断言7: 乘客和入住人信息正确（李四） (5%)
      add_assertion "乘客和入住人信息正确（#{@expected_passenger_name}）", weight: 5 do
        # 检查接送服务乘客信息
        expect(@transfer.passenger_phone).to eq(@expected_phone),
          "接送服务联系人电话错误。期望: #{@expected_phone}（#{@expected_passenger_name}）, 实际: #{@transfer.passenger_phone}"
        
        # 检查酒店入住人信息
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店入住人电话错误。期望: #{@expected_phone}（#{@expected_passenger_name}）, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言8: 接机时间与CA1831航班到达时间匹配（明天上午10点左右） (10%)
      add_assertion "接机时间与#{@flight_number}航班到达时间匹配（明天上午10点左右）", weight: 10 do
        actual_datetime = @transfer.pickup_datetime
        expect(actual_datetime).not_to be_nil, "未设置接机时间"
        
        # 验证日期是明天
        expect(actual_datetime.to_date).to eq(@pickup_datetime.to_date),
          "接机日期错误。期望: #{@pickup_datetime.to_date}（明天）, 实际: #{actual_datetime.to_date}"
        
        # 验证时间是上午10点左右（允许误差，比如8:00-12:00之间）
        actual_hour = actual_datetime.hour
        expect(actual_hour).to be_between(8, 12).inclusive,
          "接机时间错误。期望: 明天上午10:00左右（#{@flight_number}航班到达时间），实际: #{actual_datetime.strftime('%Y-%m-%d %H:%M')}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      
      # 创建酒店订单（选择价格较高的酒店，表示商务型）
      hotel = @available_hotels.first
      # CRITICAL: 必须过滤room_category='overnight'，排除钟点房
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_in_date + 2.days,
        guest_name: user.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price * 2,
        data_version: @data_version
      )
      
      # 创建机场接送订单
      Transfer.create!(
        user: user,
        transfer_type: @transfer_type,
        service_type: @service_type,
        location_from: @location_from,  # 浦东T1接机处（通过CA1831航班搜索确定）
        location_to: @location_to,  # 酒店地址
        pickup_datetime: @pickup_datetime,  # 明天上午10点（与CA1831航班到达时间匹配）
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        vehicle_type: '舒适型',
        provider_name: '快车服务',
        total_price: 120.0,
        passenger_count: 1,
        luggage_count: 1,
        driver_status: 'pending',
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def is_business_hotel?(hotel)
      # 1. 检查星级（≥4星）
      return true if hotel.star_level.to_i >= 4
      
      # 2. 检查价格（≥500元）
      return true if hotel.price.to_f >= 500
      
      # 3. 检查酒店类型和名称包含商务关键词
      return true if hotel.hotel_type&.include?('商务')
      return true if hotel.hotel_type&.include?('CBD')
      return true if hotel.name&.include?('商务')
      return true if hotel.name&.include?('CBD')
      
      # 4. 检查区域包含商务区关键词
      return true if hotel.region&.include?('CBD')
      return true if hotel.region&.include?('商圈')
      return true if hotel.region&.include?('金融区')
      return true if hotel.region&.include?('商务区')
      return true if hotel.region&.include?('陆家嘴')
      
      # 5. 检查特征标签
      return true if hotel.features&.include?('商务')
      
      false
    end
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date&.to_s,
        service_type: @service_type,
        transfer_type: @transfer_type,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_number: @flight_number,
        arrival_airport: @arrival_airport,
        dropoff_location: @dropoff_location,
        flight_date: @flight_date,
        location_from: @location_from,
        location_to: @location_to,
        pickup_datetime: @pickup_datetime.to_s
      }
    end
    
    def restore_from_state(data)
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @service_type = data['service_type']
      @transfer_type = data['transfer_type']
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_number = data['flight_number']
      @arrival_airport = data['arrival_airport']
      @dropoff_location = data['dropoff_location']
      @flight_date = data['flight_date']
      @location_from = data['location_from']
      @location_to = data['location_to']
      @pickup_datetime = DateTime.parse(data['pickup_datetime']) if data['pickup_datetime']
    end
  end
end
