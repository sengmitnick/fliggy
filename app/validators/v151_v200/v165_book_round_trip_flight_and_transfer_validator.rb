# frozen_string_literal: true

require_relative '../base_validator'

# V165: 预订往返航班+往返机场接送
# 验证用户能够完成往返航班预订+往返机场接送服务的组合下单

module V151V200
  class V165BookRoundTripFlightAndTransferValidator < BaseValidator
    self.validator_id = 'v165_book_round_trip_flight_and_transfer_validator'
    self.task_id = 'c5d6e7f8-9a0b-1c2d-3e4f-5a6b7c8d9e1f'
    self.title = '给张三预订明天北京⇄上海往返航班 + 往返机场接送服务'
    self.description = '预订明天北京到上海的往返航班，并预订两次机场接送服务（去程接机+返程送机）'
    self.timeout_seconds = 300

    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @outbound_date = Date.current + 1.day  # 明天
      @return_date = @outbound_date + 3.days
      @airport_location = '上海浦东国际机场'
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_name = @passenger.name
      @expected_phone = @passenger.phone
      @expected_id_number = @passenger.id_number
      
      # 查找去程航班
      @available_outbound_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, flight_date: @outbound_date, data_version: 0)
        .order(price: :asc)
        .to_a
      
      expect(@available_outbound_flights).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}的航班"
      
      # 查找返程航班
      @available_return_flights = Flight
        .where(departure_city: @arrival_city, destination_city: @departure_city, flight_date: @return_date, data_version: 0)
        .order(price: :asc)
        .to_a
      
      expect(@available_return_flights).not_to be_empty, "数据包缺少#{@arrival_city}→#{@departure_city}的返程航班"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建去程航班订单
      outbound_flight = @available_outbound_flights.first
      Booking.create!(
        user: user,
        flight: outbound_flight,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        total_price: outbound_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建返程航班订单
      return_flight = @available_return_flights.first
      Booking.create!(
        user: user,
        flight: return_flight,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        total_price: return_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建去程机场接机服务
      arrival_time = outbound_flight.arrival_time
      pickup_datetime = arrival_time + 30.minutes
      
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_location,
        location_to: "#{@arrival_city}市区",
        pickup_datetime: pickup_datetime,
        vehicle_type: 'business_5',
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        total_price: 150.0,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建返程机场送机服务
      departure_time = return_flight.departure_time
      dropoff_datetime = departure_time - 2.hours
      
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "#{@arrival_city}市区",
        location_to: @airport_location,
        pickup_datetime: dropoff_datetime,
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
        airport_location: @airport_location,
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
      @airport_location = data['airport_location']
      @expected_name = data['expected_name']
      @expected_phone = data['expected_phone']
      @expected_id_number = data['expected_id_number']
    end

    def verify
      # 断言1: 创建了去程航班订单
      add_assertion "创建了去程航班订单", weight: 18 do
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
      
      # 断言2: 创建了返程航班订单
      add_assertion "创建了返程航班订单", weight: 18 do
        @return_booking = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @arrival_city, destination_city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@return_booking).not_to be_nil, "未找到返程航班订单"
      end
      
      # 断言3: 创建了往返机场接送服务
      add_assertion "创建了往返机场接送服务（接机+送机）", weight: 20 do
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
      
      # 断言4: 接送地点都在上海
      add_assertion "接送地点都在上海", weight: 8 do
        pickup_in_city = @pickup_transfer.location_from.include?(@arrival_city) || @pickup_transfer.location_to.include?(@arrival_city)
        dropoff_in_city = @dropoff_transfer.location_from.include?(@arrival_city) || @dropoff_transfer.location_to.include?(@arrival_city)
        
        expect(pickup_in_city).to be(true), "接机地点错误，期望包含: #{@arrival_city}"
        expect(dropoff_in_city).to be(true), "送机地点错误，期望包含: #{@arrival_city}"
      end
      
      # 断言5: 接机时间合理（航班到达后20-40分钟）
      add_assertion "接机时间合理（航班到达后20-40分钟）", weight: 12 do
        outbound_flight = @outbound_booking.flight
        time_after_arrival = ((@pickup_transfer.pickup_datetime - outbound_flight.arrival_time) / 60.0).round
        
        expect(time_after_arrival >= 20 && time_after_arrival <= 40).to be(true),
          "接机时间不合理。航班到达: #{outbound_flight.arrival_time.strftime('%H:%M')}, 接机时间: #{@pickup_transfer.pickup_datetime.strftime('%H:%M')}, 间隔: #{time_after_arrival}分钟（期望20-40分钟）"
      end
      
      # 断言6: 送机时间合理（航班起飞前1.5-2.5小时）
      add_assertion "送机时间合理（航班起飞前1.5-2.5小时）", weight: 12 do
        return_flight = @return_booking.flight
        time_before_departure = ((return_flight.departure_time - @dropoff_transfer.pickup_datetime) / 3600.0).round(1)
        
        expect(time_before_departure >= 1.5 && time_before_departure <= 2.5).to be(true),
          "送机时间不合理。航班起飞: #{return_flight.departure_time.strftime('%H:%M')}, 送机时间: #{@dropoff_transfer.pickup_datetime.strftime('%H:%M')}, 提前: #{time_before_departure}小时（期望1.5-2.5小时）"
      end
      
      # 断言7: 乘客信息正确（张三）
      add_assertion "乘客信息正确（#{@expected_name}）", weight: 3 do
        expect(@outbound_booking.passenger_name).to eq(@expected_name),
          "乘客姓名错误。期望: #{@expected_name}, 实际: #{@outbound_booking.passenger_name}"
        expect(@outbound_booking.passenger_id_number).to eq(@expected_id_number),
          "乘客身份证号错误。期望: #{@expected_id_number}, 实际: #{@outbound_booking.passenger_id_number}"
      end
      
      # 断言8: 接送机联系人信息正确（#{@expected_name}）
      add_assertion "接送机联系人信息正确（#{@expected_name}）", weight: 9 do
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
