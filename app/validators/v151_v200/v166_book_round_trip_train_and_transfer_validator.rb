# frozen_string_literal: true

require_relative '../base_validator'

# V166: 预订往返火车+往返火车站接送
# 验证用户能够完成往返火车预订+往返火车站接送服务的组合下单

module V151V200
  class V166BookRoundTripTrainAndTransferValidator < BaseValidator
    self.validator_id = 'v166_book_round_trip_train_and_transfer_validator'
    self.task_id = 'd6e7f8a9-0b1c-2d3e-4f5a-6b7c8d9e0f1a'
    self.title = '预订往返火车并预订往返火车站接送（上海⇄杭州）'
    self.description = '预订明天上海到杭州的往返火车，并预订两次火车站接送服务（去程接站+返程送站）'
    self.timeout_seconds = 300

    def prepare
      @departure_city = '上海'
      @arrival_city = '杭州'
      @outbound_date = Date.tomorrow
      @return_date = @outbound_date + 2.days
      @arrival_station = '杭州东站'
      @departure_station = '上海虹桥站'
      
      # 查找去程火车
      @available_outbound_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .by_date(@outbound_date)
        .order(price_second_class: :asc)
        .to_a
      
      expect(@available_outbound_trains).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}的火车"
      
      # 查找返程火车
      @available_return_trains = Train
        .where(departure_city: @arrival_city, arrival_city: @departure_city, data_version: 0)
        .by_date(@return_date)
        .order(price_second_class: :asc)
        .to_a
      
      expect(@available_return_trains).not_to be_empty, "数据包缺少#{@arrival_city}→#{@departure_city}的返程火车"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(phone: '13800138000', data_version: 0)
      
      # 创建去程火车订单
      outbound_train = @available_outbound_trains.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: outbound_train.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        total_price: outbound_train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建返程火车订单
      return_train = @available_return_trains.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: return_train.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        seat_type: 'second_class',
        total_price: return_train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建去程火车站接站服务
      arrival_time = outbound_train.arrival_time.in_time_zone
      pickup_datetime = @outbound_date.in_time_zone + arrival_time.hour.hours + arrival_time.min.minutes + 15.minutes
      
      Transfer.create!(
        user: user,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @arrival_station,
        location_to: "#{@arrival_city}市区",
        pickup_datetime: pickup_datetime,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 100.0,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建返程火车站送站服务
      departure_time = return_train.departure_time.in_time_zone
      dropoff_datetime = @return_date.in_time_zone + departure_time.hour.hours + departure_time.min.minutes - 1.hour
      
      Transfer.create!(
        user: user,
        transfer_type: 'train_dropoff',
        service_type: 'to_station',
        location_from: "#{@arrival_city}市区",
        location_to: @arrival_station,
        pickup_datetime: dropoff_datetime,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 100.0,
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
        arrival_station: @arrival_station,
        departure_station: @departure_station
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @outbound_date = Date.parse(data['outbound_date']) if data['outbound_date']
      @return_date = Date.parse(data['return_date']) if data['return_date']
      @arrival_station = data['arrival_station']
      @departure_station = data['departure_station']
    end

    def verify
      # 断言1: 创建了去程火车订单
      add_assertion "创建了去程火车订单", weight: 20 do
        @outbound_ticket = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@outbound_ticket).not_to be_nil, "未找到去程火车订单"
      end
      
      return if @outbound_ticket.nil?
      
      # 断言2: 创建了返程火车订单
      add_assertion "创建了返程火车订单", weight: 20 do
        @return_ticket = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @arrival_city, arrival_city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@return_ticket).not_to be_nil, "未找到返程火车订单"
      end
      
      # 断言3: 创建了往返火车站接送服务
      add_assertion "创建了往返火车站接送服务（接站+送站）", weight: 40 do
        @transfers = Transfer
          .where(transfer_type: ['train_pickup', 'train_dropoff'], data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(@transfers.size).to be >= 2, "未找到往返接送服务，期望至少2个，实际找到#{@transfers.size}个"
        
        @pickup_transfer = @transfers.find { |t| t.transfer_type == 'train_pickup' }
        @dropoff_transfer = @transfers.find { |t| t.transfer_type == 'train_dropoff' }
        
        expect(@pickup_transfer).not_to be_nil, "未找到火车站接站服务"
        expect(@dropoff_transfer).not_to be_nil, "未找到火车站送站服务"
      end
      
      return if @pickup_transfer.nil? || @dropoff_transfer.nil?
      
      # 断言4: 接送地点都在杭州
      add_assertion "接送地点都在杭州", weight: 20 do
        pickup_in_city = @pickup_transfer.location_from.include?(@arrival_city) || @pickup_transfer.location_to.include?(@arrival_city)
        dropoff_in_city = @dropoff_transfer.location_from.include?(@arrival_city) || @dropoff_transfer.location_to.include?(@arrival_city)
        
        expect(pickup_in_city).to be(true), "接站地点错误，期望包含: #{@arrival_city}"
        expect(dropoff_in_city).to be(true), "送站地点错误，期望包含: #{@arrival_city}"
      end
    end
  end
end
