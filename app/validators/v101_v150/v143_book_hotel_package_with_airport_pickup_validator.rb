# frozen_string_literal: true

require_relative '../base_validator'

# V143: 预订上海豪华酒店套餐2晚（含早餐）+ 机场接机服务
# 验证用户能够完成酒店套餐预订+机场接机服务的组合下单

module V101V150
  class V143BookHotelPackageWithAirportPickupValidator < BaseValidator
    self.validator_id = 'v143_book_hotel_package_with_airport_pickup_validator'
    self.task_id = 'd3e4f5a6-7b8c-9d0e-1f2a-3b4c5d6e7f8a'
    self.title = '预订酒店套餐后预订机场接机服务（上海豪华2晚）'
    self.description = '预订后天上海豪华酒店套餐2晚（含早餐），并预订机场接机服务'
    self.timeout_seconds = 300

    def prepare
      @checkin_date = Date.tomorrow + 1.day
      @nights = 2
      @city = '上海'
      @brand_pattern = ['万豪', '希尔顿', '洲际', '凯悦']
      @pickup_location = '上海浦东国际机场'
      
      # 查找可用的豪华酒店套餐（含早餐）
      @available_packages = HotelPackage
        .where(city: @city, data_version: 0)
        .where(night_count: @nights)
        .where("title LIKE ? OR title LIKE ? OR title LIKE ? OR title LIKE ?", 
               "%#{@brand_pattern[0]}%", "%#{@brand_pattern[1]}%", 
               "%#{@brand_pattern[2]}%", "%#{@brand_pattern[3]}%")
        .to_a
      
      expect(@available_packages).not_to be_empty, "数据包缺少上海豪华品牌酒店套餐"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(phone: '13800138000', data_version: 0)
      package = @available_packages.first
      
      # 查找含早套餐选项
      breakfast_option = package.package_options.find_by("name LIKE ?", "%含早%") || package.package_options.first
      
      # 创建酒店套餐订单
      HotelPackageOrder.create!(
        user: user,
        hotel_package: package,
        hotel_id: package.hotel.id,
        package_option: breakfast_option,
        passenger_id: passenger.id,
        contact_name: user.name,
        contact_phone: '13800138000',
        check_in_date: @checkin_date,
        check_out_date: @checkin_date + @nights.days,
        total_price: breakfast_option.price,
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
    end

    def execution_state_data
      {
        data_version: @data_version,
        checkin_date: @checkin_date.to_s,
        nights: @nights,
        city: @city,
        pickup_location: @pickup_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @checkin_date = Date.parse(data['checkin_date']) if data['checkin_date']
      @nights = data['nights']
      @city = data['city']
      @pickup_location = data['pickup_location']
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
      add_assertion "城市正确（#{@city}）", weight: 15 do
        expect(@hotel_package_order.hotel_package.city).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@hotel_package_order.hotel_package.city}"
      end
      
      # 断言3: 入住日期正确
      add_assertion "入住日期正确（#{@checkin_date}）", weight: 10 do
        expect(@hotel_package_order.check_in_date).to eq(@checkin_date),
          "入住日期错误。期望: #{@checkin_date}（后天）, 实际: #{@hotel_package_order.check_in_date}"
      end
      
      # 断言4: 住宿晚数正确
      add_assertion "住宿晚数正确（#{@nights}晚）", weight: 10 do
        actual_nights = (@hotel_package_order.check_out_date - @hotel_package_order.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿晚数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      # 断言5: 包含早餐选项
      add_assertion "选择了含早餐套餐", weight: 15 do
        option_name = @hotel_package_order.package_option&.name.to_s
        has_breakfast = option_name.include?("含早") || option_name.include?("早餐")
        expect(has_breakfast).to be(true),
          "未选择含早餐套餐。实际选项: #{option_name}"
      end
      
      # 断言6: 创建了机场接机服务
      add_assertion "创建了机场接机服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场接机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言7: 接机地点正确
      add_assertion "接机地点正确（#{@pickup_location}）", weight: 10 do
        expect(@transfer.location_from).to eq(@pickup_location),
          "接机地点错误。期望: #{@pickup_location}, 实际: #{@transfer.location_from}"
      end
    end
  end
end
