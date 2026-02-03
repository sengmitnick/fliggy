# frozen_string_literal: true

require_relative '../base_validator'

# V154: 预订北京跟团游 + 火车站接站服务
# 验证用户能够完成跟团游预订+火车站接站服务的组合下单

module V151V200
  class V154BookTourAndStationTransferValidator < BaseValidator
    self.validator_id = 'v154_book_tour_and_station_transfer_validator'
    self.task_id = 'd9e0f1a2-3b4c-5d6e-7f8a-9b0c1d2e3f4a'
    self.title = '预订跟团游并预订火车站接站服务（北京2日游）'
    self.description = '预订明天北京2日跟团游，并预订火车站接站服务'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.tomorrow
      @city = '北京'
      @station_location = '北京站'
      
      # 查找可用的北京2日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 2, data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少北京2日跟团游产品"
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
      
      # 创建火车站接站服务（早上）
      Transfer.create!(
        user: user,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @station_location,
        location_to: "#{@city}市区",
        pickup_datetime: @tour_date.in_time_zone + 7.hours,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 100.0,
        status: 'pending',
        data_version: @data_version
      )
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
      
      # 断言4: 创建了火车站接站服务
      add_assertion "创建了火车站接站服务", weight: 30 do
        @transfer = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站接站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 接站地点正确
      add_assertion "接站地点在北京", weight: 10 do
        in_city = @transfer.location_from.include?(@city) || @transfer.location_to.include?(@city)
        expect(in_city).to be(true),
          "接站地点错误。期望包含: #{@city}, 实际: #{@transfer.location_from} -> #{@transfer.location_to}"
      end
    end
  end
end
