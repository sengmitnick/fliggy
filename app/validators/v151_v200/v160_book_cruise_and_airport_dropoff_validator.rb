# frozen_string_literal: true

require_relative '../base_validator'

# V160BookCruiseAndAirportDropoffValidator
# 验证用例160: 给张三和李四2成人预订上海日本邮轮6天5晚（当月最近日期班次），并预订机场送机服务（邮轮结束后第6天下午从外滩送到上海浦东国际机场T2，赶当天16:00飞北京的航班，14:00从外滩出发）
#
# 任务描述:
#   张三和李四计划预订上海出发日本邮轮6天5晚，邮轮结束后需要机场送机服务：邮轮第6天返回，下午14:00从外滩送到上海浦东国际机场T2航站楼，赶当天16:00飞北京的航班（航班起飞前2小时出发）。
#   1. 上海出发日本邮轮6天5晚（当月班次，2成人：张三和李四）
#   2. 机场送机服务（邮轮结束后第6天下午14:00，从外滩送到上海浦东国际机场T2，赶16:00飞北京的航班）
#
# 任务分解步骤:
#   1. 查询上海出发日本邮轮班次（departure_port=上海，duration_days=6，duration_nights=5，当月）
#   2. 选择当月最近日期的班次（按departure_date升序排序后取第一个）
#   3. 创建邮轮订单（2成人：张三和李四，联系人=张三）
#   4. 从TransferLocation获取外滩接送点（送机出发地）
#   5. 从TransferLocation获取上海浦东国际机场T2航站楼（送机目的地）
#   6. 查询当月上海浦东飞北京的航班（用于确认送机时间合理性）
#   7. 创建机场送机服务（邮轮结束后第6天下午14:00，从外滩出发，送至上海浦东国际机场T2，赶16:00飞北京航班，不关联具体航班号）
#
# 评分标准（总分100分）:
#   1. 创建了邮轮订单 (20分)
#   2. 出发港正确（上海） (10分)
#   3. 行程天数正确（6天5晚） (10分)
#   4. 创建了机场送机服务 (15分)
#   5. 送机服务地点正确（外滩→上海浦东国际机场T2） (20分)
#   6. 送机时间正确（邮轮结束后第6天下午14:00） (15分)
#   7. 联系人信息正确（张三） (5分)
#   8. 出行人员信息正确（2成人） (5分)

module V151V200
  class V160BookCruiseAndAirportDropoffValidator < BaseValidator
    self.validator_id = 'v160_book_cruise_and_airport_dropoff_validator'
    self.task_id = 'd0e1f2a3-4b5c-6d7e-8f9a-0b1c2d3e4f5a'
    self.title = '给张三和李四2成人预订上海日本邮轮6天5晚，并预订机场送机服务（邮轮结束后第6天下午14:00从外滩送到上海浦东国际机场T2，赶16:00飞北京的航班）'
    self.description = '给张三和李四预订上海出发日本邮轮6天5晚，并预订机场送机服务（邮轮结束后第6天下午14:00从外滩送到上海浦东国际机场T2航站楼，赶16:00飞北京的航班）'
    self.timeout_seconds = 300

    def prepare
      # 邮轮出发月份：当前月份
      @expected_month = Date.current.month
      @departure_port = '上海'
      @departure_city = '上海'  # 送机出发城市
      @duration_days = 6
      @duration_nights = 5
      @adult_count = 2
      
      # 预查询demo_user的乘客信息（张三作为联系人和出行人员）
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
      
      # 查询TransferLocation获取外滩接送点（送机出发地）
      @departure_loc = TransferLocation.where(
        city: @departure_city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('外滩') }
      
      raise "数据包缺少外滩接送服务点TransferLocation" unless @departure_loc
      
      @departure_location = @departure_loc.name  # 外滩（从TransferLocation动态获取）
      
      # 查询TransferLocation获取上海浦东国际机场T2航站楼（送机目的地）
      @airport_loc = TransferLocation.where(
        city: @departure_city,
        location_type: 'airport',
        data_version: 0
      ).find { |loc| loc.name.include?('浦东') && loc.name.include?('T2') }
      
      raise "数据包缺少上海浦东国际机场T2接送服务点TransferLocation" unless @airport_loc
      
      @airport_location = @airport_loc.name  # 上海浦东国际机场T2（从TransferLocation动态获取）
      
      # 查询上海浦东飞北京的航班（用于确认送机时间合理性）
      @reference_flights = Flight
        .where(departure_city: @departure_port, destination_city: '北京', data_version: 0)
        .where('EXTRACT(MONTH FROM flight_date) = ?', @expected_month)
        .where("departure_airport LIKE ?", "%浦东%")
        .to_a
      
      raise "数据包缺少上海浦东飞北京的航班（#{@expected_month}月份）" if @reference_flights.empty?
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择最近日期的班次
      sailing = @available_sailings.first
      ship = sailing.cruise_ship
      
      # 计算送机日期和时间（邮轮第6天返回当天下午14:00，赶16:00飞北京的航班）
      dropoff_date = sailing.departure_date + (@duration_days - 1).days
      dropoff_datetime = dropoff_date.in_time_zone.change(hour: 14, min: 0)
      
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
      
      # 创建机场送机服务（邮轮结束后第6天下午14:00从外滩送到上海浦东国际机场T2，不关联具体航班号）
      Transfer.create!(
        user: user,
        transfer_type: 'airport_dropoff',
        service_type: 'to_airport',
        location_from: @departure_location,    # 外滩（从TransferLocation动态获取）
        location_to: @airport_location,        # 上海浦东国际机场T2（从TransferLocation动态获取）
        pickup_datetime: dropoff_datetime,
        flight_number: nil,  # 送机服务不关联航班号（但客人需要赶飞机）
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
        departure_city: @departure_city,
        duration_days: @duration_days,
        duration_nights: @duration_nights,
        adult_count: @adult_count,
        departure_location: @departure_location,
        airport_location: @airport_location
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @expected_month = data['expected_month']
      @departure_port = data['departure_port']
      @departure_city = data['departure_city']
      @duration_days = data['duration_days']
      @duration_nights = data['duration_nights']
      @adult_count = data['adult_count']
      @departure_location = data['departure_location']
      @airport_location = data['airport_location']
      
      # 重新查询乘客信息（张三作为联系人和出行人员）
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
      @departure_loc = TransferLocation.where(
        city: @departure_city,
        location_type: 'other',
        data_version: 0
      ).find { |loc| loc.name.include?('外滩') }
      
      @departure_location = @departure_loc.name if @departure_loc
      
      @airport_loc = TransferLocation.where(
        city: @departure_city,
        location_type: 'airport',
        data_version: 0
      ).find { |loc| loc.name.include?('浦东') && loc.name.include?('T2') }
      
      @airport_location = @airport_loc.name if @airport_loc
      
      # 重新查询航班
      @reference_flights = Flight
        .where(departure_city: @departure_port, destination_city: '北京', data_version: 0)
        .where('EXTRACT(MONTH FROM flight_date) = ?', @expected_month)
        .where("departure_airport LIKE ?", "%浦东%")
        .to_a
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
      
      # 断言3: 行程天数正确
      add_assertion "行程天数正确（#{@duration_days}天#{@duration_nights}晚）", weight: 10 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expect(sailing.duration_days).to eq(@duration_days),
          "行程天数错误。期望: #{@duration_days}天, 实际: #{sailing.duration_days}天"
      end
      
      # 断言4: 创建了机场送机服务
      add_assertion "创建了机场送机服务", weight: 15 do
        @transfer = Transfer
          .where(transfer_type: 'airport_dropoff', data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@transfer).not_to be_nil, "未找到机场送机服务订单"
      end
      
      return if @transfer.nil?
      
      # 断言5: 送机服务地点正确（外滩→上海浦东国际机场T2）
      add_assertion "送机服务地点正确（外滩→上海浦东国际机场T2）", weight: 20 do
        expect(@transfer.location_from).to include('外滩'),
          "送机起点错误。期望包含: 外滩, 实际: #{@transfer.location_from}"
        expect(@transfer.location_to).to include('浦东'),
          "送机终点错误。期望包含: 浦东, 实际: #{@transfer.location_to}"
        expect(@transfer.location_to).to include('T2'),
          "送机终点航站楼错误。期望包含: T2, 实际: #{@transfer.location_to}"
      end
      
      # 断言6: 送机时间正确（邮轮结束后第6天下午14:00）
      add_assertion "送机时间正确（邮轮结束后第6天下午14:00）", weight: 15 do
        sailing = @cruise_order.cruise_product.cruise_sailing
        expected_dropoff_date = sailing.departure_date + (@duration_days - 1).days
        actual_dropoff_date = @transfer.pickup_datetime.to_date
        
        expect(actual_dropoff_date).to eq(expected_dropoff_date),
          "送机日期错误。期望: #{expected_dropoff_date}（邮轮第#{@duration_days}天返回），实际: #{actual_dropoff_date}"
        
        pickup_hour = @transfer.pickup_datetime.hour
        pickup_minute = @transfer.pickup_datetime.min
        expect(pickup_hour).to eq(14), "送机时间错误。期望: 下午14:00, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
        expect(pickup_minute).to eq(0), "送机时间错误。期望: 下午14:00, 实际: #{@transfer.pickup_datetime.strftime('%H:%M')}"
      end
      
      # 断言7: 联系人信息正确（张三）
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 5 do
        expect(@cruise_order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@cruise_order.contact_name}"
        expect(@cruise_order.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@cruise_order.contact_phone}"
      end
      
      # 断言8: 出行人员信息正确（2成人）
      add_assertion "出行人员信息正确（2成人）", weight: 5 do
        passengers = @cruise_order.passenger_info
        expect(passengers.size).to eq(2),
          "乘客数量错误。期望: 2人, 实际: #{passengers.size}人"
        
        adult_passengers = passengers.select { |p| p['passenger_type'] == 'adult' }
        expect(adult_passengers.size).to eq(2),
          "成人数量错误。期望: 2人, 实际: #{adult_passengers.size}人"
        
        passenger_names = passengers.map { |p| p['name'] }
        expect(passenger_names).to include(@passenger.name),
          "出行人员中未找到#{@passenger.name}"
        expect(passenger_names).to include('李四'),
          "出行人员中未找到李四"
      end
    end
  end
end
