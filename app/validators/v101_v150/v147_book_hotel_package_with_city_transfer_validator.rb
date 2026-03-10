# frozen_string_literal: true

require_relative '../base_validator'

# V147BookHotelPackageWithCityTransferValidator
# 预订广州酒店套餐 + 机场往返接送服务（明天上午07:30从北京飞往广州，10:45到达白云T2接机至珠江新城 + 退房当天下午14:00从珠江新城送机至广州白云国际机场T2航站楼）
#
# 验证用例147: 帮张三预订明天广州酒店套餐，住1晚，并预订入住当天机场接机（明天上午07:30从北京飞往广州，10:45到达白云T2接机至珠江新城）+退房当天机场送机（后天下午14:00从珠江新城到广州白云国际机场T2航站楼）服务
#
# 任务描述:
#   张三计划明天从北京飞往广州（乘坐07:30起飞的航班，预计上午10:45左右到达白云T2航站楼），入住广州酒店套餐，住1晚。需要预订机场往返接送服务：
#   1. 接机：明天上午10:45到达白云T2，从白云T2接机到珠江新城CBD接送服务站
#   2. 送机：退房当天下午14:00从珠江新城CBD接送服务站送机到广州白云国际机场T2航站楼
#
# 任务分解步骤:
#   1. 查询Flight获取07:30飞往广州的航班，确定到达机场（arrival_airport="白云T2"）
#   2. 查询TransferLocation获取广州珠江新城服务点（location_type='other'，名称包含'珠江新城'）
#   3. 查询广州的1晚酒店套餐（使用 HotelPackage.where(city: '广州', night_count: 1)）
#   4. 创建酒店套餐订单（contact_name=张三，contact_phone=张三电话）
#   5. 创建接机服务订单（transfer_type=airport_pickup，location_from=航班到达机场（从Flight.arrival_airport获取），location_to=珠江新城服务点）
#   6. 创建送机服务订单（transfer_type=airport_dropoff，location_from=珠江新城服务点，location_to=广州白云国际机场）
#   7. 确保接送机服务的乘客信息都使用张三的信息
#
# 复杂度分析（5个复杂点）：
#   1. 组合预订：需同时创建酒店套餐订单+接机订单+送机订单（3个不同类型的订单）
#   2. 联系人信息一致性：酒店订单联系人和接送机服务乘客都必须使用张三的信息
#   3. 时间协调：接机时间需要匹配航班到达时间和入住日期，送机时间需要匹配退房日期
#   4. 接机点查询：需要从 Flight 模型查询航班的 arrival_airport 字段（不硬编码）
#   5. 服务点查询：需要从 TransferLocation 查询具体的接送服务点（不使用笼统的"市区"）
#
# 评分标准（总分100）：
#   1. 创建了酒店套餐订单（20分）
#   2. 城市正确=广州（10分）
#   3. 入住日期正确=明天（5分）
#   4. 住宿晚数正确=1晚（5分）
#   5. 酒店订单联系人信息正确=张三（10分）
#   6. 创建了机场往返接送服务（接机+送机）（10分）
#   7. 接机服务乘客信息正确=张三（10分）
#   8. 送机服务乘客信息正确=张三（10分）
#   9. 接机服务时间在入住当天（5分）
#   10. 接机上车点=航班到达机场（从 Flight.arrival_airport 动态获取）（5分）
#   11. 接机下车点=服务点（从 TransferLocation 动态获取）（5分）
#   12. 送机上车点=服务点（从 TransferLocation 动态获取）（5分）
#
# 使用方法:
#   rake validator:simulate_single[v147_book_hotel_package_with_city_transfer_validator]

module V101V150
  class V147BookHotelPackageWithCityTransferValidator < BaseValidator
    self.validator_id = 'v147_book_hotel_package_with_city_transfer_validator'
    self.task_id = 'b7c8d9e0-1f2a-3b4c-5d6e-7f8a9b0c1d2e'
    self.title = '帮张三预订明天广州酒店套餐，住1晚，并预订入住当天机场接机（明天上午07:30从北京飞往广州，10:45到达白云T2接机至珠江新城）+退房当天机场送机（后天下午14:00从珠江新城到广州白云国际机场T2航站楼）服务'
    self.description = '帮张三预订明天广州酒店套餐，住1晚，并预订入住当天机场接机（明天上午07:30从北京飞往广州，10:45到达白云T2接机至珠江新城）+退房当天机场送机（后天下午14:00从珠江新城到广州白云国际机场T2航站楼）服务'
    self.timeout_seconds = 300

    def prepare
      @checkin_date = Date.tomorrow
      @nights = 1
      @city = '广州'
      
      # 查询航班信息（接机服务需要知道航班到达哪个航站楼）
      @flight = Flight.where(
        departure_city: '北京',
        destination_city: @city,
        data_version: 0
      ).find { |f| f.departure_time.hour == 7 && f.departure_time.min == 30 }
      
      raise "数据包缺少07:30从北京飞往广州的航班" unless @flight
      
      # 从航班获取到达机场（由航班决定，不是用户选择）
      @flight_arrival_airport = @flight.arrival_airport  # "白云T2"
      
      # 查询TransferLocation获取广州服务点（接送机上下车点）
      @service_loc = TransferLocation.where(
        city: @city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('珠江新城') }
      
      raise "数据包缺少广州珠江新城TransferLocation" unless @service_loc
      
      @service_location = @service_loc.name  # 服务点=珠江新城CBD接送服务站（从TransferLocation动态获取）
      
      # 送机目的地（固定目的地，可以从TransferLocation查询）
      @dropoff_location = '广州白云国际机场T2航站楼'
      
      # 预查询联系人信息（用于 simulate 和 verify）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      # 查找可用的1晚酒店套餐
      @available_packages = HotelPackage
        .where(city: @city, data_version: 0)
        .where(night_count: @nights)
        .to_a
      
      expect(@available_packages).not_to be_empty, "数据包缺少广州1晚酒店套餐"
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
      
      # 创建机场接机服务
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @flight_arrival_airport,  # 上车点=航班到达机场（由 Flight.arrival_airport 决定，不是用户选择）
        location_to: @service_location,  # 下车点=珠江新城（用户选择，从 TransferLocation 动态获取）
        pickup_datetime: @checkin_date.in_time_zone + 10.hours + 45.minutes,  # 10:45到达广州
        vehicle_type: 'business_5',
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        total_price: 150.0,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建机场送机服务（退房当天）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: @service_location,  # 上车点=珠江新城（用户选择的出发地，从 TransferLocation 动态获取）
        location_to: @dropoff_location,  # 目的地=机场（固定目的地）
        pickup_datetime: (@checkin_date + @nights.days).in_time_zone + 14.hours,
        vehicle_type: 'business_5',
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        total_price: 150.0,
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
        service_location_name: @service_loc&.name,
        dropoff_location: @dropoff_location,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @checkin_date = Date.parse(data['checkin_date']) if data['checkin_date']
      @nights = data['nights']
      @city = data['city']
      @flight_arrival_airport = data['flight_arrival_airport']
      @dropoff_location = data['dropoff_location']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      
      # 重新查询Flight
      @flight = Flight.find_by(id: data['flight_id']) if data['flight_id']
      
      # 重新查询TransferLocation（服务点）
      @service_loc = TransferLocation.find_by(
        city: @city,
        name: data['service_location_name'],
        location_type: 'other',
        data_version: 0
      ) if data['service_location_name']
      
      @service_location = @service_loc&.name
    end

    def verify
      # 断言1: 创建了酒店套餐订单
      add_assertion "创建了酒店套餐订单", weight: 20 do
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
      add_assertion "入住日期正确（#{@checkin_date}）", weight: 5 do
        expect(@hotel_package_order.check_in_date).to eq(@checkin_date),
          "入住日期错误。期望: #{@checkin_date}（明天）, 实际: #{@hotel_package_order.check_in_date}"
      end
      
      # 断言4: 住宿晚数正确
      add_assertion "住宿晚数正确（#{@nights}晚）", weight: 5 do
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
      
      # 断言6: 创建了机场往返接送服务（接机+送机）
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
      
      # 断言7: 接机服务乘客信息正确（张三）
      add_assertion "接机服务乘客信息正确（张三）", weight: 10 do
        expect(@pickup_transfer.passenger_name).to eq(@expected_contact_name),
          "接机乘客姓名错误。期望: #{@expected_contact_name}, 实际: #{@pickup_transfer.passenger_name}"
        expect(@pickup_transfer.passenger_phone).to eq(@expected_contact_phone),
          "接机乘客电话错误。期望: #{@expected_contact_phone}, 实际: #{@pickup_transfer.passenger_phone}"
      end
      
      # 断言8: 送机服务乘客信息正确（张三）
      add_assertion "送机服务乘客信息正确（张三）", weight: 10 do
        expect(@dropoff_transfer.passenger_name).to eq(@expected_contact_name),
          "送机乘客姓名错误。期望: #{@expected_contact_name}, 实际: #{@dropoff_transfer.passenger_name}"
        expect(@dropoff_transfer.passenger_phone).to eq(@expected_contact_phone),
          "送机乘客电话错误。期望: #{@expected_contact_phone}, 实际: #{@dropoff_transfer.passenger_phone}"
      end
      
      # 断言9: 接机服务时间在入住当天
      add_assertion "接机服务时间在入住当天", weight: 5 do
        transfer_date = @pickup_transfer.pickup_datetime.to_date
        expect(transfer_date).to eq(@checkin_date),
          "接机服务时间错误。期望: #{@checkin_date}（入住当天）, 实际: #{transfer_date}"
      end
      
      # 断言10: 接机上车点=航班到达机场（由Flight.arrival_airport决定）
      add_assertion "接机上车点=航班到达机场（#{@flight_arrival_airport}）", weight: 5 do
        expect(@pickup_transfer.location_from).to eq(@flight_arrival_airport),
          "接机上车点错误。期望: #{@flight_arrival_airport}（由航班到达机场决定）, 实际: #{@pickup_transfer.location_from}"
      end
      
      # 断言11: 接机下车点=服务点（用户选择）
      add_assertion "接机下车点=服务点（#{@service_location}）", weight: 5 do
        expect(@pickup_transfer.location_to).to eq(@service_location),
          "接机下车点错误。期望: #{@service_location}, 实际: #{@pickup_transfer.location_to}"
      end
      
      # 断言12: 送机上车点=服务点（用户选择）
      add_assertion "送机上车点=服务点（#{@service_location}）", weight: 5 do
        expect(@dropoff_transfer.location_from).to eq(@service_location),
          "送机上车点错误。期望: #{@service_location}, 实际: #{@dropoff_transfer.location_from}"
      end
    end
  end
end
