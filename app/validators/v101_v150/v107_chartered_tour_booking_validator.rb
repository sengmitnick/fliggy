# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例107: 帮小明预订上海文化深度游包车（7座商务车，8小时，4人出行，明天出发）
#
# 任务描述:
#   用户想预订上海文化深度游包车，4人出行，明天出发。
#   要求选择7座商务车车型（座位数≥4人），包车时长8小时（文化深度游标准服务时长）。
#   Agent 需要在符合条件的路线和车型中，选择合适的包车产品，并填写联系人信息完成预订。
#
# 业务流程（5个关键步骤）：
#   1. 搜索上海城市的包车路线
#   2. 筛选文化深度游路线（category='classic'，路线名："上海文化深度游"）
#   3. 选择7座商务车车型（座位数≥4人，适合小团体出行）
#   4. 设置服务时长为8小时（文化深度游标准时长）
#   5. 填写出发日期（明天）、联系人信息并提交订单
#
# 复杂度分析（5个关键点）：
#   1. 需要理解路线筛选：category='classic'（文化深度游路线，非热门路线 'hot'）
#   2. 需要理解车型选择：7座商务车，座位数≥4人（能容纳小团体出行）
#   3. 需要理解服务时长：8小时（文化深度游标准服务时长）
#   4. 需要理解出发日期计算：明天（Date.tomorrow）
#   5. 需要理解包车预订模式：by_route（按路线预订）vs by_vehicle（按车型预订）
#   ❌ 不能随机选择：必须精确匹配路线类别（classic，不是 hot/featured）、车型座位数、服务时长
#
# 评分标准（7项，总计100分）：
#   - 订单已创建（30分）
#   - 路线正确（上海文化深度游，category='classic'）（20分）
#   - 包车时长正确（8小时）（15分）
#   - 车辆类型正确（7座商务车）（15分）
#   - 出发日期正确（明天）（10分）
#   - 联系人信息正确（小明）（5分）
#   - 订单总价合理（5分）
module V101V150
  class V107CharteredTourBookingValidator < BaseValidator
    self.validator_id = 'v107_chartered_tour_booking_validator'
    self.task_id = 'e9d3f5a7-2c8b-4e1f-a6d9-8b4c1f7e3a52'
    self.title = '帮小明预订上海文化深度游包车（7座商务车，8小时，4人出行，明天出发）'
    self.description = '预订上海文化深度游包车（7座商务车，4人出行，明天出发）'
    self.timeout_seconds = 240
  
    def prepare
      @city_name = '上海'
      @route_category = 'classic'  # 经典路线
      @duration_hours = 8           # 8小时包车
      @vehicle_seats = 7            # 7座商务车
      @passengers_count = 4         # 4位乘客
      @departure_date = Date.tomorrow  # 明天出发
    
      # 预查询乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      @expected_contact_name = @xiaoming.name
      @expected_contact_phone = @xiaoming.phone
    
      # 查询可用的包车路线（上海+经典路线）
      @available_routes = CharterRoute
        .joins(:city)
        .where(cities: { name: @city_name }, data_version: @data_version)
        .where(category: @route_category)
    
      # 查询可用车型
      @available_vehicle = VehicleType.find_by(seats: @vehicle_seats, data_version: 0)
    
      {
        task: "请预订#{@departure_date.strftime('%Y年%m月%d日')}的#{@city_name}文化深度游包车，#{@passengers_count}人出行，选择#{@vehicle_seats}座商务车车型，#{@duration_hours}小时服务",
        city: @city_name,
        route_category: @route_category == 'classic' ? '文化深度游' : '其他类型',
        vehicle_type: "#{@vehicle_seats}座商务车",
        duration_hours: @duration_hours,
        passengers_count: @passengers_count,
        departure_date: @departure_date.strftime('%Y-%m-%d'),
        route_name_hint: "上海文化深度游",
        hint: "1. 在包车游搜索页选择上海城市\n2. 浏览并选择'上海文化深度游'路线（category='classic'，注意不是'上海经典一日游'）\n3. 在车型选择页选择8小时服务时长\n4. 选择'7座商务车'车型（适合4人小团体出行）\n5. 填写联系人信息并提交订单",
        available_routes_count: @available_routes.count,
        vehicle_available: @available_vehicle.present?
      }
    end
  
    def verify
      # 断言1: 订单已创建（权重30%）
      add_assertion "创建了包车订单", weight: 30 do
        all_bookings = CharterBooking
          .joins(charter_route: :city)
          .includes(:charter_route, :vehicle_type)
          .where(charter_routes: { cities: { name: @city_name } })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何包车订单"
        
        # 筛选符合基本条件的订单（经典路线）
        @charter_bookings = all_bookings.select do |booking|
          booking.charter_route.category == @route_category
        end
        
        expect(@charter_bookings.size).to be >= 1, "未找到符合条件的包车订单"
      end
      
      return if @charter_bookings.nil? || @charter_bookings.empty?
    
      # 断言2: 路线正确（权重20%）
      add_assertion "路线正确（上海文化深度游，category='classic'）", weight: 20 do
        @charter_bookings.each do |booking|
          city_name = booking.charter_route.city.name
          category = booking.charter_route.category
          
          expect(city_name).to eq(@city_name),
            "城市错误。期望: #{@city_name}, 实际: #{city_name}"
          
          expect(category).to eq(@route_category),
            "路线类别错误。期望: #{@route_category}（经典路线），实际: #{category}"
        end
      end
    
      # 断言3: 服务时长正确（权重15%）
      # 验证包车时长为8小时（经典游标准服务时长）
      add_assertion "服务时长正确（8小时）", weight: 15 do
        @charter_bookings.each do |booking|
          duration = booking.duration_hours
          
          expect(duration).to eq(@duration_hours),
            "服务时长错误。期望: #{@duration_hours}小时, 实际: #{duration}小时"
          
          # 验证包车时长是8小时（经典游标准时长）
          expect(duration).to eq(8),
            "包车时长应为8小时（经典游标准），实际: #{duration}小时"
        end
      end
    
      # 断言4: 车型正确（权重15%）
      add_assertion "车型正确（7座商务车）", weight: 15 do
        @charter_bookings.each do |booking|
          vehicle_seats = booking.vehicle_type.seats
          
          expect(vehicle_seats).to eq(@vehicle_seats),
            "车型错误。期望: #{@vehicle_seats}座, 实际: #{vehicle_seats}座"
          
          # 验证座位数能容纳4人
          expect(vehicle_seats).to be >= @passengers_count,
            "车辆座位数不足。需要容纳#{@passengers_count}人，实际座位数: #{vehicle_seats}"
        end
      end
    
      # 断言5: 出发日期正确（权重10%）
      add_assertion "出发日期正确（明天）", weight: 10 do
        @charter_bookings.each do |booking|
          # 出发日期
          expect(booking.departure_date).to be_present,
            "缺少出发日期"
          
          expect(booking.departure_date).to eq(@departure_date),
            "出发日期错误。期望: #{@departure_date}（明天），实际: #{booking.departure_date}"
          
          expect(booking.departure_date).to be >= Date.current,
            "出发日期不能早于今天。实际: #{booking.departure_date}"
          
          # 出发时间
          expect(booking.departure_time).to be_present,
            "缺少出发时间"
          
          expect(booking.departure_time).to match(/\A\d{2}:\d{2}\z/),
            "出发时间格式错误: #{booking.departure_time}。期望格式: 09:00"
          
          # 预订模式
          expect(booking.booking_mode).to eq('by_route'),
            "预订模式错误。按路线预订应为'by_route'，实际: #{booking.booking_mode}"
        end
      end
    
      # 断言6: 联系人信息正确（权重5%）
      add_assertion "联系人信息正确（小明）", weight: 5 do
        @charter_bookings.each do |booking|
          # 联系人姓名
          expect(booking.contact_name).to be_present,
            "缺少联系人姓名"
          
          expect(booking.contact_name).to eq(@expected_contact_name),
            "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{booking.contact_name}"
          
          # 联系电话
          expect(booking.contact_phone).to be_present,
            "缺少联系电话"
          
          expect(booking.contact_phone).to eq(@expected_contact_phone),
            "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{booking.contact_phone}"
        end
      end
    
      # 断言7: 价格计算正确（权重5%）
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
        route_category: @route_category,
        duration_hours: @duration_hours,
        vehicle_seats: @vehicle_seats,
        passengers_count: @passengers_count,
        departure_date: @departure_date.to_s,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
  
    def restore_from_state(data)
      @city_name = data['city_name']
      @route_category = data['route_category']
      @duration_hours = data['duration_hours']
      @vehicle_seats = data['vehicle_seats']
      @passengers_count = data['passengers_count']
      @departure_date = Date.parse(data['departure_date'])
      @expected_contact_name = data['expected_contact_name'] || '小明'
      @expected_contact_phone = data['expected_contact_phone'] || '13500135001'
      @available_routes = CharterRoute
        .joins(:city)
        .where(cities: { name: @city_name }, data_version: @data_version)
        .where(category: @route_category)
    end
  
    def simulate
      # 查找演示用户（使用基线 data_version=0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: '0')
      xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
    
      # 查找路线（从基线数据中查找）
      route = CharterRoute.where(data_version: '0')
                          .joins(:city)
                          .where('cities.name = ?', @city_name)
                          .where(category: @route_category)
                          .first
      raise "未找到符合条件的路线（城市: #{@city_name}, 类别: #{@route_category}）" unless route
    
      # 查找车型（从基线数据中查找）
      vehicle_type = VehicleType.find_by(seats: @vehicle_seats, data_version: '0')
      raise "未找到符合条件的车型（#{@vehicle_seats}座）" unless vehicle_type
      
      # 验证座位数
      if vehicle_type.seats < @passengers_count
        raise "车型座位数（#{vehicle_type.seats}）不足以容纳#{@passengers_count}人"
      end
    
      # 使用服务计算价格
      price = CharterPriceCalculatorService.call(
        route: route,
        vehicle_type: vehicle_type,
        duration_hours: @duration_hours,
        departure_date: @departure_date
      )
    
      # 创建包车订单
      CharterBooking.create!(
        user_id: user.id,
        charter_route_id: route.id,
        vehicle_type_id: vehicle_type.id,
        departure_date: @departure_date,
        departure_time: '09:00',
        duration_hours: @duration_hours,
        booking_mode: 'by_route',
        passengers_count: @passengers_count,
        contact_name: xiaoming.name,
        contact_phone: xiaoming.phone,
        total_price: price,
        status: 'pending',
        data_version: @data_version
      )
    end
  end
end
