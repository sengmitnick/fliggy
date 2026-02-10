# frozen_string_literal: true

require_relative '../base_validator'

# V155: 预订上海跟团游 + 机场送机服务（关联具体航班）
# 验证用户能够完成跟团游预订+机场送机服务的组合下单，送机需关联具体航班

module V151V200
  class V155BookTourAndAirportDropoffValidator < BaseValidator
    self.validator_id = 'v155_book_tour_and_airport_dropoff_validator'
    self.task_id = 'e0f1a2b3-4c5d-6e7f-8a9b-0c1d2e3f4a6b'
    self.title = '给张三预订明天上海1日跟团游，并预订机场送机（送后天从上海飞北京的航班）'
    self.description = '给张三订明天上海1日跟团游，并订机场送机服务（送后天从上海浦东飞北京的航班）'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.current + 1.day  # 明天游玩
      @flight_date = Date.current + 2.days  # 后天航班出发
      @city = '上海'
      @flight_destination = '北京'
      @dropoff_location = '上海浦东国际机场'
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的上海1日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 1, data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少上海1日跟团游产品"
      
      # 查找后天从上海浦东飞北京的航班
      @available_flights = Flight
        .where(departure_city: @city, destination_city: @flight_destination, data_version: 0)
        .where(flight_date: @flight_date)
        .where("departure_airport LIKE ?", "%浦东%")
        .to_a
      
      expect(@available_flights).not_to be_empty, "数据包缺少上海浦东飞北京的航班"
      
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
      
      # 选择后天出发的航班
      target_flight = @available_flights.min_by { |f| f.departure_time }
      raise "未找到可用航班" unless target_flight
      
      # 计算送机时间（航班起飞前2小时）
      pickup_datetime = target_flight.departure_time - 2.hours
      
      # 创建机场送机服务（关联航班号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "#{@city}市区",
        location_to: @dropoff_location,
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
        flight_destination: @flight_destination,
        dropoff_location: @dropoff_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @tour_date = Date.parse(data['tour_date']) if data['tour_date']
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @city = data['city']
      @flight_destination = data['flight_destination']
      @dropoff_location = data['dropoff_location']
      
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
        .where(departure_city: @city, destination_city: @flight_destination, data_version: 0)
        .where(flight_date: @flight_date)
        .where("departure_airport LIKE ?", "%浦东%")
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
      
      # 断言4: 创建了机场送机服务
      add_assertion "创建了机场送机服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场送机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 送机地点正确
      add_assertion "送机地点正确（#{@dropoff_location}）", weight: 5 do
        location_matches = (@transfer.location_to.include?('上海') && @transfer.location_to.include?('机场')) ||
                          (@transfer.location_to.include?('浦东') && @transfer.location_to.include?('机场'))
        expect(location_matches).to be(true),
          "送机地点错误。期望: #{@dropoff_location}, 实际: #{@transfer.location_to}"
      end
      
      # 断言6: 送机服务关联了具体航班号
      add_assertion "送机服务关联了具体航班号（#{@city}→#{@flight_destination}）", weight: 20 do
        expect(@transfer.flight_number).not_to be_nil, "送机服务未关联航班号"
        
        # 验证航班号对应的航班确实是上海浦东飞北京
        flight = Flight.find_by(
          flight_number: @transfer.flight_number,
          departure_city: @city,
          destination_city: @flight_destination,
          data_version: 0
        )
        
        expect(flight).not_to be_nil,
          "航班号#{@transfer.flight_number}不是#{@city}到#{@flight_destination}的航班"
        
        # 验证出发机场是浦东机场
        if flight
          expect(flight.departure_airport).to include('浦东'),
            "航班出发机场错误。期望: 浦东机场, 实际: #{flight.departure_airport}"
        end
      end
      
      # 断言7: 送机时间合理（航班起飞前1.5-2.5小时）
      add_assertion "送机时间合理（航班起飞前1.5-2.5小时）", weight: 15 do
        if @transfer.flight_number.present?
          # 查询对应的航班（必须指定日期）
          flight = Flight
            .where(flight_number: @transfer.flight_number, data_version: 0)
            .where(departure_city: @city, destination_city: @flight_destination)
            .where(flight_date: @flight_date)
            .first
          
          if flight && flight.departure_time.present?
            time_before_flight = ((flight.departure_time - @transfer.pickup_datetime) / 3600.0).round(1)
            is_reasonable = time_before_flight >= 1.5 && time_before_flight <= 2.5
            
            expect(is_reasonable).to be(true),
              "送机时间不合理。航班#{flight.departure_time.strftime('%H:%M')}起飞，" \
              "送机时间#{@transfer.pickup_datetime.strftime('%H:%M')}，" \
              "提前#{time_before_flight}小时（应为1.5-2.5小时）"
          end
        end
      end
      
      # 断言8: 联系人信息正确（#{@expected_contact_name}）
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 5 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
    end
  end
end
