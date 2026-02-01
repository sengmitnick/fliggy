# frozen_string_literal: true

require_relative '../base_validator'

# V144: 预订北京酒店套餐1晚（商务快捷）+ 车站接送服务
# 验证用户能够完成酒店套餐预订+车站接送服务的组合下单

module V101V150
  class V144BookHotelPackageWithStationTransferValidator < BaseValidator
    self.validator_id = 'v144_book_hotel_package_with_station_transfer_validator'
    self.task_id = 'e4f5a6b7-8c9d-0e1f-2a3b-4c5d6e7f8a9b'
    self.title = '预订酒店套餐后预订火车站接站服务（北京1晚）'
    self.description = '预订明天北京酒店套餐1晚（商务快捷），并预订火车站接站服务'
    self.timeout_seconds = 300

    def prepare
      @checkin_date = Date.tomorrow
      @nights = 1
      @city = '北京'
      @pickup_location = '北京南站'
      
      # 查找可用的1晚酒店套餐
      @available_packages = HotelPackage
        .where(city: @city, data_version: 0)
        .where(night_count: @nights)
        .to_a
      
      expect(@available_packages).not_to be_empty, "数据包缺少北京1晚酒店套餐"
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
      
      # 创建火车站接站服务
      Transfer.create!(
        user: user,
        transfer_type: 'train_pickup',
        service_type: 'from_station',
        location_from: @pickup_location,
        location_to: "#{@city}市区",
        pickup_datetime: @checkin_date.in_time_zone + 14.hours,
        vehicle_type: 'economy_5',
        passenger_name: user.name,
        passenger_phone: '13800138000',
        total_price: 80.0,
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
      
      # 断言5: 创建了火车站接站服务
      add_assertion "创建了火车站接站服务", weight: 20 do
        @transfer = Transfer
          .where(transfer_type: 'train_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到火车站接站服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言6: 接站地点正确
      add_assertion "接站地点正确（#{@pickup_location}）", weight: 15 do
        expect(@transfer.location_from).to eq(@pickup_location),
          "接站地点错误。期望: #{@pickup_location}, 实际: #{@transfer.location_from}"
      end
    end
  end
end
