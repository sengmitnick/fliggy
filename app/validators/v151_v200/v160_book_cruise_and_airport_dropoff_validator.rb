# frozen_string_literal: true

require_relative '../base_validator'

# V160: 预订上海邮轮 + 机场送机服务
# 验证用户能够完成邮轮预订+机场送机服务的组合下单

module V151V200
  class V160BookCruiseAndAirportDropoffValidator < BaseValidator
    self.validator_id = 'v160_book_cruise_and_airport_dropoff_validator'
    self.task_id = 'd0e1f2a3-4b5c-6d7e-8f9a-0b1c2d3e4f5a'
    self.title = '给张三预订明天上海出发日本邮轮6天5晚，并预订机场送机（送第7天从上海飞北京的航班）'
    self.description = '给张三订明天上海出发的日本邮轮6天5晚，并订机场送机服务（送第7天从上海浦东飞北京的航班）'
    self.timeout_seconds = 300

    def prepare
      @departure_date = Date.current + 1.day  # 明天邮轮出发
      @flight_date = Date.current + 7.days  # 第7天航班离开
      @departure_port = '上海'
      @airport_location = '上海浦东国际机场'
      @flight_destination = '北京'
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
      
      # 查找第7天从上海浦东飞北京的航班（送机）
      @dropoff_flights = Flight
        .where(departure_city: @departure_port, destination_city: @flight_destination, data_version: 0)
        .where(flight_date: @flight_date)
        .where("departure_airport LIKE ?", "%浦东%")
        .to_a
      
      expect(@dropoff_flights).not_to be_empty, "数据包缺少#{@departure_port}到#{@flight_destination}的航班"
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
      
      # 创建机场送机服务（第7天航班离开）
      # 选择第7天出发的航班（最早起飞的航班）
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
        flight_date: @flight_date.to_s,
        departure_port: @departure_port,
        airport_location: @airport_location,
        flight_destination: @flight_destination,
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
      @flight_destination = data['flight_destination']
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
      
      # 断言4: 创建了机场送机服务
      add_assertion "创建了机场送机服务", weight: 10 do
        @transfer = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场送机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 送机服务关联了具体航班号
      add_assertion "送机服务关联了具体航班号（#{@departure_port}→#{@flight_destination}）", weight: 20 do
        expect(@transfer.flight_number).not_to be_nil,
          "送机服务未关联航班号"
        
        flight = Flight.find_by(
          flight_number: @transfer.flight_number,
          flight_date: @flight_date,
          data_version: 0
        )
        expect(flight).not_to be_nil,
          "未找到航班号 #{@transfer.flight_number}"
        expect(flight.departure_airport).to include('浦东'),
          "航班起飞机场错误。期望包含: 浦东, 实际: #{flight.departure_airport}"
      end
      
      # 断言6: 送机时间合理（航班起飞前1.5-2.5小时）
      add_assertion "送机时间合理（航班起飞前1.5-2.5小时）", weight: 5 do
        flight = Flight.where(flight_number: @transfer.flight_number, data_version: 0)
                       .where(flight_date: @flight_date)
                       .first
        expect(flight).not_to be_nil, "未找到对应航班"
        
        time_before_departure = ((flight.departure_time - @transfer.pickup_datetime) / 3600.0).round(1)
        expect(time_before_departure >= 1.5 && time_before_departure <= 2.5).to be(true),
          "送机时间不合理。航班起飞时间: #{flight.departure_time}, 送机时间: #{@transfer.pickup_datetime}, 提前: #{time_before_departure}小时（期望1.5-2.5小时）"
      end
      
      # 断言7: 送机地点正确
      add_assertion "送机地点正确（#{@airport_location}）", weight: 5 do
        expect(@transfer.location_to).to include(@airport_location),
          "送机地点错误。期望包含: #{@airport_location}, 实际: #{@transfer.location_to}"
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
