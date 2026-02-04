# frozen_string_literal: true

require_relative '../base_validator'

# V165: 预订往返航班+往返机场接送
# 验证用户能够完成往返航班预订+往返机场接送服务的组合下单

module V151V200
  class V165BookRoundTripFlightAndTransferValidator < BaseValidator
    self.validator_id = 'v165_book_round_trip_flight_and_transfer_validator'
    self.task_id = 'c5d6e7f8-9a0b-1c2d-3e4f-5a6b7c8d9e0f'
    self.title = '预订往返航班并预订往返机场接送（北京⇄上海）'
    self.description = '预订明天北京到上海的往返航班，并预订两次机场接送服务（去程接机+返程送机）'
    self.timeout_seconds = 300

    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @outbound_date = Date.tomorrow
      @return_date = @outbound_date + 3.days
      @airport_location = '上海浦东国际机场'
      
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
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
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
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: return_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建去程机场接机服务
      arrival_time = outbound_flight.arrival_time.in_time_zone
      pickup_datetime = @outbound_date.in_time_zone + arrival_time.hour.hours + arrival_time.min.minutes + 30.minutes
      
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_location,
        location_to: "#{@arrival_city}市区",
        pickup_datetime: pickup_datetime,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 150.0,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建返程机场送机服务
      departure_time = return_flight.departure_time.in_time_zone
      dropoff_datetime = @return_date.in_time_zone + departure_time.hour.hours + departure_time.min.minutes - 2.hours
      
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "#{@arrival_city}市区",
        location_to: @airport_location,
        pickup_datetime: dropoff_datetime,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
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
        airport_location: @airport_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @outbound_date = Date.parse(data['outbound_date']) if data['outbound_date']
      @return_date = Date.parse(data['return_date']) if data['return_date']
      @airport_location = data['airport_location']
    end

    def verify
      # 断言1: 创建了去程航班订单
      add_assertion "创建了去程航班订单", weight: 20 do
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
      add_assertion "创建了返程航班订单", weight: 20 do
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
      add_assertion "创建了往返机场接送服务（接机+送机）", weight: 40 do
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
      add_assertion "接送地点都在上海", weight: 20 do
        pickup_in_city = @pickup_transfer.location_from.include?(@arrival_city) || @pickup_transfer.location_to.include?(@arrival_city)
        dropoff_in_city = @dropoff_transfer.location_from.include?(@arrival_city) || @dropoff_transfer.location_to.include?(@arrival_city)
        
        expect(pickup_in_city).to be(true), "接机地点错误，期望包含: #{@arrival_city}"
        expect(dropoff_in_city).to be(true), "送机地点错误，期望包含: #{@arrival_city}"
      end
    end
  end
end
