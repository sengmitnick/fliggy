# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例155: 给张三订明天上海1日跟团游，并订机场送机服务（后天早8:30从陆家嘴出发去浦东T2）
#
# 任务描述:
#   张三计划明天参加上海1日跟团游，并预订后天机场送机服务从陆家嘴金融区去浦东T2航站楼，后天早上8:30出发。
#   1. 上海1日跟团游（明天）
#   2. 机场送机服务（从陆家嘴金融区服务点接送至浦东T2航站楼，后天早上8:30出发）
#
# 任务分解步骤:
#   1. 查询上海1日跟团游产品（destination=上海，duration=1）
#   2. 创建跟团游订单（travel_date=明天，乘客=张三）
#   3. 查询Flight获取后天从上海浦东出发的航班，获取出发机场信息（含航站楼，如浦东T2）（送达地点）
#   4. 查询TransferLocation获取上海陆家嘴金融区服务点（location_type='other'，名称包含'陆家嘴'）（出发地点）
#   5. 创建送机服务订单（transfer_type=airport_dropoff，location_from=陆家嘴服务点，location_to=浦东T2，pickup_datetime=后天早上8:30）
#
# 复杂度分析（5个复杂点）：
#   1. 多模块组合：需要同时创建跟团游订单+送机服务订单（2个不同类型的订单）
#   2. 出发地点查询：需要从 TransferLocation 查询具体的出发地点（陆家嘴金融区，不使用笼统的"市区"）
#   3. 送达地点查询：需要从 Flight.departure_airport 获取准确的机场航站楼（用户说去浦东T2，就送到浦东T2）
#   4. 出发时间明确：用户指定后天早上8:30出发（这是送机服务的出发时间，不是航班起飞时间）
#   5. 航班关联（可选）：可关联具体航班号用于司机参考，但title/description不需要暴露航班信息
#
# 评分标准（总分100）：
#   1. 创建了跟团游订单（20分）
#   2. 城市正确=上海（10分）
#   3. 出发日期正确=明天（10分）
#   4. 创建了送机服务（20分）
#   5. 出发地点正确=陆家嘴金融区服务点（从 TransferLocation 动态获取）（15分）
#   6. 送达地点正确=浦东T2航站楼（从 Flight.departure_airport 动态获取）（15分）
#   7. 出发时间正确=后天早上8:30（10分）
#
# 使用方法:
#   rake validator:simulate_single[v155_book_tour_and_airport_dropoff_validator]
#

module V151V200
  class V155BookTourAndAirportDropoffValidator < BaseValidator
    self.validator_id = 'v155_book_tour_and_airport_dropoff_validator'
    self.task_id = 'e0f1a2b3-4c5d-6e7f-8a9b-0c1d2e3f4a6b'
    self.title = '给张三订明天上海1日跟团游，并订机场送机服务（后天早8:30从陆家嘴出发去浦东T2）'
    self.description = '给张三订明天上海1日跟团游，并订机场送机服务（后天早上8:30从陆家嘴金融区出发去浦东T2航站楼）'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.current + 1.day  # 明天游玩
      @flight_date = Date.current + 2.days  # 后天航班出发
      @city = '上海'
      @flight_destination = '北京'
      
      # 查询后天从上海浦东飞北京的航班（获取航班号、起飞时间、出发机场）
      @flight = Flight
        .where(departure_city: @city, destination_city: @flight_destination, data_version: 0)
        .where("departure_airport LIKE ?", "%浦东%")
        .to_a
        .find { |f| f.flight_date == @flight_date }
      
      raise "数据包缺少后天从#{@city}浦东飞#{@flight_destination}的航班" unless @flight
      
      # 从航班获取关键信息
      @flight_number = @flight.flight_number  # 航班号
      @flight_departure_time = @flight.departure_time  # 起飞时间
      @flight_departure_airport = @flight.departure_airport  # 出发机场（送达点=飞机在哪起飞就送到哪）
      
      # 查询TransferLocation获取上海陆家嘴金融区服务点（出发地点）
      @pickup_loc = TransferLocation.where(
        city: @city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('陆家嘴') }
      
      raise "数据包缺少上海陆家嘴TransferLocation" unless @pickup_loc
      
      @pickup_location = @pickup_loc.name  # 出发地点=陆家嘴金融区（从TransferLocation动态获取）
      
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
      
      # 设置送机时间（后天早上8:30）
      pickup_datetime = @flight_date.to_time.change(hour: 8, min: 30)
      
      # 创建机场送机服务（关联航班号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: @pickup_location,  # 出发地点=陆家嘴服务点（从TransferLocation动态获取）
        location_to: @flight_departure_airport,  # 送达地点=浦东T2（从Flight.departure_airport动态获取）
        pickup_datetime: pickup_datetime,  # 航班起飞前2小时
        flight_number: @flight_number,  # 关联航班号（从Flight动态获取）
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
        tour_date: @tour_date&.iso8601,
        flight_date: @flight_date&.iso8601,
        city: @city,
        pickup_location: @pickup_location,
        flight_departure_airport: @flight_departure_airport
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @tour_date = Date.parse(data['tour_date']) if data['tour_date']
      @flight_date = Date.parse(data['flight_date']) if data['flight_date']
      @city = data['city']
      @pickup_location = data['pickup_location']
      @flight_departure_airport = data['flight_departure_airport']
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
      add_assertion "创建了机场送机服务", weight: 20 do
        @transfer = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场送机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 出发地点正确=陆家嘴金融区服务点（从 TransferLocation 动态获取）
      add_assertion "出发地点正确（#{@pickup_location}，从TransferLocation动态获取）", weight: 15 do
        expect(@transfer.location_from).to eq(@pickup_location),
          "出发地点错误。期望: #{@pickup_location}（从TransferLocation动态获取）, 实际: #{@transfer.location_from}"
      end
      
      # 断言6: 送达地点正确=浦东T2航站楼（从 Flight.departure_airport 动态获取）
      add_assertion "送达地点正确（#{@flight_departure_airport}，从Flight.departure_airport动态获取）", weight: 15 do
        expect(@transfer.location_to).to eq(@flight_departure_airport),
          "送达地点错误。期望: #{@flight_departure_airport}（从Flight.departure_airport动态获取，应含航站楼如T2）, 实际: #{@transfer.location_to}"
      end
      
      # 断言7: 出发时间正确=后天早上8:30
      expected_pickup_time = @flight_date.to_time.change(hour: 8, min: 30)
      add_assertion "出发时间正确（后天早上8:30）", weight: 10 do
        expect(@transfer.pickup_datetime).to eq(expected_pickup_time),
          "出发时间错误。期望: #{expected_pickup_time.strftime('%Y-%m-%d %H:%M')}（后天早上8:30）, 实际: #{@transfer.pickup_datetime.strftime('%Y-%m-%d %H:%M')}"
      end
    end
  end
end
