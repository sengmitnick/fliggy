# frozen_string_literal: true

require_relative '../base_validator'

# V157BookTourWithStationDropoffValidator
# 验证用例157: 给张三1成人明天深圳2日跟团游，并订火车站送站服务（后天早上6:30从福田中心区会展中心接送服务点送到深圳北站西广场接送中心）
#
# 任务描述:
#   张三计划明天开始深圳2日跟团游，需要火车站送站服务：后天早上6:30从福田中心区会展中心接送服务点出发，送到深圳北站西广场接送中心。
#   1. 深圳2日跟团游（明天出发，1成人）
#   2. 火车站送站服务（后天早上6:30从福田中心区会展中心接送服务点出发，送到深圳北站西广场接送中心）
#
# 任务分解步骤:
#   1. 查询深圳2日跟团游产品（destination=深圳，duration=2，travel_type=跟团游）
#   2. 创建跟团游订单（出发日期=明天，成人1人，联系人=张三）
#   3. 从TransferLocation获取福田中心区会展中心接送服务点（市区出发地）
#   4. 从TransferLocation获取深圳北站西广场接送中心（火车站送达地）
#   5. 创建火车站送站服务（后天早上6:30从福田中心区会展中心接送服务点出发，送至深圳北站西广场接送中心，不关联火车班次号）
#
# 评分标准（总分100分）:
#   1. 创建了跟团游订单 (20分)
#   2. 城市正确（深圳） (10分)
#   3. 创建了火车站送站服务 (15分)
#   4. 送站服务地点正确（福田中心区会展中心→深圳北站西广场） (25分)
#   5. 送站时间正确（后天早上6:30） (20分)
#   6. 联系人信息正确（张三） (10分)

module V151V200
  class V157BookTourWithStationDropoffValidator < BaseValidator
    self.validator_id = 'v157_book_tour_with_station_dropoff_validator'
    self.task_id = 'a2b3c4d5-6e7f-8a9b-0c1d-2e3f4a5b6c8d'
    self.title = '给张三1成人明天深圳2日跟团游，并订火车站送站服务（后天早上6:30从福田中心区会展中心接送服务点送到深圳北站西广场接送中心）'
    self.description = '给张三1成人明天深圳2日跟团游，并订火车站送站服务（后天早上6:30从福田中心区会展中心接送服务点送到深圳北站西广场接送中心）'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.current + 1.day  # 明天开始游玩
      @train_date = Date.current + 2.days  # 后天送站
      @city = '深圳'
      @train_destination = '广州'
      @duration_days = 2
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的深圳2日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 2, travel_type: '跟团游', data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少深圳2日跟团游产品"
      
      # 查询TransferLocation获取深圳市区接送服务点（出发地）
      @downtown_loc = TransferLocation.where(
        city: @city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('福田') && loc.name.include?('会展中心') }
      
      raise "数据包缺少深圳市区接送服务点TransferLocation" unless @downtown_loc
      
      @downtown_location = @downtown_loc.name  # 福田中心区会展中心接送服务点（从TransferLocation动态获取）
      
      # 查询TransferLocation获取深圳北站接送服务点（送达地）
      @station_loc = TransferLocation.where(
        city: @city,
        location_type: 'train_station',
        data_version: 0
      ).find { |loc| loc.name.include?('北站') && loc.name.include?('西广场') }
      
      raise "数据包缺少深圳北站接送服务点TransferLocation" unless @station_loc
      
      @station_location = @station_loc.name  # 深圳北站西广场接送中心（从TransferLocation动态获取）
      
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
      
      # 计算送站时间（后天早上6:30）
      pickup_datetime = @train_date.in_time_zone.change(hour: 6, min: 30)
      
      # 创建火车站送站服务（从福田中心区会展中心送到深圳北站，不关联火车班次号）
      Transfer.create!(
        user: user,
        transfer_package_id: @best_package.id,
        transfer_type: 'train_dropoff',
        service_type: 'to_station',
        location_from: @downtown_location,  # 福田中心区会展中心接送服务点（从TransferLocation动态获取）
        location_to: @station_location,  # 深圳北站西广场接送中心（从TransferLocation动态获取）
        pickup_datetime: pickup_datetime,
        train_number: nil,  # 送站服务不关联火车班次号
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
        train_date: @train_date.to_s,
        city: @city,
        train_destination: @train_destination,
        downtown_location: @downtown_location,
        station_location: @station_location,
        duration_days: @duration_days
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @tour_date = Date.parse(data['tour_date']) if data['tour_date']
      @train_date = Date.parse(data['train_date']) if data['train_date']
      @city = data['city']
      @train_destination = data['train_destination']
      @downtown_location = data['downtown_location']
      @station_location = data['station_location']
      @duration_days = data['duration_days']
      
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 重新查询跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 2, travel_type: '跟团游', data_version: 0)
        .to_a
      
      # 重新查询TransferLocation
      @downtown_loc = TransferLocation.where(
        city: @city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('福田') && loc.name.include?('会展中心') }
      
      @downtown_location = @downtown_loc.name if @downtown_loc
      
      @station_loc = TransferLocation.where(
        city: @city,
        location_type: 'train_station',
        data_version: 0
      ).find { |loc| loc.name.include?('北站') && loc.name.include?('西广场') }
      
      @station_location = @station_loc.name if @station_loc
      
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
      
      # 断言3: 创建了火车站送站服务
      add_assertion "创建了火车站送站服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'train_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站送站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言4: 送站服务地点正确（福田中心区会展中心→深圳北站西广场）
      add_assertion "送站服务地点正确（#{@downtown_location}→#{@station_location}）", weight: 25 do
        expect(@transfer.location_from).to eq(@downtown_location),
          "送站出发地错误。期望: #{@downtown_location}, 实际: #{@transfer.location_from}"
        
        expect(@transfer.location_to).to eq(@station_location),
          "送站目的地错误。期望: #{@station_location}, 实际: #{@transfer.location_to}"
      end
      
      # 断言5: 送站时间正确（后天早上6:30）
      add_assertion "送站时间正确（后天早上6:30）", weight: 20 do
        expected_time = @train_date.in_time_zone.change(hour: 6, min: 30)
        actual_time = @transfer.pickup_datetime.in_time_zone
        
        # 比较Unix时间戳忽略时区差异
        expect(actual_time.to_i).to eq(expected_time.to_i),
          "送站时间错误。期望: #{expected_time.strftime('%Y-%m-%d %H:%M %Z')}（后天早上6:30）, 实际: #{actual_time.strftime('%Y-%m-%d %H:%M %Z')}"
      end
      
      # 断言6: 联系人信息正确（张三）
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
    end
  end
end
