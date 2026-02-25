# frozen_string_literal: true

require_relative '../base_validator'

# V161: 预订上海邮轮 + 机场往返接送服务
# 验证用户能够完成邮轮预订+机场往返接送服务的组合下单

module V151V200
  class V161BookCruiseWithAirportTransferValidator < BaseValidator
    self.validator_id = 'v161_book_cruise_with_airport_transfer_validator'
    self.task_id = 'e1f2a3b4-5c6d-7e8f-9a0b-1c2d3e4f5a6b'
    self.title = '给张三订明天上海出发的日本邮轮6天5晚，并订机场往返接送服务（接今天从北京飞上海浦东的航班，送第7天从上海浦东飞北京的航班）'
    self.description = '给张三订明天上海出发的日本邮轮6天5晚，并订机场往返接送服务（接今天从北京飞上海浦东的航班，送第7天从上海浦东飞北京的航班）'
    self.timeout_seconds = 300

    def prepare
      @departure_date = Date.current + 1.day  # 明天邮轮出发
      @pickup_flight_date = Date.current  # 今天航班到达
      @dropoff_flight_date = Date.current + 7.days  # 第7天航班离开
      @departure_port = '上海'
      @airport_location = '上海浦东国际机场'
      @flight_origin = '北京'
      @duration_days = 6
      @duration_nights = 5
      @adult_count = 2
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的上海邮轮班次
      @available_sailings = CruiseSailing
        .where("departure_port LIKE ?", "%#{@departure_port}%")
        .where(duration_days: @duration_days, duration_nights: @duration_nights, data_version: 0)
        .where("departure_date >= ?", @departure_date)
        .to_a
      
      expect(@available_sailings).not_to be_empty, "数据包缺少上海出发的邮轮班次"
      
      # 查找今天从北京飞上海浦东的航班（接机）
      @pickup_flights = Flight
        .where(departure_city: @flight_origin, destination_city: @departure_port, data_version: 0)
        .where(flight_date: @pickup_flight_date)
        .where("arrival_airport LIKE ?", "%浦东%")
        .to_a
      
      expect(@pickup_flights).not_to be_empty, "数据包缺少#{@flight_origin}到#{@departure_port}的航班"
      
      # 查找第7天从上海浦东飞北京的航班（送机）
      @dropoff_flights = Flight
        .where(departure_city: @departure_port, destination_city: @flight_origin, data_version: 0)
        .where(flight_date: @dropoff_flight_date)
        .where("departure_airport LIKE ?", "%浦东%")
        .to_a
      
      expect(@dropoff_flights).not_to be_empty, "数据包缺少#{@departure_port}到#{@flight_origin}的航班"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      sailing = @available_sailings.first
      ship = sailing.cruise_ship
      
      # 查找舱房类型（选择经济舱）
      cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: 'interior').first
      raise "未找到舱房类型" unless cabin_type
      
      # 查找或创建邮轮产品
      cruise_product = CruiseProduct.find_or_create_by!(
        cruise_sailing_id: sailing.id,
        cabin_type_id: cabin_type.id,
        data_version: 0
      ) do |product|
        product.merchant_name = '邮轮旅游网'
        product.price_per_person = 3500.0
        product.occupancy_requirement = 2
        product.stock = 10
        product.sales_count = 0
        product.is_refundable = true
        product.requires_confirmation = false
        product.status = 'on_sale'
      end
      
      total_price = cruise_product.price_per_person * @adult_count
      
      # 创建邮轮订单
      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: cruise_product.id,
        quantity: @adult_count,
        contact_name: @passenger.name,
        contact_phone: @passenger.phone,
        total_price: total_price,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建机场接机服务（今天航班到达）
      # 选择今天最早到达浦东的航班
      pickup_flight = @pickup_flights.min_by { |f| f.arrival_time }
      pickup_datetime = pickup_flight.arrival_time + 30.minutes
      
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_location,
        location_to: "#{@departure_port}邮轮码头",
        flight_number: pickup_flight.flight_number,
        pickup_datetime: pickup_datetime,
        vehicle_type: 'business_5',
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        total_price: 150.0,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建机场送机服务（第7天航班离开）
      # 选择第7天最早起飞的航班
      dropoff_flight = @dropoff_flights.min_by { |f| f.departure_time }
      dropoff_datetime = dropoff_flight.departure_time - 2.hours
      
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "#{@departure_port}邮轮码头",
        location_to: @airport_location,
        flight_number: dropoff_flight.flight_number,
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
        departure_date: @departure_date.to_s,
        pickup_flight_date: @pickup_flight_date.to_s,
        dropoff_flight_date: @dropoff_flight_date.to_s,
        departure_port: @departure_port,
        airport_location: @airport_location,
        flight_origin: @flight_origin,
        duration_days: @duration_days,
        duration_nights: @duration_nights,
        adult_count: @adult_count
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @pickup_flight_date = Date.parse(data['pickup_flight_date']) if data['pickup_flight_date']
      @dropoff_flight_date = Date.parse(data['dropoff_flight_date']) if data['dropoff_flight_date']
      @departure_port = data['departure_port']
      @airport_location = data['airport_location']
      @flight_origin = data['flight_origin']
      @duration_days = data['duration_days']
      @duration_nights = data['duration_nights']
      @adult_count = data['adult_count']
    end

    def verify
      # 断言1: 创建了邮轮订单
      add_assertion "创建了邮轮订单", weight: 15 do
        @cruise_order = CruiseOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@cruise_order).not_to be_nil, "未找到任何邮轮订单"
      end
      
      return if @cruise_order.nil?
      
      # 断言2: 出发港正确
      add_assertion "出发港正确（#{@departure_port}）", weight: 15 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.departure_port).to include(@departure_port),
          "出发港错误。期望包含: #{@departure_port}, 实际: #{sailing.departure_port}"
      end
      
      # 断言3: 行程天数正确
      add_assertion "行程天数正确（#{@duration_days}天#{@duration_nights}晚）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
      end
      
      # 断言4: 创建了机场往返接送服务
      add_assertion "创建了机场往返接送服务（接机+送机）", weight: 10 do
        @transfers = Transfer
          .where(transfer_type: ['airport_pickup', 'airport_dropoff'], data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(@transfers.size).to be >= 2, "未找到往返接送服务订单，期望至少2个（接机+送机），实际找到#{@transfers.size}个"
        
        @pickup_transfer = @transfers.find { |t| t.transfer_type == 'airport_pickup' }
        @dropoff_transfer = @transfers.find { |t| t.transfer_type == 'airport_dropoff' }
        
        expect(@pickup_transfer).not_to be_nil, "未找到机场接机服务"
        expect(@dropoff_transfer).not_to be_nil, "未找到机场送机服务"
      end
      
      return if @pickup_transfer.nil? || @dropoff_transfer.nil?
      
      # 断言5: 接机服务关联了具体航班号
      add_assertion "接机服务关联了具体航班号（#{@flight_origin}→#{@departure_port}）", weight: 15 do
        expect(@pickup_transfer.flight_number).not_to be_nil,
          "接机服务未关联航班号"
        
        flight = Flight.find_by(
          flight_number: @pickup_transfer.flight_number,
          flight_date: @pickup_flight_date,
          data_version: 0
        )
        expect(flight).not_to be_nil,
          "未找到航班号 #{@pickup_transfer.flight_number}"
        expect(flight.arrival_airport).to include('浦东'),
          "航班到达机场错误。期望包含: 浦东, 实际: #{flight.arrival_airport}"
      end
      
      # 断言6: 接机时间合理（航班到达后20-40分钟）
      add_assertion "接机时间合理（航班到达后20-40分钟）", weight: 3 do
        flight = Flight.where(flight_number: @pickup_transfer.flight_number, data_version: 0)
                       .where(flight_date: @pickup_flight_date)
                       .first
        expect(flight).not_to be_nil, "未找到对应航班"
        
        time_after_arrival = ((@pickup_transfer.pickup_datetime - flight.arrival_time) / 60.0).round
        expect(time_after_arrival >= 20 && time_after_arrival <= 40).to be(true),
          "接机时间不合理。航班到达时间: #{flight.arrival_time}, 接机时间: #{@pickup_transfer.pickup_datetime}, 间隔: #{time_after_arrival}分钟（期望20-40分钟）"
      end
      
      # 断言7: 送机服务关联了具体航班号
      add_assertion "送机服务关联了具体航班号（#{@departure_port}→#{@flight_origin}）", weight: 15 do
        expect(@dropoff_transfer.flight_number).not_to be_nil,
          "送机服务未关联航班号"
        
        flight = Flight.find_by(
          flight_number: @dropoff_transfer.flight_number,
          flight_date: @dropoff_flight_date,
          data_version: 0
        )
        expect(flight).not_to be_nil,
          "未找到航班号 #{@dropoff_transfer.flight_number}"
        expect(flight.departure_airport).to include('浦东'),
          "航班起飞机场错误。期望包含: 浦东, 实际: #{flight.departure_airport}"
      end
      
      # 断言8: 送机时间合理（航班起飞前1.5-2.5小时）
      add_assertion "送机时间合理（航班起飞前1.5-2.5小时）", weight: 7 do
        flight = Flight.where(flight_number: @dropoff_transfer.flight_number, data_version: 0)
                       .where(flight_date: @dropoff_flight_date)
                       .first
        expect(flight).not_to be_nil, "未找到对应航班"
        
        time_before_departure = ((flight.departure_time - @dropoff_transfer.pickup_datetime) / 3600.0).round(1)
        expect(time_before_departure >= 1.5 && time_before_departure <= 2.5).to be(true),
          "送机时间不合理。航班起飞时间: #{flight.departure_time}, 送机时间: #{@dropoff_transfer.pickup_datetime}, 提前: #{time_before_departure}小时（期望1.5-2.5小时）"
      end
      
      # 断言9: 接送地点都在上海
      add_assertion "接送地点都在上海", weight: 5 do
        pickup_in_city = @pickup_transfer.location_from.include?(@departure_port) || @pickup_transfer.location_to.include?(@departure_port)
        dropoff_in_city = @dropoff_transfer.location_from.include?(@departure_port) || @dropoff_transfer.location_to.include?(@departure_port)
        
        expect(pickup_in_city).to be(true), "接机地点错误，期望包含: #{@departure_port}"
        expect(dropoff_in_city).to be(true), "送机地点错误，期望包含: #{@departure_port}"
      end
      
      # 断言10: 联系人信息正确（张三）
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 5 do
        expect(@cruise_order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@cruise_order.contact_name}"
        expect(@cruise_order.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@cruise_order.contact_phone}"
      end
    end
  end
end
