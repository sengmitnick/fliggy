# frozen_string_literal: true

require_relative '../base_validator'


# 验证用例145: 帮张三预订后天成都酒店套餐，住2晚，退房当天上午8点预订从春熙路商圈送机到双流机场T1航站楼
#
# 任务描述:
#   张三计划后天入住成都酒店套餐，住2晚，退房当天需要预订送机服务到成都机场。
#
# 任务分解步骤:
#   1. 查询成都的2晚酒店套餐（使用 HotelPackage.where(city: '成都', night_count: 2)）
#   2. 筛选入住日期=后天、住宿晚数=2晚的套餐
#   3. 创建酒店套餐订单（contact_name=张三，contact_phone=张三电话）
#   4. 从 TransferLocation 表查询成都机场位置（location_type='airport'，名称包含'双流'）
#   5. 从 TransferLocation 表查询春熙路商圈接送服务点（location_type='other'，名称包含'春熙路'）
#   6. 创建送机服务订单（transfer_type=airport_dropoff，location_from=春熙路商圈，location_to=从 TransferLocation 查询的机场名称）
#   7. 确保送机服务的乘客信息也使用张三的信息
#
# 复杂度分析（4个复杂点）：
#   1. 组合预订：需同时创建酒店套餐订单+送机订单（2个不同类型的订单）
#   2. 联系人信息一致性：酒店订单联系人和送机服务乘客都必须使用张三的信息
#   3. 时间协调：送机时间需要匹配退房日期
#   4. 接送点查询：需要从 TransferLocation 表查询成都机场位置和春熙路商圈接送服务点（不硬编码）
#
# 评分标准（总分10）：
#   1. 创建了酒店套餐订单（10分）
#   2. 城市正确=成都（10分）
#   3. 入住日期正确=后天（10分）
#   4. 住宿晚数正确=2晚（10分）
#   5. 酒店订单联系人信息正确=张三（10分）
#   6. 创建了送机服务（10分）
#   7. 送机服务乘客信息正确=张三（10分）
#   8. 上车点=春熙路商圈接送服务点（从 TransferLocation 动态获取）（10分）
#   9. 送机目的地正确=从transferLocation查询的成都机场（10分）
#   10. 送机时间在退房当天（10分）
#
# 使用方法:
#   rake validator:simulate_single[v145_book_hotel_package_with_airport_dropoff_validator]

module V101V150
  class V145BookHotelPackageWithAirportDropoffValidator < BaseValidator
    self.validator_id = 'v145_book_hotel_package_with_airport_dropoff_validator'
    self.task_id = 'f5a6b7c8-9d0e-1f2a-3b4c-5d6e7f8a9b0c'
    self.title = '帮张三预订后天成都酒店套餐，住2晚，退房当天上午8点预订从春熙路商圈送机到双流机场T1航站楼'
    self.description = '帮张三预订后天成都酒店套餐，住2晚，退房当天上午8点预订从春熙路商圈送机到双流机场T1航站楼'
    self.timeout_seconds = 300

    def prepare
      @checkin_date = Date.tomorrow + 1.day
      @nights = 2
      @city = '成都'
      
      # 查询TransferLocation获取成都机场（送机目的地，不硬编码）
      @airport_loc = TransferLocation.where(
        city: @city,
        location_type: 'airport',
        data_version: 0
      ).find { |loc| loc.name.include?('双流') }
      
      raise "数据包缺少成都机场TransferLocation" unless @airport_loc
      
      @dropoff_location = @airport_loc.name  # 送机目的地=机场名称（从transferlocation动态获取）
      
      # 查询TransferLocation获取春熙路商圈接送服务点（送机上车点）
      @pickup_loc = TransferLocation.where(
        city: @city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('春熙路商圈') }
      
      raise "数据包缺少春熙路商圈TransferLocation" unless @pickup_loc
      
      @pickup_location = @pickup_loc.name  # 送机上车点=春熙路商圈（从transferlocation动态获取）
      
      # 预查询联系人信息（用于 simulate 和 verify）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      # 查找可用的2晚酒店套餐
      @available_packages = HotelPackage
        .where(city: @city, data_version: 0)
        .where(night_count: @nights)
        .to_a
      
      expect(@available_packages).not_to be_empty, "数据包缺少成都2晚酒店套餐"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      package = @available_packages.first
      
      # 优先选择豪华套餐（含早+晚餐），适合亲子家庭
      luxury_option = package.package_options.find_by("name LIKE ?", "%豪华%")
      option = luxury_option || package.package_options.order(price: :desc).first
      
      # 创建酒店套餐订单
      hotel_order = HotelPackageOrder.create!(
        user: user,
        hotel_package: package,
        hotel_id: package.hotel.id,
        package_option: option,
        passenger_id: passenger.id,
        contact_name: passenger.name,
        contact_phone: passenger.phone,
        check_in_date: @checkin_date,
        check_out_date: @checkin_date + @nights.days,
        total_price: option.price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 创建送机服务（退房当天，从春熙路商圈送至机场）
      checkout_date = @checkin_date + @nights.days
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: @pickup_location,  # 上车点=春熙路商圈（从 TransferLocation 动态获取）
        location_to: @dropoff_location,  # 目的地=机场名称（从 TransferLocation 动态获取）
        pickup_datetime: checkout_date.in_time_zone + 8.hours,
        vehicle_type: 'business_7',
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
        total_price: 120.0,
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
        airport_location_name: @airport_loc&.name,
        pickup_location_name: @pickup_loc&.name,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @checkin_date = Date.parse(data['checkin_date']) if data['checkin_date']
      @nights = data['nights']
      @city = data['city']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      
      # 重新查询TransferLocation（机场和上车点）
      @airport_loc = TransferLocation.find_by(
        city: @city,
        name: data['airport_location_name'],
        location_type: 'airport',
        data_version: 0
      ) if data['airport_location_name']
      
      @pickup_loc = TransferLocation.find_by(
        city: @city,
        name: data['pickup_location_name'],
        location_type: 'other',
        data_version: 0
      ) if data['pickup_location_name']
      
      @dropoff_location = @airport_loc&.name
      @pickup_location = @pickup_loc&.name
    end

    def verify
      # 断言1: 创建了酒店套餐订单
      add_assertion "创建了酒店套餐订单", weight: 10 do
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
          "入住日期错误。期望: #{@checkin_date}（后天）, 实际: #{@hotel_package_order.check_in_date}"
      end
      
      # 断言4: 住宿晚数正确
      add_assertion "住宿晚数正确（#{@nights}晚）", weight: 10 do
        actual_nights = (@hotel_package_order.check_out_date - @hotel_package_order.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿晚数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      # 断言5: 酒店订单联系人信息正确（张三）
      add_assertion "酒店订单联系人信息正确（张三）", weight: 10 do
        expect(@hotel_package_order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@hotel_package_order.contact_name}"
        expect(@hotel_package_order.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@hotel_package_order.contact_phone}"
      end
      
      # 断言6: 创建了送机服务
      add_assertion "创建了送机服务", weight: 10 do
        @transfer = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到送机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言7: 送机服务乘客信息正确（张三）
      add_assertion "送机服务乘客信息正确（张三）", weight: 10 do
        expect(@transfer.passenger_name).to eq(@expected_contact_name),
          "乘客姓名错误。期望: #{@expected_contact_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_contact_phone),
          "乘客电话错误。期望: #{@expected_contact_phone}, 实际: #{@transfer.passenger_phone}"
      end
      
      # 断言8: 上车点=春熙路商圈接送服务点（从 TransferLocation 动态获取）
      add_assertion "上车点=春熙路商圈接送服务点（#{@pickup_location}）", weight: 10 do
        expect(@transfer.location_from).to eq(@pickup_location),
          "上车点错误。应从#{@pickup_location}出发，实际: #{@transfer.location_from}"
      end
      
      # 断言9: 送机目的地正确
      add_assertion "送机目的地正确（#{@dropoff_location}）", weight: 10 do
        expect(@transfer.location_to).to eq(@dropoff_location),
          "送机目的地错误。期望: #{@dropoff_location}, 实际: #{@transfer.location_to}"
      end
      
      # 断言10: 送机时间在退房当天
      add_assertion "送机时间在退房当天", weight: 10 do
        checkout_date = @checkin_date + @nights.days
        transfer_date = @transfer.pickup_datetime.to_date
        expect(transfer_date).to eq(checkout_date),
          "送机时间错误。期望: #{checkout_date}（退房当天）, 实际: #{transfer_date}"
      end
    end
  end
end
