# frozen_string_literal: true

require_relative '../base_validator'

# V253: 给刘强等3人预订明天杭州经典一日游包车（舒适5座，8小时）
#
# 任务描述:
#   刘强等3人计划明天在杭州进行经典一日游，需要预订包车服务。
#   要求选择舒适5座车型，包车时长8小时（一日游标准服务时长）。
#   Agent 需要在符合条件的路线和车型中，选择合适的包车产品，并填写联系人信息完成预订。
#
# 业务流程（6个关键步骤）：
#   1. 搜索杭州城市的包车路线
#   2. 筛选路线名包含"经典一日游"的路线
#   3. 选择舒适5座车型
#   4. 设置服务时长为8小时（一日游标准服务时长）
#   5. 填写出发日期（明天）、联系人信息（刘强）
#   6. 提交订单并验证价格计算正确性
#
# 复杂度分析（5个关键点）：
#   1. 需要理解路线筛选：路线名包含"经典一日游"
#   2. 需要理解车型选择：舒适5座（适合3人小团队）
#   3. 需要理解服务时长：8小时（一日游标准服务时长）
#   4. 需要理解出发日期计算：明天（Date.current + 1.day）
#   5. 需要理解联系人选择：刘强及其电话号码
#   ❌ 不能随机选择：必须精确匹配路线关键词、车型名称、服务时长
#
# 评分标准（7项，总计100分）：
#   - 创建了包车订单（25分）
#   - 路线正确（杭州经典一日游）（15分）
#   - 车型正确（舒适5座）（20分）
#   - 服务时长正确（8小时）（15分）
#   - 出发日期正确（明天）（10分）
#   - 联系人信息正确（刘强）（10分）
#   - 价格计算正确（5分）
module V251V300
  class V253BookHangzhouClassicOneDayCharteredTourValidator < BaseValidator
    self.validator_id = 'v253_book_hangzhou_classic_one_day_chartered_tour_validator'
    self.task_id = '7e2b48e7-d591-4752-b3d8-405b73a258f5'
    self.title = '给刘强等3人预订明天杭州经典一日游包车（舒适5座，8小时）'
    self.description = '给刘强等3人预订明天杭州经典一日游包车（舒适5座，8小时）'
    self.timeout_seconds = 240
  
    def prepare
      @city_name = '杭州'
      @route_keyword = '经典一日游'
      @vehicle_type_name = '舒适5座'
      @duration_hours = 8
      @passenger_count = 3
      @travel_date = Date.current + 1.day
    
      # 查询 demo_user 和乘客信息（基线数据）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @expected_contact_name = @liuqiang.name
      @expected_contact_phone = @liuqiang.phone
    
      # 查询可用路线
      @available_routes = CharterRoute.where(data_version: @data_version)
                                      .joins(:city)
                                      .where('cities.name = ?', @city_name)
                                      .where('charter_routes.name LIKE ?', "%#{@route_keyword}%")
    
      # 查询可用车型
      @available_vehicle = VehicleType.find_by(name: @vehicle_type_name, data_version: @data_version)
    
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}的#{@city_name}#{@route_keyword}包车路线，选择#{@vehicle_type_name}车型，#{@duration_hours}小时服务",
        city: @city_name,
        route_keyword: @route_keyword,
        vehicle_type: @vehicle_type_name,
        duration_hours: @duration_hours,
        passenger_count: @passenger_count,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        hint: "1. 在包车游搜索页选择杭州城市\n2. 浏览并选择包含'经典一日游'的路线\n3. 在车型选择页选择8小时服务时长\n4. 选择'舒适5座'车型\n5. 填写联系人信息并提交订单",
        available_routes_count: @available_routes.count,
        vehicle_available: @available_vehicle.present?
      }
    end
  
    def verify
      # 断言1: 订单已创建（权重25%）
      add_assertion "创建了包车订单", weight: 25 do
        all_bookings = CharterBooking
          .joins(charter_route: :city)
          .includes(:charter_route, :vehicle_type)
          .where(charter_routes: { cities: { name: @city_name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何包车订单"
        
        # 筛选符合基本条件的订单
        @charter_bookings = all_bookings.select do |booking|
          booking.charter_route.name.include?(@route_keyword)
        end
        
        expect(@charter_bookings.size).to be >= 1, "未找到符合条件的包车订单"
      end
      
      return if @charter_bookings.nil? || @charter_bookings.empty?
      
      # 断言2: 路线正确（权重15%）
      add_assertion "路线正确（杭州经典一日游）", weight: 15 do
        @charter_bookings.each do |booking|
          route_name = booking.charter_route.name
          city_name = booking.charter_route.city.name
          
          expect(city_name).to eq(@city_name),
            "城市错误。期望: #{@city_name}, 实际: #{city_name}"
          
          expect(route_name).to include(@route_keyword),
            "路线名称错误。期望包含: #{@route_keyword}, 实际: #{route_name}"
        end
      end
      
      # 断言3: 车型正确（权重20%）
      add_assertion "车型正确（舒适5座）", weight: 20 do
        @charter_bookings.each do |booking|
          vehicle_name = booking.vehicle_type.name
          vehicle_seats = booking.vehicle_type.seats
          
          expect(vehicle_name).to eq(@vehicle_type_name),
            "车型错误。期望: #{@vehicle_type_name}, 实际: #{vehicle_name}"
          
          # 验证座位数（前端无人数选择，默认1人）
          expect(vehicle_seats).to be >= 1,
            "车辆座位数不足。实际座位数: #{vehicle_seats}"
        end
      end
      
      # 断言4: 服务时长正确（权重15%）
      # 验证包车时长为8小时（一日游标准服务时长）
      add_assertion "服务时长正确（8小时）", weight: 15 do
        @charter_bookings.each do |booking|
          duration = booking.duration_hours
          
          expect(duration).to eq(@duration_hours),
            "服务时长错误。期望: #{@duration_hours}小时, 实际: #{duration}小时"
        end
      end
      
      # 断言5: 出发日期正确（权重10%）
      add_assertion "出发日期正确（明天#{@travel_date}）", weight: 10 do
        @charter_bookings.each do |booking|
          expect(booking.departure_date).to eq(@travel_date),
            "出发日期错误。期望: #{@travel_date}（明天），实际: #{booking.departure_date}"
        end
      end
      
      # 断言6: 联系人信息正确（权重10%）
      add_assertion "联系人信息正确（刘强）", weight: 10 do
        @charter_bookings.each do |booking|
          expect(booking.contact_name).to eq(@expected_contact_name),
            "联系人姓名错误。期望: #{@expected_contact_name}，实际: #{booking.contact_name}"
          
          expect(booking.contact_phone).to eq(@expected_contact_phone),
            "联系电话错误。期望: #{@expected_contact_phone}，实际: #{booking.contact_phone}"
        end
      end
      
      # 断言7: 价格计算正确 (5分)
      add_assertion "价格计算正确", weight: 5 do
        @charter_bookings.each do |booking|
          # 使用服务重新计算价格
          expected_price = CharterPriceCalculatorService.call(
            route: booking.charter_route,
            vehicle_type: booking.vehicle_type,
            duration_hours: booking.duration_hours,
            departure_date: booking.departure_date
          )
          
          actual_price = booking.total_price
          
          # 允许1元的误差（四舍五入）
          price_diff = (expected_price - actual_price).abs
          
          expect(price_diff).to be < 1.0,
            "价格计算错误。期望: ¥#{expected_price.round(1)}, 实际: ¥#{actual_price.round(1)}"
        end
      end
    end
  
    def execution_state_data
      {
        city_name: @city_name,
        route_keyword: @route_keyword,
        vehicle_type_name: @vehicle_type_name,
        duration_hours: @duration_hours,
        passenger_count: @passenger_count,
        travel_date: @travel_date.to_s,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
  
    def restore_from_state(data)
      @city_name = data['city_name']
      @route_keyword = data['route_keyword']
      @vehicle_type_name = data['vehicle_type_name']
      @duration_hours = data['duration_hours']
      @passenger_count = data['passenger_count']
      @travel_date = Date.parse(data['travel_date'])
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  
    def simulate
      # 查找演示用户（使用基线 data_version=0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: '0')
    
      # 查找路线（从基线数据中查找）
      route = CharterRoute.where(data_version: '0')
                          .joins(:city)
                          .where('cities.name = ?', @city_name)
                          .where('charter_routes.name LIKE ?', "%#{@route_keyword}%")
                          .first
      raise "未找到符合条件的路线（城市: #{@city_name}, 关键词: #{@route_keyword}）" unless route
    
      # 查找车型（从基线数据中查找）
      vehicle_type = VehicleType.find_by(name: @vehicle_type_name, data_version: '0')
      raise "未找到符合条件的车型（#{@vehicle_type_name}）" unless vehicle_type
      
      # 验证座位数（前端无人数选择，默认1人）
      if vehicle_type.seats < 1
        raise "车型座位数不足（#{vehicle_type.seats}座）"
      end
    
      # 使用服务计算价格
      price = CharterPriceCalculatorService.call(
        route: route,
        vehicle_type: vehicle_type,
        duration_hours: @duration_hours,
        departure_date: @travel_date
      )
    
      # 创建订单
      CharterBooking.create!(
        user_id: user.id,
        charter_route_id: route.id,
        vehicle_type_id: vehicle_type.id,
        departure_date: @travel_date,
        departure_time: '09:30',
        duration_hours: @duration_hours,
        booking_mode: 'by_route',
        passengers_count: @passenger_count,
        contact_name: @liuqiang.name,
        contact_phone: @liuqiang.phone,
        total_price: price,
        status: 'pending',
        data_version: @data_version
      )
    end
  end
end
