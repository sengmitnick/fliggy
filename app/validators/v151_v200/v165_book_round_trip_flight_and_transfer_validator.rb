# frozen_string_literal: true

require_relative '../base_validator'

# V165BookRoundTripFlightAndTransferValidator
# 验证用例165: 给张三预订明天北京到上海的往返航班（去程明天，返程第4天），并预订两次机场接送服务（去程接机：从到达机场→人民广场接送服务站，返程送机：从人民广场接送服务站→出发机场）
#
# 任务描述:
#   张三计划预订北京到上海的往返航班和机场接送服务：明天出发去上海，第4天返回北京，两次均需要机场接送服务。
#   1. 去程航班（明天北京→上海）
#   2. 返程航班（第4天上海→北京）
#   3. 去程接机服务（去程航班到达后接机，从到达机场→人民广场接送服务站）
#   4. 返程送机服务（返程航班起飞前2小时从人民广场接送服务站→出发机场）
#
# 任务分解步骤:
#   1. 查询去程航班（明天北京→上海）
#   2. 查询返程航班（第4天上海→北京）
#   3. 创建去程航班订单（乘客=张三，联系人=张三）
#   4. 创建返程航班订单（乘客=张三，联系人=张三）
#   5. 创建去程接机服务（从到达机场→人民广场接送服务站，基于实际预订的去程航班到达时间安排接机，关联航班号以便追踪航班动态，联系人=张三）
#   6. 创建返程送机服务（从人民广场接送服务站→出发机场，基于实际预订的返程航班起飞时间安排送机，不需要关联航班号，联系人=张三）
#
# 评分标准（总分100分）:
#   1. 创建了去程航班订单 (15分)
#   2. 创建了返程航班订单 (15分)
#   3. 创建了往返机场接送服务（接机+送机） (16分)
#   4. 接送机场与预订航班的机场一致 (10分)
#   5. 接机时间合理（航班到达后20-40分钟）且航班号正确 (18分)
#   6. 送机时间合理（航班起飞前1.5-2.5小时） (18分)
#   7. 乘客信息正确（张三） (4分)
#   8. 接送机联系人信息正确（张三） (4分)

module V151V200
  class V165BookRoundTripFlightAndTransferValidator < BaseValidator
    self.validator_id = 'v165_book_round_trip_flight_and_transfer_validator'
    self.task_id = 'c5d6e7f8-9a0b-1c2d-3e4f-5a6b7c8d9e1f'
    self.title = '给张三预订明天北京到上海的往返航班（去程明天，返程第4天），并预订两次机场接送服务（去程：去程航班到达后接机，返程：返程航班起飞前2小时送机）'
    self.description = '给张三预订明天北京到上海的往返航班和机场接送服务：去程航班到达后接机；返程航班起飞前2小时送机'
    self.timeout_seconds = 300

    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @outbound_date = Date.current + 1.day  # 明天
      @return_date = Date.current + 3.days  # 第4天返回（今天 + 3天 = 第4天）
      @city_location = '人民广场接送服务站'  # 市区接送点
      
      # 查找去程航班
      @available_outbound_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @outbound_date, data_version: 0)
        .order(price: :asc)
        .to_a
      
      expect(@available_outbound_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}的航班（明天#{@outbound_date}）"
      
      # 查找返程航班
      @available_return_flights = Flight
        .where(departure_city: @arrival_city, destination_city: @departure_city, flight_date: @return_date, data_version: 0)
        .order(price: :asc)
        .to_a
      
      expect(@available_return_flights).not_to be_empty, "数据包缺少#{@arrival_city}→#{@departure_city}的返程航班（第4天#{@return_date}）"
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_name = @passenger.name
      @expected_phone = @passenger.phone
      @expected_id_number = @passenger.id_number
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择去程和返程航班
      outbound_flight = @available_outbound_flights.first
      return_flight = @available_return_flights.first
      
      # 创建往返航班订单（一个订单包含去程和返程）
      # 注：verify方法已兼容两种下单方式：
      #   1. 往返订单（trip_type: 'round_trip', 包含return_flight）
      #   2. 两个独立的单程订单（trip_type: 'one_way'）
      booking = Booking.create!(
        user: user,
        trip_type: 'round_trip',  # 往返类型
        flight: outbound_flight,  # 去程航班
        return_flight: return_flight,  # 返程航班
        return_date: @return_date,  # 返程日期
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        total_price: outbound_flight.price + return_flight.price,  # 总价 = 去程 + 返程
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建去程机场接机服务（基于实际预订的去程航班到达时间）
      actual_pickup_time = outbound_flight.arrival_time + 30.minutes  # 航班到达后30分钟接机
      outbound_airport = outbound_flight.arrival_airport  # 从航班获取到达机场
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: outbound_airport,  # 使用航班实际到达机场
        location_to: @city_location,
        pickup_datetime: actual_pickup_time,  # 基于实际选择的航班动态计算
        flight_number: outbound_flight.flight_number,  # 关联去程航班号
        vehicle_type: 'business_5',
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        total_price: 150.0,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建返程机场送机服务（基于实际预订的返程航班起飞时间）
      actual_dropoff_time = return_flight.departure_time - 2.hours  # 航班起飞前2小时送机
      return_airport = return_flight.departure_airport  # 从航班获取出发机场
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: @city_location,
        location_to: return_airport,  # 使用航班实际出发机场
        pickup_datetime: actual_dropoff_time,  # 基于实际选择的航班动态计算
        # 注：送机服务不需要关联航班号，只需要按时送到机场即可
        vehicle_type: 'business_5',
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        total_price: 150.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        outbound_date: @outbound_date.to_s,
        return_date: @return_date.to_s,
        city_location: @city_location,
        expected_name: @expected_name,
        expected_phone: @expected_phone,
        expected_id_number: @expected_id_number
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @outbound_date = Date.parse(data['outbound_date']) if data['outbound_date']
      @return_date = Date.parse(data['return_date']) if data['return_date']
      @city_location = data['city_location']
      @expected_name = data['expected_name']
      @expected_phone = data['expected_phone']
      @expected_id_number = data['expected_id_number']
    end

    def verify
      # 断言1: 创建了去程航班订单（北京→上海）
      add_assertion "创建了去程航班订单（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        @outbound_booking = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@outbound_booking).not_to be_nil, "未找到去程航班订单"
      end
      
      return if @outbound_booking.nil?
      
      # 断言2: 有返程航班（可以是往返订单的return_flight，或独立的返程订单）
      add_assertion "有返程航班（#{@arrival_city}→#{@departure_city}）", weight: 15 do
        # 尝试方式A：检查是否为往返订单
        if @outbound_booking.trip_type == 'round_trip' && @outbound_booking.return_flight.present?
          @return_flight = @outbound_booking.return_flight
          @is_round_trip_booking = true
        else
          # 方式B：查找独立的返程订单
          @return_booking = Booking
            .joins(:flight)
            .includes(:flight)
            .where(flights: { departure_city: @arrival_city, destination_city: @departure_city })
            .where(data_version: @data_version)
            .where.not(id: @outbound_booking.id)  # 排除去程订单
            .order(created_at: :desc)
            .first
          
          expect(@return_booking).not_to be_nil, "未找到返程航班（既不是往返订单，也没有独立的返程订单）"
          return if @return_booking.nil?  # Guard clause：如果返程订单为nil则提前返回
          
          @return_flight = @return_booking.flight
          @is_round_trip_booking = false
        end
        
        # 验证返程航班的城市信息
        expect(@return_flight.departure_city).to eq(@arrival_city),
          "返程出发城市错误。期望: #{@arrival_city}, 实际: #{@return_flight.departure_city}"
        expect(@return_flight.destination_city).to eq(@departure_city),
          "返程到达城市错误。期望: #{@departure_city}, 实际: #{@return_flight.destination_city}"
      end
      
      return if @return_flight.nil?  # Guard clause：如果未找到返程航班，后续断言无法进行
      
      # 断言3: 创建了往返机场接送服务
      add_assertion "创建了往返机场接送服务（接机+送机）", weight: 16 do
        @transfers = Transfer
          .where(transfer_type: ['airport_pickup', 'airport_dropoff'], data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(@transfers.size).to be >= 2, "未找到往返接送服务，期望至少2个，实际找到#{@transfers.size}个"
        
        @pickup_transfer = @transfers.find { |t| t.transfer_type == 'airport_pickup' }
        @dropoff_transfer = @transfers.find { |t| t.transfer_type == 'airport_dropoff' }
        
        expect(@pickup_transfer).not_to be_nil, "未找到机场接机服务"
        expect(@dropoff_transfer).not_to be_nil, "未找到机场送机服务"
      end
      
      return if @pickup_transfer.nil? || @dropoff_transfer.nil?
      
      # 断言4: 接送机场与预订航班的机场一致
      add_assertion "接送机场与预订航班的机场一致", weight: 10 do
        # 验证接机服务：机场地址与去程航班到达机场一致
        outbound_flight = @outbound_booking.flight
        expected_arrival_airport = outbound_flight.arrival_airport
        
        expect(@pickup_transfer.location_from).to eq(expected_arrival_airport),
          "接机出发地点错误。期望: #{expected_arrival_airport}（去程航班到达机场），实际: #{@pickup_transfer.location_from}"
        
        # 验证送机服务：机场地址与返程航班出发机场一致
        # @return_flight 已在断言2中获取（兼容往返订单或独立订单）
        expected_departure_airport = @return_flight.departure_airport
        
        expect(@dropoff_transfer.location_to).to eq(expected_departure_airport),
          "送机目的地点错误。期望: #{expected_departure_airport}（返程航班出发机场），实际: #{@dropoff_transfer.location_to}"
      end
      
      # 断言5: 接机时间合理（航班到达后20-40分钟）且航班号正确
      add_assertion "接机时间合理（航班到达后20-40分钟）且航班号正确", weight: 18 do
        # 验证接机服务关联了航班号
        expect(@pickup_transfer.flight_number).not_to be_nil, "接机服务未关联航班号"
        return if @pickup_transfer.flight_number.nil?  # Guard clause
        
        # 验证航班号对应去程航班（北京→上海）
        outbound_flight = @outbound_booking.flight
        return if outbound_flight.nil?  # Guard clause
        
        # 直接验证航班号是否匹配已选定的去程航班
        expect(@pickup_transfer.flight_number).to eq(outbound_flight.flight_number),
          "接机服务航班号错误。期望: #{outbound_flight.flight_number}（去程航班），实际: #{@pickup_transfer.flight_number}"
        
        # 验证接机时间在航班到达后20-40分钟
        arrival_time = outbound_flight.arrival_time
        actual_pickup = @pickup_transfer.pickup_datetime
        return if arrival_time.nil? || actual_pickup.nil?  # Guard clause
        
        time_after_arrival = ((actual_pickup - arrival_time) / 60.0).round
        
        expect(time_after_arrival >= 20 && time_after_arrival <= 40).to be(true),
          "接机时间不合理。航班到达: #{arrival_time.strftime('%H:%M')}, 接机时间: #{actual_pickup.strftime('%H:%M')}, 间隔: #{time_after_arrival}分钟（期望20-40分钟）"
      end
      
      # 断言6: 送机时间合理（航班起飞前1.5-2.5小时）
      add_assertion "送机时间合理（航班起飞前1.5-2.5小时）", weight: 18 do
        # 验证送机时间在航班起飞前1.5-2.5小时
        # 注：送机服务不需要验证航班号，只需要确保送达时间合理即可
        return if @return_flight.nil?  # Guard clause
        
        departure_time = @return_flight.departure_time
        actual_dropoff = @dropoff_transfer.pickup_datetime
        return if departure_time.nil? || actual_dropoff.nil?  # Guard clause
        
        time_before_departure = ((departure_time - actual_dropoff) / 3600.0).round(1)  # 转换为小时
        
        expect(time_before_departure >= 1.5 && time_before_departure <= 2.5).to be(true),
          "送机时间不合理。航班起飞: #{departure_time.strftime('%H:%M')}, 送机时间: #{actual_dropoff.strftime('%H:%M')}, 间隔: #{time_before_departure}小时（期望1.5-2.5小时）"
      end
      
      # 断言7: 乘客信息正确（张三）
      add_assertion "乘客信息正确（#{@expected_name}）", weight: 4 do
        expect(@outbound_booking.passenger_name).to eq(@expected_name),
          "乘客姓名错误。期望: #{@expected_name}, 实际: #{@outbound_booking.passenger_name}"
        expect(@outbound_booking.passenger_id_number).to eq(@expected_id_number),
          "乘客身份证号错误。期望: #{@expected_id_number}, 实际: #{@outbound_booking.passenger_id_number}"
      end
      
      # 断言8: 接送机联系人信息正确（#{@expected_name}）
      add_assertion "接送机联系人信息正确（#{@expected_name}）", weight: 4 do
        expect(@pickup_transfer.passenger_name).to eq(@expected_name),
          "接机联系人姓名错误。期望: #{@expected_name}, 实际: #{@pickup_transfer.passenger_name}"
        expect(@pickup_transfer.passenger_phone).to eq(@expected_phone),
          "接机联系人电话错误。期望: #{@expected_phone}, 实际: #{@pickup_transfer.passenger_phone}"
        
        expect(@dropoff_transfer.passenger_name).to eq(@expected_name),
          "送机联系人姓名错误。期望: #{@expected_name}, 实际: #{@dropoff_transfer.passenger_name}"
        expect(@dropoff_transfer.passenger_phone).to eq(@expected_phone),
          "送机联系人电话错误。期望: #{@expected_phone}, 实际: #{@dropoff_transfer.passenger_phone}"
      end
    end
  end
end