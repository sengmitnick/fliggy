# frozen_string_literal: true

require_relative '../base_validator'

# V153BookTourAndAirportPickupValidator
# 验证用例153: 给张三订明天广州市内2日跟团游,并订机场接机服务(接今天从北京飞来的航班,CZ3100早上10:45到白云T2,送到珠江新城CBD)
#
# 任务描述:
#   张三计划明天参加广州市内2日跟团游,并预订机场接机服务接今天从北京飞来的航班(CZ3100,早上10:45到达白云T2,送到珠江新城CBD)。
#   1. 广州市内2日跟团游(明天出发)
#   2. 机场接机服务(从白云T2接机,送至珠江新城CBD,接今天从北京飞来的CZ3100,航班10:45到达)
#
# 任务分解步骤:
#   1. 查询广州2日跟团游产品(destination=广州,duration=2,travel_type=跟团游)
#   2. 创建跟团游订单(出发日期=明天,成人1人,联系人=张三)
#   3. 查询Flight获取今天从北京到广州白云机场的航班,确定航班号、到达时间、到达机场
#   4. 查询TransferPackage获取舒适型5座套餐(vehicle_category='comfort_5')
#   5. 创建接机服务订单(transfer_type=airport_pickup,flight_number=航班号,location_from=航班到达机场,location_to=送达地点,pickup_datetime=航班到达后30分钟)
#
# 复杂度分析(6个复杂点):
#   1. 多模块组合:需要同时创建跟团游订单+接机服务订单(2个不同类型的订单)
#   2. 航班信息查询:需要从 Flight 模型查询从北京飞来的航班信息(flight_number、arrival_time、arrival_airport)
#   3. 接机地点查询:需要从 Flight 模型获取具体的接机地点(arrival_airport,不使用笼统的"机场")
#   4. 车型套餐选择:需要查询舒适型5座套餐(vehicle_category='comfort_5')
#   5. 时间计算:接机时间=航班到达后30分钟
#   6. 跨日期协调:跟团游明天,接机服务今天
#
# 评分标准(总计100):
#   1. 创建了跟团游订单(20分)
#   2. 城市正确=广州(10分)
#   3. 出发日期正确=明天(10分)
#   4. 成人数量=1(5分)
#   5. 创建了机场接机服务(15分)
#   6. 接机地点正确=白云T2(从 Flight.arrival_airport 动态获取)(8分)
#   7. 送达地点正确=珠江新城CBD(从 TransferLocation 动态获取)(10分)
#   8. 接机服务关联了具体航班号(从北京来的航班)(10分)
#   9. 接机时间合理(航班到达后20-40分钟)(12分)
#
# 使用方法:
#   rake validator:simulate_single[v153_book_tour_and_airport_pickup_validator]
#

module V151V200
  class V153BookTourAndAirportPickupValidator < BaseValidator
    self.validator_id = 'v153_book_tour_and_airport_pickup_validator'
    self.task_id = 'c8d9e0f1-2a3b-4c5d-6e7f-8a9b0c1d2e4f'
    self.title = '给张三订明天广州市内2日跟团游,并订机场接机服务(接今天从北京飞来的航班,CZ3100早上10:45到白云T2,送到珠江新城CBD)'
    self.description = '给张三订明天广州市内2日跟团游,并订机场接机服务(接今天从北京飞来的CZ3100航班,早上10:45到达白云T2,送到珠江新城CBD)'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.current + 1.day  # 明天游玩
      @flight_date = Date.current  # 今天飞机到达
      @city = '广州'
      @flight_origin = '北京'
      
      # 查询今天从北京到广州白云机场的航班(获取航班号、到达时间、到达机场)
      @flight = Flight
        .where(departure_city: @flight_origin, destination_city: @city, data_version: 0)
        .where(flight_date: @flight_date)
        .where("arrival_airport LIKE ?", "%白云%")
        .order(:arrival_time)
        .first
      
      raise "数据包缺少今天从#{@flight_origin}到#{@city}白云机场的航班" unless @flight
      
      # 从航班获取关键信息
      @flight_number = @flight.flight_number  # 航班号
      @flight_arrival_time = @flight.arrival_time  # 到达时间
      @flight_arrival_airport = @flight.arrival_airport  # 到达机场(接机点=飞机在哪降落就在哪接)
      
      # 查询TransferLocation获取广州珠江新城CBD服务点（送达地点）
      @dropoff_loc = TransferLocation.where(
        city: @city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('珠江新城') }
      
      raise "数据包缺少广州珠江新城CBDTransferLocation" unless @dropoff_loc
      
      @dropoff_location = @dropoff_loc.name  # 送达地点（从TransferLocation动态获取）
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的广州2日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 2, travel_type: '跟团游', data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少广州2日跟团游产品"
      
      # 查找舒适型5座套餐
      @available_packages = TransferPackage.where(
        vehicle_category: 'comfort_5',
        data_version: 0
      ).order(:price)
      
      expect(@available_packages).not_to be_empty, "未找到舒适型5座套餐"
      
      @best_package = @available_packages.first
      
      {
        tour_date: @tour_date.to_s,
        flight_date: @flight_date.to_s,
        city: @city,
        flight_origin: @flight_origin,
        flight_number: @flight_number,
        flight_arrival_time: @flight_arrival_time.to_s,
        flight_arrival_airport: @flight_arrival_airport,
        dropoff_location: @dropoff_location,
        available_tours_count: @available_tours.size
      }
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
      
      # 计算接机时间(航班到达后30分钟)
      pickup_datetime = @flight_arrival_time + 30.minutes
      
      # 创建机场接机服务(关联航班号)
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @flight_arrival_airport,  # 从 Flight.arrival_airport 动态获取
        location_to: @dropoff_location,  # 从 TransferLocation 动态获取
        pickup_datetime: pickup_datetime,
        flight_number: @flight_number,  # 关键:关联航班号
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
        flight_number: @flight_number,
        flight_arrival_airport: @flight_arrival_airport,
        dropoff_location: @dropoff_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @tour_date = Date.parse(data['tour_date']) if data['tour_date']
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @city = data['city']
      @flight_origin = data['flight_origin']
      @flight_number = data['flight_number']
      @flight_arrival_airport = data['flight_arrival_airport']
      @dropoff_location = data['dropoff_location']
      
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 重新查询跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 2, travel_type: '跟团游', data_version: 0)
        .to_a
      
      # 重新查询航班
      @flight = Flight.find_by(
        flight_number: @flight_number,
        departure_city: @flight_origin,
        destination_city: @city,
        data_version: 0
      )
      
      @flight_arrival_time = @flight.arrival_time if @flight
      
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
      add_assertion "城市正确(#{@city})", weight: 10 do
        expect(@tour_booking.tour_group_product.destination).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      # 断言3: 出发日期正确
      add_assertion "出发日期正确(#{@tour_date})", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@tour_date),
          "出发日期错误。期望: #{@tour_date}(明天), 实际: #{@tour_booking.travel_date}"
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
      
      # 断言6: 接机地点正确(从 Flight.arrival_airport 动态获取)
      add_assertion "接机地点正确(#{@flight_arrival_airport},从Flight.arrival_airport动态获取)", weight: 8 do
        expect(@transfer.location_from).to eq(@flight_arrival_airport),
          "接机地点错误。期望: #{@flight_arrival_airport}(从Flight.arrival_airport获取), 实际: #{@transfer.location_from}"
      end
      
      # 断言7: 送达地点正确(从 TransferLocation 动态获取)
      add_assertion "送达地点正确(#{@dropoff_location},从TransferLocation动态获取)", weight: 10 do
        expect(@transfer.location_to).to eq(@dropoff_location),
          "送达地点错误。期望: #{@dropoff_location}(从TransferLocation动态获取), 实际: #{@transfer.location_to}"
      end
      
      # 断言8: 接机服务关联了具体航班号
      add_assertion "接机服务关联了具体航班号(#{@flight_origin}→#{@city})", weight: 10 do
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
      
      # 断言9: 接机时间合理(航班到达后20-40分钟)
      add_assertion "接机时间合理(航班到达后20-40分钟)", weight: 12 do
        if @transfer.flight_number.present?
          # 查询对应的航班(必须指定日期)
          flight = Flight
            .where(flight_number: @transfer.flight_number, data_version: 0)
            .where(departure_city: @flight_origin, destination_city: @city)
            .where(flight_date: @flight_date)
            .first
          
          if flight && flight.arrival_time.present?
            time_after_arrival = ((@transfer.pickup_datetime - flight.arrival_time) / 60.0).round
            is_reasonable = time_after_arrival >= 20 && time_after_arrival <= 40
            
            expect(is_reasonable).to be(true),
              "接机时间不合理。航班#{flight.arrival_time.strftime('%H:%M')}到达," \
              "接机时间#{@transfer.pickup_datetime.strftime('%H:%M')}," \
              "间隔#{time_after_arrival}分钟(应为20-40分钟)"
          end
        end
      end
    end
  end
end
