# frozen_string_literal: true

require_relative '../base_validator'

# V155: 预订上海跟团游 + 机场送机服务
# 验证用户能够完成跟团游预订+机场送机服务的组合下单

module V151V200
  class V155BookTourAndAirportDropoffValidator < BaseValidator
    self.validator_id = 'v155_book_tour_and_airport_dropoff_validator'
    self.task_id = 'e0f1a2b3-4c5d-6e7f-8a9b-0c1d2e3f4a6b'
    self.title = '预订跟团游并预订机场送机服务（上海1日游）'
    self.description = '预订明天上海1日跟团游，并预订当天结束后的机场送机服务'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.tomorrow
      @city = '上海'
      @dropoff_location = '上海浦东国际机场'
      
      # 查找可用的上海1日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 1, data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少上海1日跟团游产品"
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
        contact_name: user.name,
        contact_phone: '13800138000',
        total_price: tour_package.price,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建机场送机服务（游览结束后）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "#{@city}市区",
        location_to: @dropoff_location,
        pickup_datetime: @tour_date.in_time_zone + 18.hours,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 150.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        tour_date: @tour_date.to_s,
        city: @city,
        dropoff_location: @dropoff_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @tour_date = Date.parse(data['tour_date']) if data['tour_date']
      @city = data['city']
      @dropoff_location = data['dropoff_location']
    end

    def verify
      # 断言1: 创建了跟团游订单
      add_assertion "创建了跟团游订单", weight: 30 do
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
      add_assertion "出发日期正确（#{@tour_date}）", weight: 15 do
        expect(@tour_booking.travel_date).to eq(@tour_date),
          "出发日期错误。期望: #{@tour_date}（明天）, 实际: #{@tour_booking.travel_date}"
      end
      
      # 断言4: 创建了机场送机服务
      add_assertion "创建了机场送机服务", weight: 30 do
        @transfer = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场送机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 送机地点正确
      add_assertion "送机地点正确（#{@dropoff_location}）", weight: 10 do
        expect(@transfer.location_to).to eq(@dropoff_location),
          "送机地点错误。期望: #{@dropoff_location}, 实际: #{@transfer.location_to}"
      end
    end
  end
end
