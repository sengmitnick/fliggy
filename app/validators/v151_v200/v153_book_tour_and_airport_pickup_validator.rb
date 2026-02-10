# frozen_string_literal: true

require_relative '../base_validator'

# V153: 预订广州跟团游 + 机场接机服务（关联具体航班）
# 验证用户能够完成跟团游预订+机场接机服务的组合下单，接机需关联具体航班

module V151V200
  class V153BookTourAndAirportPickupValidator < BaseValidator
    self.validator_id = 'v153_book_tour_and_airport_pickup_validator'
    self.task_id = 'c8d9e0f1-2a3b-4c5d-6e7f-8a9b0c1d2e4f'
    self.title = '给张三预订明天广州1日跟团游，并预订机场接机（接今天从北京飞来的航班）'
    self.description = '给张三订明天广州市内1日跟团游，并订机场接机服务（接今天从北京飞来的航班）'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.current + 1.day  # 明天游玩
      @flight_date = Date.current  # 今天飞机到达
      @city = '广州'
      @flight_origin = '北京'
      @pickup_location = '广州白云国际机场'
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的广州1日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 1, data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少广州1日跟团游产品"
      
      # 查找今天从北京飞广州白云机场的航班
      @available_flights = Flight
        .where(departure_city: @flight_origin, destination_city: @city, data_version: 0)
        .where(flight_date: @flight_date)
        .where("arrival_airport LIKE ?", "%白云%")
        .to_a
      
      expect(@available_flights).not_to be_empty, "数据包缺少北京到广州白云机场的航班"
      
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
        adult_count: 1,
        child_count: 0,
        contact_name: @passenger.name,
        contact_phone: @passenger.phone,
        total_price: tour_package.price,
        status: 'pending',
        data_version: @data_version
      )
      
      # 选择今天到达的航班
      target_flight = @available_flights.min_by { |f| f.arrival_time }
      raise "未找到可用航班" unless target_flight
      
      # 计算接机时间（航班到达后30分钟）
      pickup_datetime = target_flight.arrival_time + 30.minutes
      
      # 创建机场接机服务（关联航班号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @pickup_location,
        location_to: "#{@city}市区",
        pickup_datetime: pickup_datetime,
        flight_number: target_flight.flight_number,  # 关键：关联航班号
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        passenger_count: 1,
        luggage_count: 1,
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
        flight_date: @flight_date.to_s,
        city: @city,
        flight_origin: @flight_origin,
        pickup_location: @pickup_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @tour_date = Date.parse(data['tour_date']) if data['tour_date']
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @city = data['city']
      @flight_origin = data['flight_origin']
      @pickup_location = data['pickup_location']
      
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 重新查询跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 1, data_version: 0)
        .to_a
      
      # 重新查询航班
      @available_flights = Flight
        .where(departure_city: @flight_origin, destination_city: @city, data_version: 0)
        .where(flight_date: @flight_date)
        .where("arrival_airport LIKE ?", "%白云%")
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
      add_assertion "创建了跟团游订单", weight: 20 do
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
      
      # 断言4: 成人数量正确
      add_assertion "成人数量=1", weight: 5 do
        expect(@tour_booking.adult_count).to eq(1),
          "成人数量错误。期望: 1, 实际: #{@tour_booking.adult_count}"
      end
      
      # 断言5: 创建了机场接机服务
      add_assertion "创建了机场接机服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场接机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言6: 接机地点正确
      add_assertion "接机地点正确（#{@pickup_location}）", weight: 5 do
        location_matches = (@transfer.location_from.include?('广州') && @transfer.location_from.include?('机场')) ||
                          (@transfer.location_from.include?('白云') && @transfer.location_from.include?('机场'))
        expect(location_matches).to be(true),
          "接机地点错误。期望: #{@pickup_location}, 实际: #{@transfer.location_from}"
      end
      
      # 断言7: 接机服务关联了具体航班号
      add_assertion "接机服务关联了具体航班号（#{@flight_origin}→#{@city}）", weight: 20 do
        expect(@transfer.flight_number).not_to be_nil, "接机服务未关联航班号"
        
        # 验证航班号对应的航班确实是北京到广州白云机场
        flight = Flight.find_by(
          flight_number: @transfer.flight_number,
          departure_city: @flight_origin,
          destination_city: @city,
          data_version: 0
        )
        
        expect(flight).not_to be_nil,
          "航班号#{@transfer.flight_number}不是#{@flight_origin}到#{@city}的航班"
        
        # 验证目的地机场是白云机场
        if flight
          expect(flight.arrival_airport).to include('白云'),
            "航班目的地机场错误。期望: 白云机场, 实际: #{flight.arrival_airport}"
        end
      end
      
      # 断言8: 接机时间合理（航班到达后30分钟内）
      add_assertion "接机时间合理（航班到达后30分钟内）", weight: 10 do
        if @transfer.flight_number.present?
          # 查询对应的航班（必须指定日期）
          flight = Flight
            .where(flight_number: @transfer.flight_number, data_version: 0)
            .where(departure_city: @flight_origin, destination_city: @city)
            .where(flight_date: @flight_date)
            .first
          
          if flight && flight.arrival_time.present?
            time_after_arrival = ((@transfer.pickup_datetime - flight.arrival_time) / 60.0).round
            is_reasonable = time_after_arrival >= 20 && time_after_arrival <= 40
            
            expect(is_reasonable).to be(true),
              "接机时间不合理。航班#{flight.arrival_time.strftime('%H:%M')}到达，" \
              "接机时间#{@transfer.pickup_datetime.strftime('%H:%M')}，" \
              "间隔#{time_after_arrival}分钟（应为20-40分钟）"
          end
        end
      end
      
      # 断言9: 联系人信息正确（张三）
      add_assertion "联系人信息正确（张三）", weight: 5 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
    end
  end
end
