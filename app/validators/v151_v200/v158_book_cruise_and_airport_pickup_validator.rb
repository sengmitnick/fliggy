# frozen_string_literal: true

require_relative '../base_validator'

# V158: 预订上海邮轮 + 机场接机服务
# 验证用户能够完成邮轮预订+机场接机服务的组合下单

module V151V200
  class V158BookCruiseAndAirportPickupValidator < BaseValidator
    self.validator_id = 'v158_book_cruise_and_airport_pickup_validator'
    self.task_id = 'b8c9d0e1-2f3a-4b5c-6d7e-8f9a0b1c2d3e'
    self.title = '给张三预订明天上海出发日本邮轮6天5晚，并预订机场接机（接今天从北京飞来的航班）'
    self.description = '预订明天上海出发的日本邮轮航线，并预订机场接机服务（接今天从北京飞到上海浦东的航班）'
    self.timeout_seconds = 300

    def prepare
      @departure_date = Date.current + 1.day  # 明天邮轮出发
      @flight_date = Date.current  # 今天航班到达
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
      
      raise "数据包缺少上海出发的邮轮班次" if @available_sailings.empty?
      
      # 查找今天从北京飞到上海浦东的航班（接机）
      @pickup_flights = Flight
        .where(departure_city: @flight_origin, destination_city: @departure_port, data_version: 0)
        .where(flight_date: @flight_date)
        .where("arrival_airport LIKE ?", "%浦东%")
        .to_a
      
      raise "数据包缺少#{@flight_origin}到#{@departure_port}浦东的航班" if @pickup_flights.empty?
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
        pickup_datetime: pickup_datetime,
        flight_number: pickup_flight.flight_number,
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
        flight_date: @flight_date.to_s,
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
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @departure_port = data['departure_port']
      @airport_location = data['airport_location']
      @flight_origin = data['flight_origin']
      @duration_days = data['duration_days']
      @duration_nights = data['duration_nights']
      @adult_count = data['adult_count']
    end

    def verify
      # 断言1: 创建了邮轮订单
      add_assertion "创建了邮轮订单", weight: 25 do
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
      add_assertion "行程天数正确（#{@duration_days}天#{@duration_nights}晚）", weight: 15 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
      end
      
      # 断言4: 成人数量=2
      add_assertion "成人数量=2", weight: 10 do
        expect(@cruise_order.quantity).to eq(@adult_count),
          "成人数量错误。期望: #{@adult_count}, 实际: #{@cruise_order.quantity}"
      end
      
      # 断言5: 创建了机场接机服务
      add_assertion "创建了机场接机服务", weight: 10 do
        @transfer = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场接机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言6: 接机服务关联了具体航班号
      add_assertion "接机服务关联了具体航班号（#{@flight_origin}→#{@departure_port}）", weight: 15 do
        expect(@transfer.flight_number).not_to be_nil,
          "接机服务未关联航班号"
        
        flight = Flight.find_by(
          flight_number: @transfer.flight_number,
          departure_city: @flight_origin,
          destination_city: @departure_port,
          data_version: 0
        )
        
        expect(flight).not_to be_nil,
          "未找到关联的航班: #{@transfer.flight_number}"
        expect(flight.arrival_airport).to include('浦东'),
          "航班到达机场错误。期望: 浦东, 实际: #{flight.arrival_airport}"
      end
      
      # 断言7: 接机时间合理（航班到达后20-40分钟）
      add_assertion "接机时间合理（航班到达后20-40分钟）", weight: 5 do
        flight = Flight
          .where(flight_number: @transfer.flight_number, data_version: 0)
          .where(departure_city: @flight_origin, destination_city: @departure_port)
          .where(flight_date: @flight_date)
          .first
        
        expect(flight).not_to be_nil, "未找到关联的航班"
        
        time_after_arrival = ((@transfer.pickup_datetime - flight.arrival_time) / 60.0).round
        expect(time_after_arrival >= 20 && time_after_arrival <= 40).to be(true),
          "接机时间不合理。航班到达: #{flight.arrival_time.strftime('%H:%M')}, 接机时间: #{@transfer.pickup_datetime.strftime('%H:%M')}, 间隔: #{time_after_arrival}分钟（期望20-40分钟）"
      end
      
      # 断言8: 联系人信息正确（张三）
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 5 do
        expect(@cruise_order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@cruise_order.contact_name}"
        expect(@cruise_order.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@cruise_order.contact_phone}"
      end
    end
  end
end
