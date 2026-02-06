# frozen_string_literal: true

require_relative '../base_validator'

# V157: 预订深圳跟团游 + 火车站送站服务
# 验证用户能够完成跟团游预订+火车站送站服务的组合下单

module V151V200
  class V157BookTourWithStationDropoffValidator < BaseValidator
    self.validator_id = 'v157_book_tour_with_station_dropoff_validator'
    self.task_id = 'a2b3c4d5-6e7f-8a9b-0c1d-2e3f4a5b6c8d'
    self.title = '预订跟团游并预订火车站送站服务（深圳2日游）'
    self.description = '预订明天深圳2日跟团游，并预订第二天结束后的火车站送站服务'
    self.timeout_seconds = 300

    def prepare
      @tour_date = Date.tomorrow
      @city = '深圳'
      @station_location = '深圳北站'
      @duration_days = 2
      
      # 查找可用的深圳2日跟团游
      @available_tours = TourGroupProduct
        .where(destination: @city, duration: 2, data_version: 0)
        .to_a
      
      expect(@available_tours).not_to be_empty, "数据包缺少深圳2日跟团游产品"
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
      
      # 创建火车站送站服务（最后一天）
      end_date = @tour_date + (@duration_days - 1).days
      Transfer.create!(
        user: user,
        transfer_type: 'train_dropoff',
        service_type: 'to_station',
        pickup_datetime: end_date.in_time_zone + 17.hours,
        location_from: "#{@city}市区",
        location_to: @station_location,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 100.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        tour_date: @tour_date.to_s,
        city: @city,
        station_location: @station_location,
        duration_days: @duration_days
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @tour_date = Date.parse(data['tour_date']) if data['tour_date']
      @city = data['city']
      @station_location = data['station_location']
      @duration_days = data['duration_days']
    end

    def verify
      # 断言1: 创建了跟团游订单
      add_assertion "创建了跟团游订单", weight: 25 do
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
      
      # 断言4: 创建了火车站送站服务
      add_assertion "创建了火车站送站服务", weight: 25 do
        @transfer = Transfer
          .where(transfer_type: 'train_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站送站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 送站时间在最后一天（第2天）
      add_assertion "送站时间在最后一天（第#{@duration_days}天）", weight: 15 do
        expected_dropoff_date = @tour_date + (@duration_days - 1).days
        transfer_date = @transfer.pickup_datetime.to_date
        expect(transfer_date).to eq(expected_dropoff_date),
          "送站时间错误。期望: #{expected_dropoff_date}（第#{@duration_days}天）, 实际: #{transfer_date}"
      end
      
      # 断言6: 送站地点正确（市区→火车站）
      add_assertion "送站地点正确（市区→火车站）", weight: 10 do
        expect(@transfer.location_from).to include("#{@city}市区"),
          "送站出发地错误。期望: #{@city}市区, 实际: #{@transfer.location_from}"
        expect(@transfer.location_to).to include(@city),
          "送站目的地错误。期望包含: #{@city}, 实际: #{@transfer.location_to}"
      end
    end
  end
end
