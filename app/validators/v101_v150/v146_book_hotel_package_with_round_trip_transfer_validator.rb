# frozen_string_literal: true

require_relative '../base_validator'

# V146: 预订深圳酒店套餐2晚 + 往返机场接送服务
# 验证用户能够完成酒店套餐预订+往返机场接送服务的组合下单

module V101V150
  class V146BookHotelPackageWithRoundTripTransferValidator < BaseValidator
    self.validator_id = 'v146_book_hotel_package_with_round_trip_transfer_validator'
    self.task_id = 'a6b7c8d9-0e1f-2a3b-4c5d-6e7f8a9b0c1d'
    self.title = '预订明天酒店套餐后预订往返接送服务（深圳2晚）'
    self.description = '预订明天深圳酒店套餐2晚，并预订往返机场接送服务（接机+送机）'
    self.timeout_seconds = 300

    def prepare
      @checkin_date = Date.tomorrow
      @nights = 2
      @city = '深圳'
      @airport_location = '深圳宝安国际机场'
      
      # 查找可用的2晚酒店套餐
      @available_packages = HotelPackage
        .where(city: @city, data_version: 0)
        .where(night_count: @nights)
        .to_a
      
      expect(@available_packages).not_to be_empty, "数据包缺少深圳2晚酒店套餐"
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
      
      # 创建接机服务（入住当天）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_location,
        location_to: "#{@city}市区",
        pickup_datetime: @checkin_date.in_time_zone + 10.hours,
        vehicle_type: 'economy_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 100.0,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建送机服务（退房当天）
      checkout_date = @checkin_date + @nights.days
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: "#{@city}市区",
        location_to: @airport_location,
        pickup_datetime: checkout_date.in_time_zone + 8.hours,
        vehicle_type: 'economy_5',
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
        checkin_date: @checkin_date.to_s,
        nights: @nights,
        city: @city,
        airport_location: @airport_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @checkin_date = Date.parse(data['checkin_date']) if data['checkin_date']
      @nights = data['nights']
      @city = data['city']
      @airport_location = data['airport_location']
    end

    def verify
      # 断言1: 创建了酒店套餐订单
      add_assertion "创建了酒店套餐订单", weight: 25 do
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
      add_assertion "城市正确（#{@city}）", weight: 10 do
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
      
      # 断言5: 创建了接机服务
      add_assertion "创建了接机服务", weight: 15 do
        @pickup_transfer = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@pickup_transfer).not_to be_nil, "未找到接机服务订单"
      end
      
      # 断言6: 创建了送机服务
      add_assertion "创建了送机服务", weight: 15 do
        @dropoff_transfer = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@dropoff_transfer).not_to be_nil, "未找到送机服务订单"
      end
      
      return if @pickup_transfer.nil? || @dropoff_transfer.nil?
      
      # 断言7: 接送机往返地点正确
      add_assertion "接送机往返地点正确（#{@airport_location}）", weight: 15 do
        pickup_ok = @pickup_transfer.location_from == @airport_location
        dropoff_ok = @dropoff_transfer.location_to == @airport_location
        
        expect(pickup_ok && dropoff_ok).to be(true),
          "接送机地点错误。接机: #{@pickup_transfer.location_from}, 送机: #{@dropoff_transfer.location_to}"
      end
    end
  end
end
