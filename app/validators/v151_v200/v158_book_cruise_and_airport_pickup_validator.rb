# frozen_string_literal: true

require_relative '../base_validator'

# V158BookCruiseAndAirportPickupValidator
# 验证用例158: 给张三和李四2成人预订上海日本邮轮6天5晚（当月最近日期班次），并预订机场接机服务（从北京飞来，邮轮出发前1天下午2:30到T1航站楼，下午3点接机到外滩）
#
# 任务描述:
#   张三和李四从北京飞来上海，计划预订上海出发日本邮轮6天5晚，需要机场接机服务：邮轮出发前1天下午2:30到T1航站楼，下午3点从上海浦东国际机场T1航站楼接机，送到外滩。
#   1. 上海出发日本邮轮6天5晚（当月班次，2成人：张三和李四）
#   2. 机场接机服务（从北京飞来，邮轮出发前1天下午2:30到T1航站楼，下午3点接机，送到外滩）
#
# 任务分解步骤:
#   1. 查询上海出发日本邮轮班次（departure_port=上海，duration_days=6，duration_nights=5，当月）
#   2. 选择当月最近日期的班次（按departure_date升序排序后取第一个）
#   3. 创建邮轮订单（2成人：张三和李四，联系人=张三）
#   4. 从TransferLocation获取上海浦东国际机场接机点（机场出发地）
#   5. 从TransferLocation获取上海外滩（送达地）
#   6. 创建机场接机服务（乘客从北京飞来，邮轮出发前1天下午2:30到T1航站楼，下午3点接机，送至外滩，不关联航班号）
#
# 评分标准（总分100分）:
#   1. 创建了邮轮订单 (20分)
#   2. 出发港正确（上海） (10分)
#   3. 行程天数正确（6天5晚） (10分)
#   4. 创建了机场接机服务 (15分)
#   5. 接机服务地点正确（上海浦东国际机场→外滩） (25分)
#   6. 接机时间正确（邮轮出发前1天下午3点） (10分)
#   7. 联系人信息正确（张三） (5分)
#   8. 出行人员信息正确（2成人） (5分)

module V151V200
  class V158BookCruiseAndAirportPickupValidator < BaseValidator
    self.validator_id = 'v158_book_cruise_and_airport_pickup_validator'
    self.task_id = 'b8c9d0e1-2f3a-4b5c-6d7e-8f9a0b1c2d3e'
    self.title = '给张三和李四2成人预订上海日本邮轮6天5晚，并预订机场接机服务（从北京飞来，邮轮出发前1天下午2:30到T1航站楼，下午3点接机到外滩）'
    self.description = '给张三和李四2成人从北京飞来上海，预订上海出发日本邮轮6天5晚，并预订机场接机服务（邮轮出发前1天下午2:30到T1航站楼，下午3点接机到外滩）'
    self.timeout_seconds = 300

    def prepare
      # 邮轮出发月份：当前月份
      @expected_month = Date.current.month
      @departure_port = '上海'
      @airport_city = '上海'
      @flight_departure_city = '北京'  # 乘客航班出发城市
      @duration_days = 6
      @duration_nights = 5
      @adult_count = 2
      
      # 预查询demo_user的乘客信息（张三作为联系人和第一位出行人员）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的上海出发日本邮轮班次（按月份查询）
      @available_sailings = CruiseSailing
        .where("departure_port LIKE ?", "%#{@departure_port}%")
        .where(duration_days: @duration_days, duration_nights: @duration_nights, data_version: 0)
        .where('EXTRACT(MONTH FROM departure_date) = ?', @expected_month)
        .order(departure_date: :asc)
        .to_a
      
      raise "数据包缺少上海出发日本6天5晚邮轮班次（#{@expected_month}月份）" if @available_sailings.empty?
      
      # 查询TransferLocation获取上海浦东国际机场接送点（出发地）
      @airport_loc = TransferLocation.where(
        city: @airport_city,
        location_type: 'airport',
        data_version: 0
      ).find { |loc| loc.name.include?('浦东') }
      
      raise "数据包缺少上海浦东机场接送服务点TransferLocation" unless @airport_loc
      
      @airport_location = @airport_loc.name  # 上海浦东国际机场T1航站楼（从TransferLocation动态获取）
      
      # 查询TransferLocation获取上海外滩接送点（送达地）
      @terminal_loc = TransferLocation.where(
        city: @departure_port,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('外滩') }
      
      raise "数据包缺少上海外滩接送服务点TransferLocation" unless @terminal_loc
      
      @terminal_location = @terminal_loc.name  # 外滩（从TransferLocation动态获取）
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择最近日期的班次
      sailing = @available_sailings.first
      ship = sailing.cruise_ship
      
      # 计算接机日期和时间（邮轮出发前1天下午3点）
      pickup_date = sailing.departure_date - 1.day
      pickup_datetime = pickup_date.in_time_zone.change(hour: 15, min: 0)
      
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
      
      # 准备出行人员信息（2成人：张三和李四）
      passenger_info = [
        {
          name: @passenger.name,
          id_number: @passenger.id_number,
          phone: @passenger.phone,
          passenger_type: 'adult'
        },
        {
          name: '李四',
          id_number: '110101199001012346',
          phone: '13900000002',
          passenger_type: 'adult'
        }
      ]
      
      # 创建邮轮订单（明确出行人员：张三和李四）
      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: cruise_product.id,
        quantity: @adult_count,
        passenger_info: passenger_info,
        contact_name: @passenger.name,
        contact_phone: @passenger.phone,
        total_price: total_price,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建机场接机服务（乘客从北京飞来，从上海浦东机场接到外滩，不关联航班号）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_location,  # 上海浦东国际机场T1航站楼（从TransferLocation动态获取）
        location_to: @terminal_location,   # 外滩（从TransferLocation动态获取）
        pickup_datetime: pickup_datetime,
        flight_number: nil,  # 接机服务不关联航班号（但乘客从#{@flight_departure_city}飞来）
        vehicle_type: 'business_5',
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        passenger_count: @adult_count,
        luggage_count: @adult_count,
        total_price: 150.0,
        discount_amount: 0,
        status: 'paid',
        driver_status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        expected_month: @expected_month,
        departure_port: @departure_port,
        airport_city: @airport_city,
        flight_departure_city: @flight_departure_city,
        duration_days: @duration_days,
        duration_nights: @duration_nights,
        adult_count: @adult_count,
        airport_location: @airport_location,
        terminal_location: @terminal_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @expected_month = data['expected_month']
      @departure_port = data['departure_port']
      @airport_city = data['airport_city']
      @flight_departure_city = data['flight_departure_city']
      @duration_days = data['duration_days']
      @duration_nights = data['duration_nights']
      @adult_count = data['adult_count']
      @airport_location = data['airport_location']
      @terminal_location = data['terminal_location']
      
      # 重新查询乘客信息（张三作为联系人和第一位出行人员）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 重新查询邮轮班次
      @available_sailings = CruiseSailing
        .where("departure_port LIKE ?", "%#{@departure_port}%")
        .where(duration_days: @duration_days, duration_nights: @duration_nights, data_version: 0)
        .where('EXTRACT(MONTH FROM departure_date) = ?', @expected_month)
        .order(departure_date: :asc)
        .to_a
      
      # 重新查找TransferLocation
      @airport_loc = TransferLocation.where(
        city: @airport_city,
        location_type: 'airport',
        data_version: 0
      ).find { |loc| loc.name.include?('浦东') }
      
      @airport_location = @airport_loc.name if @airport_loc
      
      @terminal_loc = TransferLocation.where(
        city: @departure_port,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('外滩') }
      
      @terminal_location = @terminal_loc.name if @terminal_loc
    end

    def verify
      # 断言1: 创建了邮轮订单
      add_assertion "创建了邮轮订单", weight: 20 do
        @cruise_order = CruiseOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@cruise_order).not_to be_nil, "未找到任何邮轮订单"
      end
      
      return if @cruise_order.nil?
      
      # 断言2: 出发港正确（上海）
      add_assertion "出发港正确（#{@departure_port}）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.departure_port).to include(@departure_port),
          "出发港错误。期望包含: #{@departure_port}, 实际: #{sailing.departure_port}"
      end
      
      # 断言3: 行程天数正确（6天5晚）
      add_assertion "行程天数正确（#{@duration_days}天#{@duration_nights}晚）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天#{@duration_nights}晚, 实际: #{sailing.duration_days}天#{sailing.duration_nights}晚"
      end
      
      # 断言4: 创建了机场接机服务
      add_assertion "创建了机场接机服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场接机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 接机服务地点正确（上海浦东国际机场→外滩）
      add_assertion "接机服务地点正确（#{@airport_location}→#{@terminal_location}）", weight: 25 do
        expect(@transfer.location_from).to eq(@airport_location),
          "接机出发地错误。期望: #{@airport_location}, 实际: #{@transfer.location_from}"
        
        expect(@transfer.location_to).to eq(@terminal_location),
          "接机目的地错误。期望: #{@terminal_location}, 实际: #{@transfer.location_to}"
      end
      
      # 断言6: 接机时间正确（邮轮出发前1天下午3点）
      add_assertion "接机时间正确（邮轮出发前1天下午3点）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expected_pickup_date = sailing.departure_date - 1.day
        expected_time = expected_pickup_date.in_time_zone.change(hour: 15, min: 0)
        actual_time = @transfer.pickup_datetime.in_time_zone
        
        # 比较Unix时间戳忽略时区差异
        expect(actual_time.to_i).to eq(expected_time.to_i),
          "接机时间错误。期望: #{expected_time.strftime('%Y-%m-%d %H:%M %Z')}（邮轮#{sailing.departure_date.strftime('%m月%d日')}出发前1天下午3点）, 实际: #{actual_time.strftime('%Y-%m-%d %H:%M %Z')}"
      end
      
      # 断言7: 联系人信息正确（张三）
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 5 do
        expect(@cruise_order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@cruise_order.contact_name}"
        expect(@cruise_order.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@cruise_order.contact_phone}"
      end
      
      # 断言8: 出行人员信息正确（2成人）
      add_assertion "出行人员信息正确（2成人）", weight: 5 do
        passengers = @cruise_order.passenger_list
        expect(passengers.size).to eq(2), "出行人员数量错误。期望: 2人, 实际: #{passengers.size}人"
        
        adult_passengers = passengers.select { |p| p['passenger_type'] == 'adult' }
        expect(adult_passengers.size).to eq(2), "成人数量错误。期望: 2人, 实际: #{adult_passengers.size}人"
        
        passenger_names = passengers.map { |p| p['name'] }
        expect(passenger_names).to include(@passenger.name), "出行人员中未找到#{@passenger.name}"
        expect(passenger_names).to include('李四'), "出行人员中未找到李四"
      end
    end
  end
end
