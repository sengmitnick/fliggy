# frozen_string_literal: true

require_relative '../base_validator'

# V156: 预订成都跟团游 + 机场往返接送服务
# 验证用户能够完成跟团游预订+机场往返接送服务的组合下单

module V151V200
  class V156BookMultiDayTourWithAirportTransferValidator < BaseValidator
    self.validator_id = 'v156_book_multi_day_tour_with_airport_transfer_validator'
    self.task_id = 'f1a2b3c4-5d6e-7f8a-9b0c-1d2e3f4a5b6c'
    self.title = '预订跟团游并预订机场往返接送服务（成都3日游）'
    self.description = '预订明天成都3日跟团游，并预订机场往返接送服务（接机+送机）'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.tomorrow
      @city = '成都'
      @airport_location = '成都双流国际机场'
      @duration_days = 3
      
      # 查找可用的成都3日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 3, data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少成都3日跟团游产品"
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
        contact_name: user.name,
        contact_phone: '13800138000',
        total_price: tour_package.price * 2,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建机场接机服务（第一天）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_location,
        location_to: "#{@city}市区",
        pickup_datetime: @tour_date.in_time_zone + 9.hours,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 120.0,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建机场送机服务（最后一天）
      end_date = @tour_date + (@duration_days - 1).days
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "#{@city}市区",
        location_to: @airport_location,
        pickup_datetime: end_date.in_time_zone + 18.hours,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 120.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        tour_date: @tour_date.to_s,
        city: @city,
        airport_location: @airport_location,
        duration_days: @duration_days
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @tour_date = Date.parse(data['tour_date']) if data['tour_date']
      @city = data['city']
      @airport_location = data['airport_location']
      @duration_days = data['duration_days']
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
      add_assertion "城市正确（#{@city}）", weight: 15 do
        expect(@tour_booking.tour_group_product.destination).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      # 断言3: 出发日期正确
      add_assertion "出发日期正确（#{@tour_date}）", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@tour_date),
          "出发日期错误。期望: #{@tour_date}（明天）, 实际: #{@tour_booking.travel_date}"
      end
      
      # 断言4: 成人数量=2
      add_assertion "成人数量=2", weight: 10 do
        expect(@tour_booking.adult_count).to eq(2),
          "成人数量错误。期望: 2, 实际: #{@tour_booking.adult_count}"
      end
      
      # 断言5: 创建了机场往返接送服务
      add_assertion "创建了机场往返接送服务（接机+送机）", weight: 25 do
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
      
      # 断言6: 接机时间在第一天
      add_assertion "接机时间在第一天", weight: 10 do
        transfer_date = @pickup_transfer.pickup_datetime.to_date
        expect(transfer_date).to eq(@tour_date),
          "接机时间错误。期望: #{@tour_date}（第一天）, 实际: #{transfer_date}"
      end
      
      # 断言7: 送机时间在最后一天（第3天）
      add_assertion "送机时间在最后一天（第#{@duration_days}天）", weight: 10 do
        expected_return_date = @tour_date + (@duration_days - 1).days
        transfer_date = @dropoff_transfer.pickup_datetime.to_date
        expect(transfer_date).to eq(expected_return_date),
          "送机时间错误。期望: #{expected_return_date}（第#{@duration_days}天）, 实际: #{transfer_date}"
      end
    end
  end
end
