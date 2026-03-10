# frozen_string_literal: true

#
# 验证用例143: 帮张三预订后天上海洲际酒店含早套餐，住2晚，并预订浦东国际机场接机服务（后天上午11点从北京飞抵上海，送至陆家嘴金融区接送服务点）
#
# 任务描述:
#   张三计划后天上午从北京飞往上海（预计上午11点左右到达浦东国际机场），入住上海洲际酒店的含早套餐，住2晚。
#   同时需要预订浦东国际机场的接机服务（从北京飞来，上午11点左右接机）送至陆家嘴金融区接送服务点。
#
# 任务分解步骤:
#   1. 查询上海洲际酒店的含早套餐（使用 HotelPackage.where(city: '上海', night_count: 2)）
#   2. 确认套餐中的酒店名称包含"洲际"
#   3. 筛选入住日期=后天（Date.tomorrow + 1.day）、住宿晚数=2晚的套餐
#   4. 选择含早餐的套餐选项（package_option 名称包含"含早"或"早餐"）
#   5. 创建酒店套餐订单（contact_name=张三，contact_phone=张三电话，确保联系人信息匹配）
#   6. 创建机场接机服务订单（transfer_type=airport_pickup，后天上午11点从北京飞抵上海，location_from=上海浦东国际机场，location_to=陆家嘴金融区接送服务点）
#   7. 确保接机服务的乘客信息也使用张三的姓名和电话
#
# 复杂度分析（4个复杂点）：
#   1. 组合预订：需同时创建酒店套餐订单+机场接机订单（2个不同类型的订单）
#   2. 套餐选项筛选：需要从 package_options 中筛选含早餐的选项
#   3. 联系人信息一致性：酒店订单联系人和接机服务乘客都必须使用张三的信息
#   4. 时间协调：接机时间需要匹配入住日期
#
# 评分标准（总分100分）：
#   1. 创建了酒店套餐订单（20分）
#   2. 酒店名称正确=洲际酒店（15分）
#   3. 入住日期正确=后天（10分）
#   4. 住宿晚数正确=2晚（10分）
#   5. 选择了含早餐套餐（10分）
#   6. 酒店订单联系人信息正确=张三（10分）
#   7. 创建了机场接机服务（10分）
#   8. 接机服务乘客信息正确=张三（10分）
#   9. 接机下车点正确=陆家嘴金融区接送服务点（5分）
#
# 使用方法:
#   rake validator:simulate_single[v143_book_hotel_package_with_airport_pickup_validator]

module V101V150
  class V143BookHotelPackageWithAirportPickupValidator < BaseValidator
    self.validator_id = 'v143_book_hotel_package_with_airport_pickup_validator'
    self.task_id = 'd3e4f5a6-7b8c-9d0e-1f2a-3b4c5d6e7f8a'
    self.title = '帮张三预订后天上海洲际酒店含早套餐，住2晚，并预订浦东国际机场接机服务（后天上午11点从北京飞抵上海，送至陆家嘴金融区接送服务点）'
    self.description = '帮张三预订后天上海洲际酒店含早套餐，住2晚，并预订浦东国际机场接机服务（后天上午11点从北京飞抵上海，送至陆家嘴金融区接送服务点）'
    self.timeout_seconds = 300

    def task_description
      "帮张三预订后天上海洲际酒店含早套餐，住2晚，并预订浦东国际机场接机服务（后天上午11点从北京飞抵上海，送至陆家嘴金融区接送服务点）"
    end

    def prepare
      @checkin_date = Date.tomorrow + 1.day
      @nights = 2
      @city = '上海'
      @hotel_name_pattern = '洲际'  # 明确要求预订洲际酒店
      
      # 预查询机场接送点（TransferLocation - 浦东国际机场）
      @airport_loc = TransferLocation.where(
        city: @city,
        location_type: 'airport',
        data_version: 0
      ).find { |loc| loc.name.include?('浦东') }
      
      raise "未找到上海浦东国际机场接送点" unless @airport_loc
      
      # 预查询下车点：陆家嘴金融区接送服务点
      @dropoff_loc = TransferLocation.where(
        city: @city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('陆家嘴') && loc.name.include?('接送服务点') }
      
      raise "未找到陆家嘴金融区接送服务点" unless @dropoff_loc
      
      # 预查询联系人信息（用于 simulate 和 verify）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      # 查找可用的洲际酒店套餐（含早套餐）
      @available_packages = HotelPackage
        .joins(:hotel)
        .where(city: @city, data_version: 0)
        .where(night_count: @nights)
        .where('hotels.name LIKE ?', "%#{@hotel_name_pattern}%")
        .to_a
      
      expect(@available_packages).not_to be_empty, "数据包缺少上海洲际酒店套餐"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
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
        contact_name: passenger.name,
        contact_phone: passenger.phone,
        check_in_date: @checkin_date,
        check_out_date: @checkin_date + @nights.days,
        total_price: breakfast_option.price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 创建机场接机服务（从浦东机场到陆家嘴金融区接送服务点）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_loc.name,  # 使用TransferLocation查询结果（浦东国际机场）
        location_to: @dropoff_loc.name,  # 陆家嘴金融区接送服务点
        pickup_datetime: @checkin_date.in_time_zone + 11.hours,
        vehicle_type: 'business_5',
        passenger_name: passenger.name,
        passenger_phone: passenger.phone,
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
        airport_location_name: @airport_loc&.name,
        dropoff_location_name: @dropoff_loc&.name,
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
      
      # 重新查询TransferLocation（上车点和下车点）
      @airport_loc = TransferLocation.find_by(
        city: @city,
        name: data['airport_location_name'],
        location_type: 'airport',
        data_version: 0
      ) if data['airport_location_name']
      
      @dropoff_loc = TransferLocation.find_by(
        city: @city,
        name: data['dropoff_location_name'],
        location_type: 'other',
        data_version: 0
      ) if data['dropoff_location_name']
    end

    def verify
      # 断言1: 创建了酒店套餐订单
      add_assertion "创建了酒店套餐订单", weight: 20 do
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
      
      # 断言2: 酒店名称正确（洲际酒店）
      add_assertion "酒店名称正确（洲际酒店）", weight: 15 do
        hotel_name = @hotel_package_order.hotel_package.hotel.name
        is_intercontinental = hotel_name.include?('洲际')
        expect(is_intercontinental).to be(true),
          "酒店名称错误。期望: 上海洲际酒店, 实际: #{hotel_name}"
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
      add_assertion "选择了含早餐套餐", weight: 10 do
        option_name = @hotel_package_order.package_option&.name.to_s
        has_breakfast = option_name.include?("含早") || option_name.include?("早餐")
        expect(has_breakfast).to be(true),
          "未选择含早餐套餐。实际选项: #{option_name}"
      end
      
      # 断言6: 酒店订单联系人信息正确（张三）
      add_assertion "酒店订单联系人信息正确（张三）", weight: 10 do
        expect(@hotel_package_order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@hotel_package_order.contact_name}"
        expect(@hotel_package_order.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@hotel_package_order.contact_phone}"
      end
      
      # 断言7: 创建了机场接机服务
      add_assertion "创建了机场接机服务", weight: 10 do
        @transfer = Transfer
          .where(transfer_type: 'airport_pickup', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场接机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言8: 接机服务乘客信息正确（张三）
      add_assertion "接机服务乘客信息正确（张三）", weight: 10 do
        expect(@transfer.passenger_name).to eq(@expected_contact_name),
          "乘客姓名错误。期望: #{@expected_contact_name}, 实际: #{@transfer.passenger_name}"
        expect(@transfer.passenger_phone).to eq(@expected_contact_phone),
          "乘客电话错误。期望: #{@expected_contact_phone}, 实际: #{@transfer.passenger_phone}"
      end
      
      # 断言9: 接机下车点正确（陆家嘴金融区接送服务点）
      add_assertion "接机下车点正确（陆家嘴金融区接送服务点）", weight: 5 do
        location_to = @transfer.location_to
        is_lujiazui = location_to.include?('陆家嘴') && location_to.include?('接送服务点')
        expect(is_lujiazui).to be(true),
          "接机下车点错误。期望: 陆家嘴金融区接送服务点, 实际: #{location_to}"
      end
    end
  end
end
