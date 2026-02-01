# frozen_string_literal: true

require_relative '../base_validator'

# V147: 预订广州酒店套餐1晚 + 机场往返接送服务
# 验证用户能够完成酒店套餐预订+机场往返接送的组合下单

module V101V150
  class V147BookHotelPackageWithCityTransferValidator < BaseValidator
    self.validator_id = 'v147_book_hotel_package_with_city_transfer_validator'
    self.task_id = 'b7c8d9e0-1f2a-3b4c-5d6e-7f8a9b0c1d2e'
    self.title = '预订酒店套餐后预订机场往返接送服务（广州1晚）'
    self.description = '预订明天广州酒店套餐1晚，并预订机场往返接送服务（接机+送机）'
    self.timeout_seconds = 300

    def prepare
      @checkin_date = Date.tomorrow
      @nights = 1
      @city = '广州'
      @pickup_location = '广州白云国际机场'
      @dropoff_location = '广州白云国际机场'
      
      # 查找可用的1晚酒店套餐
      @available_packages = HotelPackage
        .where(city: @city, data_version: 0)
        .where(night_count: @nights)
        .to_a
      
      expect(@available_packages).not_to be_empty, "数据包缺少广州1晚酒店套餐"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(phone: '13800138000', data_version: 0)
      package = @available_packages.first
      option = package.package_options.first
      
      # 创建酒店套餐订单
      HotelPackageOrder.create!(
        user: user,
        hotel_package: package,
        hotel_id: package.hotel.id,
        package_option: option,
        passenger_id: passenger.id,
        contact_name: user.name,
        contact_phone: '13800138000',
        check_in_date: @checkin_date,
        check_out_date: @checkin_date + @nights.days,
        total_price: option.price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 创建机场接机服务
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @pickup_location,
        location_to: "#{@city}市区",
        pickup_datetime: @checkin_date.in_time_zone + 10.hours,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 150.0,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建机场送机服务（退房当天）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "#{@city}市区",
        location_to: @dropoff_location,
        pickup_datetime: (@checkin_date + @nights.days).in_time_zone + 14.hours,
        vehicle_type: 'business_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 150.0,
        status: 'pending',
        data_version: @data_version
      )
    end

    def verify
      # 断言1: 创建了酒店套餐订单
      add_assertion "创建了酒店套餐订单", weight: 30 do
        all_orders = HotelPackageOrder
          .joins(:hotel_package)
          .includes(:hotel_package, :package_option)
          .where(hotel_packages: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何酒店套餐订单"
        
        @hotel_package_order = all_orders.first
      end
      
      return if @hotel_package_order.nil?
      
      # 断言2: 城市正确
      add_assertion "城市正确（#{@city}）", weight: 15 do
        expect(@hotel_package_order.hotel_package.city).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@hotel_package_order.hotel_package.city}"
      end
      
      # 断言3: 入住日期正确
      add_assertion "入住日期正确（#{@checkin_date}）", weight: 10 do
        expect(@hotel_package_order.check_in_date).to eq(@checkin_date),
          "入住日期错误。期望: #{@checkin_date}（明天）, 实际: #{@hotel_package_order.check_in_date}"
      end
      
      # 断言4: 住宿晚数正确
      add_assertion "住宿晚数正确（#{@nights}晚）", weight: 10 do
        actual_nights = (@hotel_package_order.check_out_date - @hotel_package_order.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿晚数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      # 断言5: 创建了机场接送服务（往返）
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
      
      # 断言6: 接机服务时间在入住当天
      add_assertion "接机服务时间在入住当天", weight: 10 do
        transfer_date = @pickup_transfer.pickup_datetime.to_date
        expect(transfer_date).to eq(@checkin_date),
          "接机服务时间错误。期望: #{@checkin_date}（入住当天）, 实际: #{transfer_date}"
      end
    end
  end
end
