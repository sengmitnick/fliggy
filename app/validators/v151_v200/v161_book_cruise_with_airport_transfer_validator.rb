# frozen_string_literal: true

require_relative '../base_validator'

# V161BookCruiseWithAirportTransferValidator
# 验证用例161: 给张三和李四2成人预订上海日本邮轮6天5晚，并订机场往返接送服务（从北京飞来，邮轮出发前1天15:00从上海浦东国际机场T1航站楼接机到外滩，邮轮返回后第7天09:00从外滩送到上海浦东国际机场T1航站楼）
#
# 任务描述:
#   张三和李四从北京飞来上海，计划预订上海出发日本邮轮6天5晚，需要机场往返接送服务：邮轮出发前1天15:00从上海浦东国际机场T1航站楼接机到外滩，邮轮返回后第7天09:00从外滩送到上海浦东国际机场T1航站楼。
#   1. 上海出发日本邮轮6天5晚（当月最近日期班次，2成人：张三和李四）
#   2. 机场接机服务（从北京飞来，邮轮出发前1天15:00从上海浦东国际机场T1航站楼接机到外滩）
#   3. 机场送机服务（邮轮返回后第7天09:00从外滩送到上海浦东国际机场T1航站楼）
#
# 任务分解步骤:
#   1. 查询上海出发日本邮轮班次（departure_port=上海，duration_days=6，duration_nights=5，当月）
#   2. 选择当月最近日期的班次（按departure_date升序排序后取第一个）
#   3. 创建邮轮订单（2成人：张三和李四，联系人=张三）
#   4. 从TransferLocation获取上海浦东国际机场T1航站楼接送点
#   5. 从TransferLocation获取外滩接送点
#   6. 创建机场接机服务（乘客从北京飞来，邮轮出发前1天15:00，从上海浦东国际机场T1航站楼到外滩，不关联航班号）
#   7. 创建机场送机服务（邮轮返回后第7天09:00，从外滩到上海浦东国际机场T1航站楼，不关联航班号）
#
# 评分标准（总分100分）:
#   1. 创建了邮轮订单 (20分)
#   2. 出发港正确（上海） (10分)
#   3. 行程天数正确（6天5晚） (10分)
#   4. 创建了机场往返接送服务（接机+送机） (15分)
#   5. 接机服务地点正确（上海浦东国际机场T1航站楼→外滩） (15分)
#   6. 接机时间正确（邮轮出发前1天15:00） (10分)
#   7. 送机服务地点正确（外滩→上海浦东国际机场T1航站楼） (10分)
#   8. 送机时间正确（邮轮返回后第7天09:00） (5分)
#   9. 联系人信息正确（张三） (5分)

module V151V200
  class V161BookCruiseWithAirportTransferValidator < BaseValidator
    self.validator_id = 'v161_book_cruise_with_airport_transfer_validator'
    self.task_id = 'e1f2a3b4-5c6d-7e8f-9a0b-1c2d3e4f5a6b'
    self.title = '给张三和李四2成人预订上海日本邮轮6天5晚，并订机场往返接送服务（从北京飞来，邮轮出发前1天15:00从上海浦东国际机场T1航站楼接机到外滩，邮轮返回后第7天09:00从外滩送到上海浦东国际机场T1航站楼）'
    self.description = '给张三和李四从北京飞来上海，预订上海出发日本邮轮6天5晚，并订机场往返接送服务（邮轮出发前1天15:00从上海浦东国际机场T1航站楼接机到外滩，邮轮返回后第7天09:00从外滩送到上海浦东国际机场T1航站楼）'
    self.timeout_seconds = 300

    def prepare
      # 邮轮出发月份：当前月份
      @expected_month = Date.current.month
      @departure_port = '上海'
      @airport_city = '上海'
      @flight_departure_city = '北京'  # 乘客飞机出发城市
      @duration_days = 6
      @duration_nights = 5
      @adult_count = 2
      
      # 预查询demo_user的乘客信息（张三作为联系人和第一位出行人员）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 查找可用的上海出发日本邮轮班次（按月份查询）
      @available_sailings = CruiseSailing
        .where("departure_port LIKE ?", "%#{@departure_port}%")
        .where(duration_days: @duration_days, duration_nights: @duration_nights, data_version: 0)
        .where('EXTRACT(MONTH FROM departure_date) = ?', @expected_month)
        .order(departure_date: :asc)
        .to_a
      
      raise "数据包缺少上海出发日本6天5晚邮轮班次（#{@expected_month}月份）" if @available_sailings.empty?
      
      # 查询TransferLocation获取上海浦东国际机场接送点
      @airport_loc = TransferLocation.where(
        city: @airport_city,
        location_type: 'airport',
        data_version: 0
      ).find { |loc| loc.name.include?('浦东') }
      
      raise "数据包缺少上海浦东机场接送服务点TransferLocation" unless @airport_loc
      
      @airport_location = @airport_loc.name  # 上海浦东国际机场T1航站楼（从TransferLocation动态获取）
      
      # 查询TransferLocation获取上海外滩接送点
      @bund_loc = TransferLocation.where(
        city: @departure_port,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('外滩') }
      
      raise "数据包缺少上海外滩接送服务点TransferLocation" unless @bund_loc
      
      @bund_location = @bund_loc.name  # 外滩（从TransferLocation动态获取）
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择最近日期的班次
      sailing = @available_sailings.first
      ship = sailing.cruise_ship
      
      # 计算接机和送机日期时间
      pickup_date = sailing.departure_date - 1.day  # 邮轮出发前1天
      pickup_datetime = pickup_date.in_time_zone.change(hour: 15, min: 0)  # 下午3点
      
      dropoff_date = sailing.departure_date + @duration_days.days  # 邮轮返回后1天（第7天）
      dropoff_datetime = dropoff_date.in_time_zone.change(hour: 9, min: 0)  # 早上9点
      
      # 查找舱房类型（选择经济舱）
      cabin_type = CabinType.where(data_version: 0, cruise_ship_id: ship.id, category: 'interior').first
      raise "未找到舱房类型" unless cabin_type
      
      # 查找邮轮产品（必须存在于数据包中）
      cruise_product = CruiseProduct.find_by!(
        cruise_sailing_id: sailing.id,
        cabin_type_id: cabin_type.id,
        data_version: 0
      )
      
      total_price = cruise_product.price_per_person * @adult_count
      
      # 准备出行人员信息（2成人：张三和李四）
      passenger_info = [
        {
          name: @passenger.name,
          id_number: @passenger.id_number,
          phone: @passenger.phone,
          passenger_type: 'adult'
        },
        {
          name: '李四',
          id_number: '110101199001012346',
          phone: '13900000002',
          passenger_type: 'adult'
        }
      ]
      
      # 创建邮轮订单（明确出行人员：张三和李四）
      CruiseOrder.create!(
        user_id: user.id,
        cruise_product_id: cruise_product.id,
        quantity: @adult_count,
        passenger_info: passenger_info,
        contact_name: @passenger.name,
        contact_phone: @passenger.phone,
        total_price: total_price,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建机场接机服务（乘客从北京飞来，从上海浦东机场接到外滩，不关联航班号）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_pickup',
        service_type: 'from_airport',
        location_from: @airport_location,  # 上海浦东国际机场T1航站楼（从TransferLocation动态获取）
        location_to: @bund_location,   # 外滩（从TransferLocation动态获取）
        pickup_datetime: pickup_datetime,
        flight_number: nil,  # 接机服务不关联航班号（但乘客从北京飞来）
        vehicle_type: 'business_5',
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        passenger_count: @adult_count,
        luggage_count: @adult_count,
        total_price: 150.0,
        discount_amount: 0,
        status: 'paid',
        driver_status: 'pending',
        data_version: @data_version
      )
      
      # 创建机场送机服务（从外滩送到上海浦东机场，不关联航班号）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: @bund_location,  # 外滩（从TransferLocation动态获取）
        location_to: @airport_location,   # 上海浦东国际机场T1航站楼（从TransferLocation动态获取）
        pickup_datetime: dropoff_datetime,
        flight_number: nil,  # 送机服务不关联航班号
        vehicle_type: 'business_5',
        passenger_name: @passenger.name,
        passenger_phone: @passenger.phone,
        passenger_count: @adult_count,
        luggage_count: @adult_count,
        total_price: 150.0,
        discount_amount: 0,
        status: 'paid',
        driver_status: 'pending',
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        expected_month: @expected_month,
        departure_port: @departure_port,
        airport_city: @airport_city,
        flight_departure_city: @flight_departure_city,
        duration_days: @duration_days,
        duration_nights: @duration_nights,
        adult_count: @adult_count,
        airport_location: @airport_location,
        bund_location: @bund_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @expected_month = data['expected_month']
      @departure_port = data['departure_port']
      @airport_city = data['airport_city']
      @flight_departure_city = data['flight_departure_city']
      @duration_days = data['duration_days']
      @duration_nights = data['duration_nights']
      @adult_count = data['adult_count']
      @airport_location = data['airport_location']
      @bund_location = data['bund_location']
      
      # 重新查询乘客信息（张三作为联系人和第一位出行人员）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
      
      # 重新查询邮轮班次
      @available_sailings = CruiseSailing
        .where("departure_port LIKE ?", "%#{@departure_port}%")
        .where(duration_days: @duration_days, duration_nights: @duration_nights, data_version: 0)
        .where('EXTRACT(MONTH FROM departure_date) = ?', @expected_month)
        .order(departure_date: :asc)
        .to_a
      
      # 重新查找TransferLocation
      @airport_loc = TransferLocation.where(
        city: @airport_city,
        location_type: 'airport',
        data_version: 0
      ).find { |loc| loc.name.include?('浦东') }
      
      @airport_location = @airport_loc.name if @airport_loc
      
      @bund_loc = TransferLocation.where(
        city: @departure_port,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('外滩') }
      
      @bund_location = @bund_loc.name if @bund_loc
    end

    def verify
      # 断言1: 创建了邮轮订单
      add_assertion "创建了邮轮订单", weight: 20 do
        @cruise_order = CruiseOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@cruise_order).not_to be_nil, "未找到任何邮轮订单"
      end
      
      return if @cruise_order.nil?
      
      # 断言2: 出发港正确（上海）
      add_assertion "出发港正确（#{@departure_port}）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.departure_port).to include(@departure_port),
          "出发港错误。期望包含: #{@departure_port}, 实际: #{sailing.departure_port}"
      end
      
      # 断言3: 行程天数正确（6天5晚）
      add_assertion "行程天数正确（#{@duration_days}天#{@duration_nights}晚）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天#{@duration_nights}晚, 实际: #{sailing.duration_days}天#{sailing.duration_nights}晚"
      end
      
      # 断言4: 创建了机场往返接送服务（接机+送机）
      add_assertion "创建了机场往返接送服务（接机+送机）", weight: 15 do
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
      
      # 断言5: 接机服务地点正确（上海浦东国际机场→外滩）
      add_assertion "接机服务地点正确（#{@airport_location}→#{@bund_location}）", weight: 15 do
        expect(@pickup_transfer.location_from).to eq(@airport_location),
          "接机出发地错误。期望: #{@airport_location}, 实际: #{@pickup_transfer.location_from}"
        
        expect(@pickup_transfer.location_to).to eq(@bund_location),
          "接机目的地错误。期望: #{@bund_location}, 实际: #{@pickup_transfer.location_to}"
      end
      
      # 断言6: 接机时间正确（邮轮出发前1天15:00）
      add_assertion "接机时间正确（邮轮出发前1天15:00）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expected_pickup_date = sailing.departure_date - 1.day
        expected_time = expected_pickup_date.in_time_zone.change(hour: 15, min: 0)
        actual_time = @pickup_transfer.pickup_datetime.in_time_zone
        
        # 比较Unix时间戳忽略时区差异
        expect(actual_time.to_i).to eq(expected_time.to_i),
          "接机时间错误。期望: #{expected_time.strftime('%Y-%m-%d %H:%M %Z')}（邮轮#{sailing.departure_date.strftime('%m月%d日')}出发前1天15:00）, 实际: #{actual_time.strftime('%Y-%m-%d %H:%M %Z')}"
      end
      
      # 断言7: 送机服务地点正确（外滩→上海浦东国际机场）
      add_assertion "送机服务地点正确（#{@bund_location}→#{@airport_location}）", weight: 10 do
        expect(@dropoff_transfer.location_from).to eq(@bund_location),
          "送机出发地错误。期望: #{@bund_location}, 实际: #{@dropoff_transfer.location_from}"
        
        expect(@dropoff_transfer.location_to).to eq(@airport_location),
          "送机目的地错误。期望: #{@airport_location}, 实际: #{@dropoff_transfer.location_to}"
      end
      
      # 断言8: 送机时间正确（邮轮返回后第7天09:00）
      add_assertion "送机时间正确（邮轮返回后第7天09:00）", weight: 5 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expected_dropoff_date = sailing.departure_date + @duration_days.days
        expected_time = expected_dropoff_date.in_time_zone.change(hour: 9, min: 0)
        actual_time = @dropoff_transfer.pickup_datetime.in_time_zone
        
        # 比较Unix时间戳忽略时区差异
        expect(actual_time.to_i).to eq(expected_time.to_i),
          "送机时间错误。期望: #{expected_time.strftime('%Y-%m-%d %H:%M %Z')}（邮轮返回后第7天09:00）, 实际: #{actual_time.strftime('%Y-%m-%d %H:%M %Z')}"
      end
      
      # 断言9: 联系人信息正确（张三）
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 5 do
        expect(@cruise_order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@cruise_order.contact_name}"
        expect(@cruise_order.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@cruise_order.contact_phone}"
      end
    end
  end
end
