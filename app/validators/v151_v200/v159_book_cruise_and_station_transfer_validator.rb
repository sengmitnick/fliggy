# frozen_string_literal: true

require_relative '../base_validator'

# V159BookCruiseAndStationTransferValidator
# 验证用例159: 给张三和李四2成人预订上海日本邮轮6天5晚（当月最近日期班次），并预订火车站接站服务（从北京坐G93次火车来，邮轮出发当天11点到上海站，11:15接站到外滩）
#
# 任务描述:
#   张三和李四从北京坐G93次火车来上海，计划预订上海出发日本邮轮6天5晚，需要火车站接站服务：邮轮出发当天11点到上海站，11:15从上海站接站，送到外滩。
#   1. 上海出发日本邮轮6天5晚（当月班次，2成人：张三和李四）
#   2. 火车站接站服务（从北京坐G93次火车来，邮轮出发当天11点到上海站，11:15接站，送到外滩）
#
# 任务分解步骤:
#   1. 查询上海出发日本邮轮班次（departure_port=上海，duration_days=6，duration_nights=5，当月）
#   2. 选择当月最近日期的班次（按departure_date升序排序后取第一个）
#   3. 创建邮轮订单（2成人：张三和李四，联系人=张三）
#   4. 从 TransferLocation获取上海站接送点（火车站出发地）
#   5. 从TransferLocation获取上海外滩（送达地）
#   6. 创建火车站接站服务（乘客从北京坐G93次火车来，邮轮出发当天11点到上海站，11:15从上海站接站，送至外滩，不关联火车班次号）
#
# 评分标准（总分100分）:
#   1. 创建了邮轮订单 (20分)
#   2. 出发港正确（上海） (10分)
#   3. 行程天数正确（6天5晚） (10分)
#   4. 创建了火车站接站服务 (15分)
#   5. 接站服务地点正确（上海站→外滩） (25分)
#   6. 接站时间正确（邮轮出发当天上午11:15） (10分)
#   7. 联系人信息正确（张三） (5分)
#   8. 出行人员信息正确（2成人） (5分)

module V151V200
  class V159BookCruiseAndStationTransferValidator < BaseValidator
    self.validator_id = 'v159_book_cruise_and_station_transfer_validator'
    self.task_id = 'c9d0e1f2-3a4b-5c6d-7e8f-9a0b1c2d3e4f'
    self.title = '给张三和李四2成人预订上海日本邮轮6天5晚，并预订火车站接站服务（从北京坐G93次火车来，邮轮出发当天11点到上海站，11:15接站到外滩）'
    self.description = '给张三和李四从北京坐G93次火车来上海，预订上海出发日本邮轮6天5晚，并预订火车站接站服务（邮轮出发当天11点到上海站，11:15接站到外滩）'
    self.timeout_seconds = 300

    def prepare
      # 邮轮出发月份：当前月份
      @expected_month = Date.current.month
      @departure_port = '上海'
      @station_city = '上海'
      @train_departure_city = '北京'  # 乘客火车出发城市
      @duration_days = 6
      @duration_nights = 5
      @adult_count = 2
      
      # 预查询demo_user的乘客信息（张三作为联系人和出行人员）
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
      
      # 查询TransferLocation获取上海站接送点（出发地）
      @station_loc = TransferLocation.where(
        city: @station_city,
        location_type: 'train_station',
        data_version: 0
      ).find { |loc| loc.name == '上海站' }
      
      raise "数据包缺少上海站接送服务点TransferLocation" unless @station_loc
      
      @station_location = @station_loc.name  # 上海站（从TransferLocation动态获取）
      
      # 查询TransferLocation获取上海外滩接送点（送达地）
      @destination_loc = TransferLocation.where(
        city: @departure_port,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('外滩') }
      
      raise "数据包缺少上海外滩接送服务点TransferLocation" unless @destination_loc
      
      @destination_location = @destination_loc.name  # 外滩（从TransferLocation动态获取）
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择最近日期的班次
      sailing = @available_sailings.first
      ship = sailing.cruise_ship
      
      # 计算接站日期和时间（邮轮出发当天上午11:15，对应G93次11:00到达上海站后15分钟）
      pickup_date = sailing.departure_date
      pickup_datetime = pickup_date.in_time_zone.change(hour: 11, min: 15)
      
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
      
      # 创建火车站接站服务（乘客从北京坐火车来，从上海站接到外滩，不关联火车班次号）
      Transfer.create!(
        user: user,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @station_location,     # 上海站（从TransferLocation动态获取）
        location_to: @destination_location,   # 外滩（从TransferLocation动态获取）
        pickup_datetime: pickup_datetime,
        train_number: nil,  # 接站服务不关联火车班次号（但乘客从北京坐火车来）
        vehicle_type: 'business_5',
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        passenger_count: @adult_count,
        luggage_count: @adult_count,
        total_price: 100.0,
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
        station_city: @station_city,
        train_departure_city: @train_departure_city,
        duration_days: @duration_days,
        duration_nights: @duration_nights,
        adult_count: @adult_count,
        station_location: @station_location,
        destination_location: @destination_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @expected_month = data['expected_month']
      @departure_port = data['departure_port']
      @station_city = data['station_city']
      @train_departure_city = data['train_departure_city']
      @duration_days = data['duration_days']
      @duration_nights = data['duration_nights']
      @adult_count = data['adult_count']
      @station_location = data['station_location']
      @destination_location = data['destination_location']
      
      # 重新查询乘客信息（张三作为联系人和出行人员）
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
      @station_loc = TransferLocation.where(
        city: @station_city,
        location_type: 'train_station',
        data_version: 0
      ).find { |loc| loc.name == '上海站' }
      
      @station_location = @station_loc.name if @station_loc
      
      @destination_loc = TransferLocation.where(
        city: @departure_port,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('外滩') }
      
      @destination_location = @destination_loc.name if @destination_loc
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
          "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
        expect(sailing.duration_nights).to eq(@duration_nights),
          "行程晚数错误。期望: #{@duration_nights}晚, 实际: #{sailing.duration_nights}晚"
      end
      
      # 断言4: 创建了火车站接站服务
      add_assertion "创建了火车站接站服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站接站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 接站服务地点正确（上海站→外滩）
      add_assertion "接站服务地点正确（上海站→外滩）", weight: 25 do
        expect(@transfer.location_from).to include('上海站'),
          "接站服务出发地错误。期望包含: 上海站, 实际: #{@transfer.location_from}"
        expect(@transfer.location_to).to include('外滩'),
          "接站服务送达地错误。期望包含: 外滩, 实际: #{@transfer.location_to}"
      end
      
      # 断言6: 接站时间正确（邮轮出发当天上午11:15）
      add_assertion "接站时间正确（邮轮出发当天上午11:15）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expected_pickup_date = sailing.departure_date
        actual_pickup_date = @transfer.pickup_datetime.to_date
        
        expect(actual_pickup_date).to eq(expected_pickup_date),
          "接站日期错误。期望: #{expected_pickup_date}（邮轮出发当天）, 实际: #{actual_pickup_date}"
        
        pickup_hour = @transfer.pickup_datetime.hour
        pickup_minute = @transfer.pickup_datetime.min
        expect(pickup_hour).to eq(11), "接站时间错误。期望: 上午11:15, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
        expect(pickup_minute).to eq(15), "接站时间错误。期望: 上午11:15, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
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
