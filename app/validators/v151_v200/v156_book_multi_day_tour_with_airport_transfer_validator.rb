# frozen_string_literal: true

require_relative '../base_validator'

# V156: 预订成都跟团游 + 机场往返接送服务（关联具体航班）
# 验证用户能够完成跟团游预订+机场往返接送服务的组合下单，接送机需关联具体航班

module V151V200
  class V156BookMultiDayTourWithAirportTransferValidator < BaseValidator
    self.validator_id = 'v156_book_multi_day_tour_with_airport_transfer_validator'
    self.task_id = 'f1a2b3c4-5d6e-7f8a-9b0c-1d2e3f4a5b7c'
    self.title = '给张三预订明天成都3日跟团游，并预订机场往返接送（接今天从上海飞来的航班，送第4天飞回上海的航班）'
    self.description = '给张三订明天成都3日跟团游，并订机场接机（接今天从上海飞成都的航班）和送机（送第4天从成都飞上海的航班）'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.current + 1.day  # 明天开始游玩
      @pickup_flight_date = Date.current  # 今天到达
      @dropoff_flight_date = Date.current + 3.days  # 第4天离开
      @city = '成都'
      @flight_origin = '上海'
      @airport_location = '成都双流国际机场'
      @duration_days = 3
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的成都3日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 3, data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少成都3日跟团游产品"
      
      # 查找今天从北京飞成都的航班（接机）
      @pickup_flights = Flight
        .where(departure_city: @flight_origin, destination_city: @city, data_version: 0)
        .where(flight_date: @pickup_flight_date)
        .where("arrival_airport LIKE ?", "%双流%")
        .to_a
      
      expect(@pickup_flights).not_to be_empty, "数据包缺少上海到成都的航班"
      
      # 查找第4天从成都飞上海的航班（送机）
      @dropoff_flights = Flight
        .where(departure_city: @city, destination_city: @flight_origin, data_version: 0)
        .where(flight_date: @dropoff_flight_date)
        .where("departure_airport LIKE ?", "%双流%")
        .to_a
      
      expect(@dropoff_flights).not_to be_empty, "数据包缺少成都到上海的航班"
      
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
      
      # 选择今天到达的航班
      pickup_flight = @pickup_flights.min_by { |f| f.arrival_time }
      raise "未找到可用的到达航班" unless pickup_flight
      
      # 计算接机时间（航班到达后30分钟）
      pickup_datetime = pickup_flight.arrival_time + 30.minutes
      
      # 创建机场接机服务（关联到达航班号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_location,
        location_to: "#{@city}市区",
        pickup_datetime: pickup_datetime,
        flight_number: pickup_flight.flight_number,
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
      
      # 选择第4天出发的航班
      dropoff_flight = @dropoff_flights.min_by { |f| f.departure_time }
      raise "未找到可用的出发航班" unless dropoff_flight
      
      # 计算送机时间（航班起飞前2小时）
      dropoff_datetime = dropoff_flight.departure_time - 2.hours
      
      # 创建机场送机服务（关联出发航班号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "#{@city}市区",
        location_to: @airport_location,
        pickup_datetime: dropoff_datetime,
        flight_number: dropoff_flight.flight_number,
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
      @duration_days = data['duration_days']
      
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 重新查询跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 3, data_version: 0)
        .to_a
      
      # 重新查询接机航班
      @pickup_flights = Flight
        .where(departure_city: @flight_origin, destination_city: @city, data_version: 0)
        .where(flight_date: @pickup_flight_date)
        .where("arrival_airport LIKE ?", "%双流%")
        .to_a
      
      # 重新查询送机航班
      @dropoff_flights = Flight
        .where(departure_city: @city, destination_city: @flight_origin, data_version: 0)
        .where(flight_date: @dropoff_flight_date)
        .where("departure_airport LIKE ?", "%双流%")
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
      
      # 断言8: 送机服务关联了具体航班号
      add_assertion "送机服务关联了具体航班号（#{@city}→#{@flight_origin}）", weight: 15 do
        expect(@dropoff_transfer.flight_number).not_to be_nil, "送机服务未关联航班号"
        
        # 验证航班号对应的航班确实是成都到北京
        flight = Flight.find_by(
          flight_number: @dropoff_transfer.flight_number,
          departure_city: @city,
          destination_city: @flight_origin,
          data_version: 0
        )
        
        expect(flight).not_to be_nil,
          "航班号#{@dropoff_transfer.flight_number}不是#{@city}到#{@flight_origin}的航班"
        
        # 验证出发机场是成都双流机场
        if flight
          expect(flight.departure_airport).to include('双流'),
            "航班出发机场错误。期望: 双流机场, 实际: #{flight.departure_airport}"
        end
      end
      
      # 断言9: 送机时间合理（航班起飞前1.5-2.5小时）
      add_assertion "送机时间合理（航班起飞前1.5-2.5小时）", weight: 7 do
        if @dropoff_transfer.flight_number.present?
          # 查询对应的航班（必须指定日期）
          flight = Flight
            .where(flight_number: @dropoff_transfer.flight_number, data_version: 0)
            .where(departure_city: @city, destination_city: @flight_origin)
            .where(flight_date: @dropoff_flight_date)
            .first
          
          if flight && flight.departure_time.present?
            time_before_flight = ((flight.departure_time - @dropoff_transfer.pickup_datetime) / 3600.0).round(1)
            is_reasonable = time_before_flight >= 1.5 && time_before_flight <= 2.5
            
            expect(is_reasonable).to be(true),
              "送机时间不合理。航班#{flight.departure_time.strftime('%H:%M')}起飞，" \
              "送机时间#{@dropoff_transfer.pickup_datetime.strftime('%H:%M')}，" \
              "提前#{time_before_flight}小时（应为1.5-2.5小时）"
          end
        end
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
