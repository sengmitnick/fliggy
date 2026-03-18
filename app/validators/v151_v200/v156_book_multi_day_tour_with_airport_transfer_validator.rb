# frozen_string_literal: true

require_relative '../base_validator'

# V156BookMultiDayTourWithAirportTransferValidator
# 验证用例156: 给张三和李四2成人明天成都3日跟团游，并订机场接机（接今天上海飞来的MU5424航班10:20到双流T2，送到春熙路太古里）和送机（第4天早上6:00从春熙路太古里出发去双流T2）
#
# 任务描述:
#   张三计划明天开始成都3日跟团游，需要机场往返接送服务：接机服务接今天从上海飞来的MU5424航班（10:20到达双流T2，送到春熙路太古里接送服务站），送机服务第4天早上6:00从春熙路太古里接送服务站出发去双流T2。
#   1. 成都3日跟团游（明天出发，2成人）
#   2. 机场接机服务（接今天上海MU5424航班，10:20到达双流T2，送至春熙路太古里接送服务站）
#   3. 机场送机服务（第4天早上6:00从春熙路太古里接送服务站出发，送至双流T2，不关联航班号）
#
# 任务分解步骤:
#   1. 查询成都3日跟团游产品（destination=成都，duration=3，travel_type=跟团游）
#   2. 创建跟团游订单（出发日期=明天，成人2人，联系人=张三）
#   3. 查询今天上海到成都的MU5424航班（到达双流T2，10:20到达）
#   4. 从TransferLocation获取双流国际机场T2航站楼（接机地点）
#   5. 从TransferLocation获取春熙路太古里接送服务站（接机送达地点、送机出发地点）
#   6. 创建机场接机服务（从双流T2接机，送至春熙路太古里，关联MU5421航班，接机时间=航班到达后30分钟）
#   7. 查询第4天成都到上海的MU5434航班（从双流T2起飞，8:00起飞，用于计算送机时间）
#   8. 创建机场送机服务（第4天早上6:00从春熙路太古里出发，送至双流T2，不关联航班号）
#
# 评分标准（总分100分）:
#   1. 创建了跟团游订单 (15分)
#   2. 城市正确（成都） (10分)
#   3. 出发日期正确（明天） (10分)
#   4. 成人数量=2 (5分)
#   5. 创建了机场往返接送服务（接机+送机） (15分)
#   6. 接机服务关联了具体航班号（上海→成都MU5424） (15分)
#   7. 接机时间合理（航班到达后20-40分钟） (3分)
#   8. 送机服务地点正确（春熙路太古里→双流T2） (15分)
#   9. 送机时间正确（第4天早上6:00） (7分)
#   10. 联系人信息正确（张三） (5分)

module V151V200
  class V156BookMultiDayTourWithAirportTransferValidator < BaseValidator
    self.validator_id = 'v156_book_multi_day_tour_with_airport_transfer_validator'
    self.task_id = 'f1a2b3c4-5d6e-7f8a-9b0c-1d2e3f4a5b7c'
    self.title = '给张三和李四2成人明天成都3日跟团游，并订机场接机（接今天上海飞来的MU5424航班10:20到双流T2，送到春熙路太古里）和送机（第4天早上6:00从春熙路太古里出发去双流T2）'
    self.description = '给张三和李四2成人明天成都3日跟团游，并订机场接机（接今天上海飞来的MU5424航班10:20到达双流T2，送到春熙路太古里接送服务站）和送机（第4天早上6:00从春熙路太古里接送服务站出发去双流T2）'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.current + 1.day  # 明天开始游玩
      @pickup_flight_date = Date.current  # 今天到达
      @dropoff_flight_date = Date.current + 3.days  # 第4天离开
      @city = '成都'
      @flight_origin = '上海'
      @duration_days = 3
      
      # 查询今天从上海飞成都的MU5424航班（接机）
      @pickup_flight = Flight
        .where(departure_city: @flight_origin, destination_city: @city, data_version: 0)
        .where(flight_date: @pickup_flight_date)
        .where("arrival_airport LIKE ?", "%双流T2%")
        .where(flight_number: 'MU5424')
        .first
      
      raise "数据包缺少今天上海到成都的MU5424航班" unless @pickup_flight
      
      @pickup_flight_number = @pickup_flight.flight_number  # MU5424
      @pickup_arrival_time = @pickup_flight.arrival_time  # 10:20
      
      # 查询第4天从成都飞上海的MU5434航班（送机）
      @dropoff_flight = Flight
        .where(departure_city: @city, destination_city: @flight_origin, data_version: 0)
        .where(flight_date: @dropoff_flight_date)
        .where("departure_airport LIKE ?", "%双流T2%")
        .where(flight_number: 'MU5434')
        .first
      
      raise "数据包缺少第4天成都到上海的MU5434航班" unless @dropoff_flight
      
      @dropoff_flight_number = @dropoff_flight.flight_number  # MU5434
      @dropoff_departure_time = @dropoff_flight.departure_time  # 08:00
      
      # 查询TransferLocation获取双流国际机场T2航站楼（接机地点、送机送达地点）
      @airport_loc = TransferLocation.where(
        city: @city,
        location_type: 'airport',
        data_version: 0
      ).find { |loc| loc.name.include?('双流') && loc.name.include?('T2') && loc.name.include?('航站楼') }
      
      raise "数据包缺少成都双流国际机场T2航站楼TransferLocation" unless @airport_loc
      
      @airport_location = @airport_loc.name  # 双流国际机场T2航站楼（从TransferLocation动态获取）
      
      # 查询TransferLocation获取春熙路太古里接送服务站（接机送达地点、送机出发地点）
      @downtown_loc = TransferLocation.where(
        city: @city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('春熙路') && loc.name.include?('太古里') }
      
      raise "数据包缺少成都春熙路太古里接送服务站TransferLocation" unless @downtown_loc
      
      @downtown_location = @downtown_loc.name  # 春熙路太古里接送服务站（从TransferLocation动态获取）
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的成都3日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 3, travel_type: '跟团游', data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少成都3日跟团游产品"
      
      # 查找舒适型5座套餐
      @available_packages = TransferPackage.where(
        vehicle_category: 'comfort_5',
        data_version: 0
      ).order(:price)
      
      expect(@available_packages).not_to be_empty, "未找到舒适型5座套餐"
      
      @best_package = @available_packages.first
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      tour = @available_tours.first
      tour_package = tour.tour_packages.where(data_version: 0).order(:price).first
      
      raise "产品 #{tour.title} 没有可用套餐" if tour_package.nil?
      
      # 创建跟团游订单
      TourGroupBooking.create!(
        user: user,
        tour_group_product: tour,
        tour_package: tour_package,
        travel_date: @tour_date,
        adult_count: 2,
        child_count: 0,
        contact_name: @passenger.name,
        contact_phone: @passenger.phone,
        total_price: tour_package.price * 2,
        status: 'pending',
        data_version: @data_version
      )
      
      # 计算接机时间（MU5424航班到达后30分钟）
      pickup_datetime = @pickup_arrival_time + 30.minutes
      
      # 创建机场接机服务（从双流T2接机，送至春熙路太古里，关联MU5424航班）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_location,  # 双流国际机场T2航站楼（从TransferLocation动态获取）
        location_to: @downtown_location,  # 春熙路太古里接送服务站（从TransferLocation动态获取）
        pickup_datetime: pickup_datetime,  # MU5424到达后30分钟
        flight_number: @pickup_flight_number,  # 关联MU5424航班
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        passenger_count: 2,
        luggage_count: 2,
        total_price: @best_package.price,
        discount_amount: 0,
        status: 'paid',
        driver_status: 'pending',
        data_version: @data_version
      )
      
      # 设置送机时间（第4天早上6:00）
      dropoff_datetime = @dropoff_flight_date.in_time_zone.change(hour: 6, min: 0)
      
      # 创建机场送机服务（第4天早上6:00从春熙路太古里出发，送至双流T2，不关联航班号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: @downtown_location,  # 春熙路太古里接送服务站（从TransferLocation动态获取）
        location_to: @airport_location,  # 双流国际机场T2航站楼（从TransferLocation动态获取）
        pickup_datetime: dropoff_datetime,  # 第4天早上6:00出发
        flight_number: nil,  # 送机服务不关联航班号
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        passenger_count: 2,
        luggage_count: 2,
        total_price: @best_package.price,
        discount_amount: 0,
        status: 'paid',
        driver_status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        tour_date: @tour_date.to_s,
        pickup_flight_date: @pickup_flight_date.to_s,
        dropoff_flight_date: @dropoff_flight_date.to_s,
        city: @city,
        flight_origin: @flight_origin,
        airport_location: @airport_location,
        downtown_location: @downtown_location,
        pickup_flight_number: @pickup_flight_number,
        dropoff_flight_number: @dropoff_flight_number,
        duration_days: @duration_days
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @tour_date = Date.parse(data['tour_date']) if data['tour_date']
      @pickup_flight_date = Date.parse(data['pickup_flight_date']) if data['pickup_flight_date']
      @dropoff_flight_date = Date.parse(data['dropoff_flight_date']) if data['dropoff_flight_date']
      @city = data['city']
      @flight_origin = data['flight_origin']
      @airport_location = data['airport_location']
      @downtown_location = data['downtown_location']
      @pickup_flight_number = data['pickup_flight_number']
      @dropoff_flight_number = data['dropoff_flight_number']
      @duration_days = data['duration_days']
      
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 重新查询跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 3, travel_type: '跟团游', data_version: 0)
        .to_a
      
      # 重新查询套餐
      @available_packages = TransferPackage.where(
        vehicle_category: 'comfort_5',
        data_version: 0
      ).order(:price)
      
      @best_package = @available_packages.first if @available_packages.any?
    end

    def verify
      # 断言1: 创建了跟团游订单
      add_assertion "创建了跟团游订单", weight: 15 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { destination: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何跟团游订单"
        @tour_booking = all_bookings.first
      end
      
      return if @tour_booking.nil?
      
      # 断言2: 城市正确
      add_assertion "城市正确（#{@city}）", weight: 10 do
        expect(@tour_booking.tour_group_product.destination).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      # 断言3: 出发日期正确
      add_assertion "出发日期正确（#{@tour_date}）", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@tour_date),
          "出发日期错误。期望: #{@tour_date}（明天）, 实际: #{@tour_booking.travel_date}"
      end
      
      # 断言4: 成人数量=2
      add_assertion "成人数量=2", weight: 5 do
        expect(@tour_booking.adult_count).to eq(2),
          "成人数量错误。期望: 2, 实际: #{@tour_booking.adult_count}"
      end
      
      # 断言5: 创建了机场往返接送服务
      add_assertion "创建了机场往返接送服务（接机+送机）", weight: 15 do
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
      
      # 断言6: 接机服务关联了具体航班号
      add_assertion "接机服务关联了具体航班号（#{@flight_origin}→#{@city}）", weight: 15 do
        expect(@pickup_transfer.flight_number).not_to be_nil, "接机服务未关联航班号"
        
        # 验证航班号对应的航班确实是北京到成都
        flight = Flight.find_by(
          flight_number: @pickup_transfer.flight_number,
          departure_city: @flight_origin,
          destination_city: @city,
          data_version: 0
        )
        
        expect(flight).not_to be_nil,
          "航班号#{@pickup_transfer.flight_number}不是#{@flight_origin}到#{@city}的航班"
        
        # 验证目的地机场是成都双流机场
        if flight
          expect(flight.arrival_airport).to include('双流'),
            "航班目的地机场错误。期望: 双流机场, 实际: #{flight.arrival_airport}"
        end
      end
      
      # 断言7: 接机时间合理（航班到达后20-40分钟）
      add_assertion "接机时间合理（航班到达后20-40分钟）", weight: 3 do
        if @pickup_transfer.flight_number.present?
          # 查询对应的航班（必须指定日期）
          flight = Flight
            .where(flight_number: @pickup_transfer.flight_number, data_version: 0)
            .where(departure_city: @flight_origin, destination_city: @city)
            .where(flight_date: @pickup_flight_date)
            .first
          
          if flight && flight.arrival_time.present?
            time_after_arrival = ((@pickup_transfer.pickup_datetime - flight.arrival_time) / 60.0).round
            is_reasonable = time_after_arrival >= 20 && time_after_arrival <= 40
            
            expect(is_reasonable).to be(true),
              "接机时间不合理。航班#{flight.arrival_time.strftime('%H:%M')}到达，" \
              "接机时间#{@pickup_transfer.pickup_datetime.strftime('%H:%M')}，" \
              "间隔#{time_after_arrival}分钟（应为20-40分钟）"
          end
        end
      end
      
      # 断言8: 送机服务地点正确（从春熙路太古里到双流T2）
      add_assertion "送机服务地点正确（#{@downtown_location}→#{@airport_location}）", weight: 15 do
        expect(@dropoff_transfer.location_from).to eq(@downtown_location),
          "送机出发地点错误。期望: #{@downtown_location}, 实际: #{@dropoff_transfer.location_from}"
        
        expect(@dropoff_transfer.location_to).to eq(@airport_location),
          "送机送达地点错误。期望: #{@airport_location}, 实际: #{@dropoff_transfer.location_to}"
      end
      
      # 断言9: 送机时间正确（第4天早上6:00）
      add_assertion "送机时间正确（第4天早上6:00）", weight: 7 do
        expected_time = @dropoff_flight_date.in_time_zone.change(hour: 6, min: 0)
        actual_time = @dropoff_transfer.pickup_datetime.in_time_zone
        
        # 比较Unix时间戳忽略时区差异
        expect(actual_time.to_i).to eq(expected_time.to_i),
          "送机时间错误。期望: #{expected_time.strftime('%Y-%m-%d %H:%M %Z')}（第4天早上6:00）, 实际: #{actual_time.strftime('%Y-%m-%d %H:%M %Z')}"
      end
      
      # 断言10: 联系人信息正确（张三）
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 5 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
    end
  end
end
