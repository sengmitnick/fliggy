# frozen_string_literal: true

require_relative '../base_validator'


# 验证用例146: 帮张三预订明天深圳酒店套餐，住2晚，并预订往返机场接送服务（明天中午11:45从北京飞抵深圳宝安国际机场T3航站楼接机至福田中心区 + 退房当天上午8点从福田中心区送机至宝安国际机场T3航站楼）
#
# 任务描述:
#   张三计划明天从北京飞往深圳（乘址08:30起飞的航班，预计中午11:45左右到达宝安国际机场T3航站楼），入住深圳酒店套餐，住2晚。需要预订往返机场接送服务：
#   1. 接机：明天中午11:45从北京飞抵深圳，从宝安国际机场T3航站楼接机到福田中心区接送服务点
#   2. 送机：退房当天上午8点从福田中心区送机到宝安国际机场T3航站楼
#
# 任务分解步骤:
#   1. 查询深圳的2晚酒店套餐（使用 HotelPackage.where(city: '深圳', night_count: 2)）
#   2. 筛选入住日期=明天、住宿晚数=2晚的套餐
#   3. 创建酒店套餐订单（contact_name=张三，contact_phone=张三电话）
#   4. 从 TransferLocation 表查询宝安机场（location_type='airport'，名称包含'宝安'）
#   5. 从 TransferLocation 表查询福田中心区接送服务点（location_type='other'，名称包含'福田中心区'）
#   6. 创建接机服务订单（transfer_type=airport_pickup，明天中午11:45从北京飞抵深圳，location_from=机场，location_to=福田中心区）
#   7. 创建送机服务订单（transfer_type=airport_dropoff，location_from=福田中心区，location_to=机场）
#   8. 确保接送机服务的乘客信息都使用张三的信息
#
# 复杂度分析（5个复杂点）：
#   1. 组合预订：需同时创建酒店套餐订单+接机订单+送机订单（3个不同类型的订单）
#   2. 联系人信息一致性：酒店订单联系人和接送机服务乘客都必须使用张三的信息
#   3. 时间协调：接机时间需要匹配入住日期，送机时间需要匹配退房日期
#   4. 接送点查询：需要从 TransferLocation 表查询机场位置和福田中心区接送服务点（不硬编码）
#   5. 往返逻辑：接机的location_to必须和送机的location_from一致
#
# 评分标准（总分10）：
#   1. 创建了酒店套餐订单（10分）
#   2. 城市正确=深圳（10分）
#   3. 入住日期正确=明天（10分）
#   4. 住宿晚数正确=2晚（10分）
#   5. 酒店订单联系人信息正确=张三（10分）
#   6. 创建了接机服务（10分）
#   7. 创建了送机服务（10分）
#   8. 接机下车点=福田中心区（从 TransferLocation 动态获取）（10分）
#   9. 送机上车点=福田中心区（从 TransferLocation 动态获取）（10分）
#   10. 接送机机场=宝安国际机场T3航站楼（从 TransferLocation 动态获取）（10分）
#
# 使用方法:
#   rake validator:simulate_single[v146_book_hotel_package_with_round_trip_transfer_validator]

module V101V150
  class V146BookHotelPackageWithRoundTripTransferValidator < BaseValidator
    self.validator_id = 'v146_book_hotel_package_with_round_trip_transfer_validator'
    self.task_id = 'a6b7c8d9-0e1f-2a3b-4c5d-6e7f8a9b0c1d'
    self.title = '帮张三预订明天深圳酒店套餐，住2晚，并预订往返机场接送服务（明天中午11:45从北京飞抵深圳宝安国际机场T3航站楼接机至福田中心区 + 退房当天上午8点从福田中心区送机至宝安国际机场T3航站楼）'
    self.description = '帮张三预订明天深圳酒店套餐，住2晚，并预订往返机场接送服务（明天中午11:45从北京飞抵深圳宝安国际机场T3航站楼接机至福田中心区 + 退房当天上午8点从福田中心区送机至宝安国际机场T3航站楼）'
    self.timeout_seconds = 300

    def prepare
      @checkin_date = Date.tomorrow
      @nights = 2
      @city = '深圳'
      
      # 查询航班信息（08:30从北京起飞，11:45到达深圳）
      @flight = Flight.where(
        departure_city: '北京',
        destination_city: @city,
        data_version: 0
      ).find { |f| f.departure_time.hour == 8 && f.departure_time.min == 30 }
      
      raise "数据包缺少08:30从北京飞深圳的航班" unless @flight
      
      # 从航班获取到达机场（由航班决定，不是用户选择）
      @flight_arrival_airport = @flight.arrival_airport  # "宝安T3"
      
      # 查询TransferLocation获取与航班到达机场匹配的接送点
      @airport_loc = TransferLocation.where(
        city: @city,
        location_type: 'airport',
        data_version: 0
      ).find { |loc| loc.name.include?('宝安') && loc.name.include?('T3') }
      
      raise "数据包缺少深圳宝安T3航站楼TransferLocation" unless @airport_loc
      
      @airport_location = @airport_loc.name  # 机场接送点完整名称（从transferlocation动态获取）
      
      # 查询TransferLocation获取福田中心区接送服务点（接送机上下车点）
      @service_loc = TransferLocation.where(
        city: @city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('福田中心区') }
      
      raise "数据包缺少福田中心区接送服务点TransferLocation" unless @service_loc
      
      @service_location = @service_loc.name  # 商圈接送点=福田中心区（从transferlocation动态获取）
      
      # 预查询联系人信息（用于 simulate 和 verify）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      # 查找可用的2晚酒店套餐
      @available_packages = HotelPackage
        .where(city: @city, data_version: 0)
        .where(night_count: @nights)
        .to_a
      
      expect(@available_packages).not_to be_empty, "数据包缺少深圳2晚酒店套餐"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      package = @available_packages.first
      option = package.package_options.first
      
      # 创建酒店套餐订单
      HotelPackageOrder.create!(
        user: user,
        hotel_package: package,
        hotel_id: package.hotel.id,
        package_option: option,
        passenger_id: passenger.id,
        contact_name: passenger.name,
        contact_phone: passenger.phone,
        check_in_date: @checkin_date,
        check_out_date: @checkin_date + @nights.days,
        total_price: option.price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 创建接机服务（入住当天，从航班到达机场至福田中心区）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @flight_arrival_airport,  # 上车点=航班到达机场（由 Flight.arrival_airport 决定，不是用户选择）
        location_to: @service_location,  # 下车点=福田中心区（用户选择，从 TransferLocation 动态获取）
        pickup_datetime: @checkin_date.in_time_zone + 11.hours + 45.minutes,  # 11:45从北京飞抵深圳
        vehicle_type: 'economy_5',
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        total_price: 100.0,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建送机服务（退房当天，从福田中心区至机场）
      checkout_date = @checkin_date + @nights.days
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: @service_location,  # 上车点=福田中心区（用户选择，从 TransferLocation 动态获取）
        location_to: @airport_location,  # 目的地=机场（固定目的地，从 TransferLocation 动态获取）
        pickup_datetime: checkout_date.in_time_zone + 8.hours,
        vehicle_type: 'economy_5',
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        total_price: 100.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        checkin_date: @checkin_date.to_s,
        nights: @nights,
        city: @city,
        flight_id: @flight&.id,
        flight_arrival_airport: @flight_arrival_airport,
        airport_location_name: @airport_loc&.name,
        service_location_name: @service_loc&.name,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @checkin_date = Date.parse(data['checkin_date']) if data['checkin_date']
      @nights = data['nights']
      @city = data['city']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      @flight_arrival_airport = data['flight_arrival_airport']
      
      # 重新查询Flight
      @flight = Flight.find_by(id: data['flight_id']) if data['flight_id']
      
      # 重新查询TransferLocation（机场和商圈接送点）
      @airport_loc = TransferLocation.find_by(
        city: @city,
        name: data['airport_location_name'],
        location_type: 'airport',
        data_version: 0
      ) if data['airport_location_name']
      
      @service_loc = TransferLocation.find_by(
        city: @city,
        name: data['service_location_name'],
        location_type: 'other',
        data_version: 0
      ) if data['service_location_name']
      
      @airport_location = @airport_loc&.name
      @service_location = @service_loc&.name
    end

    def verify
      # 断言1: 创建了酒店套餐订单
      add_assertion "创建了酒店套餐订单", weight: 10 do
        all_orders = HotelPackageOrder
          .joins(:hotel_package)
          .includes(:hotel_package, :package_option)
          .where(hotel_packages: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何酒店套餐订单"
        
        @hotel_package_order = all_orders.first
      end
      
      return if @hotel_package_order.nil?
      
      # 断言2: 城市正确
      add_assertion "城市正确（#{@city}）", weight: 10 do
        expect(@hotel_package_order.hotel_package.city).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@hotel_package_order.hotel_package.city}"
      end
      
      # 断言3: 入住日期正确
      add_assertion "入住日期正确（#{@checkin_date}）", weight: 10 do
        expect(@hotel_package_order.check_in_date).to eq(@checkin_date),
          "入住日期错误。期望: #{@checkin_date}（明天）, 实际: #{@hotel_package_order.check_in_date}"
      end
      
      # 断言4: 住宿晚数正确
      add_assertion "住宿晚数正确（#{@nights}晚）", weight: 10 do
        actual_nights = (@hotel_package_order.check_out_date - @hotel_package_order.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿晚数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      # 断言5: 酒店订单联系人信息正确（张三）
      add_assertion "酒店订单联系人信息正确（张三）", weight: 10 do
        expect(@hotel_package_order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@hotel_package_order.contact_name}"
        expect(@hotel_package_order.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@hotel_package_order.contact_phone}"
      end
      
      # 断言6: 创建了接机服务
      add_assertion "创建了接机服务", weight: 10 do
        @pickup_transfer = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@pickup_transfer).not_to be_nil, "未找到接机服务订单"
      end
      
      # 断言7: 创建了送机服务
      add_assertion "创建了送机服务", weight: 10 do
        @dropoff_transfer = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@dropoff_transfer).not_to be_nil, "未找到送机服务订单"
      end
      
      return if @pickup_transfer.nil? || @dropoff_transfer.nil?
      
      # 断言8: 接机下车点=福田中心区（用户选择的目的地）
      add_assertion "接机下车点=福田中心区（#{@service_location}）", weight: 10 do
        expect(@pickup_transfer.location_to).to eq(@service_location),
          "接机下车点错误。期望: #{@service_location}, 实际: #{@pickup_transfer.location_to}"
      end
      
      # 断言9: 送机上车点=福田中心区（用户选择的出发地）
      add_assertion "送机上车点=福田中心区（#{@service_location}）", weight: 10 do
        expect(@dropoff_transfer.location_from).to eq(@service_location),
          "送机上车点错误。期望: #{@service_location}, 实际: #{@dropoff_transfer.location_from}"
      end
      
      # 断言10: 接机上车点=航班到达机场（由Flight.arrival_airport决定）
      add_assertion "接机上车点=航班到达机场（#{@flight_arrival_airport}）", weight: 10 do
        expect(@pickup_transfer.location_from).to eq(@flight_arrival_airport),
          "接机上车点错误。期望: #{@flight_arrival_airport}（由航班到达机场决定）, 实际: #{@pickup_transfer.location_from}"
      end
    end
  end
end
