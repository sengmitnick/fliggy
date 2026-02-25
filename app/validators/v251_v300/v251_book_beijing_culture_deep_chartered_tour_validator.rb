# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例251: 给张三和李四预订北京文化深度游包车（5天后出发，豪华5座，6小时）
#
# 核心验证点:
# 1. 路线选择: 北京文化深度游
# 2. 车型选择: 豪华5座
# 3. 包车时长: 6小时（半日游标准时长）
# 4. 出发日期: 5天后（Date.current + 5.days）
# 5. 联系人信息: 张三、李四任选其一
# 6. 订单信息完整性
module V251V300
  class V251BookBeijingCultureDeepCharteredTourValidator < BaseValidator
    self.validator_id = 'v251_book_beijing_culture_deep_chartered_tour_validator'
    self.task_id = '61645ce7-e573-42d2-b80e-c5bfe1d863db'
    self.title = '给张三和李四预订北京文化深度游包车（5天后出发，豪华5座，6小时）'
    self.description = '给张三和李四预订北京文化深度游包车（5天后出发，豪华5座，6小时）'
    self.timeout_seconds = 240
  
    def prepare
      @city_name = '北京'
      @route_keyword = '文化深度游'
      @vehicle_type_name = '豪华5座'
      @duration_hours = 6
      @passenger_count = 2
      @travel_date = Date.current + 5.days
    
      # 查询 demo_user 和乘客信息（基线数据）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_contact_names = [@zhangsan.name, @lisi.name]
      @expected_contact_phones = { '张三' => @zhangsan.phone, '李四' => @lisi.phone }
    
      # 查询可用路线
      @available_routes = CharterRoute.where(data_version: @data_version)
                                      .joins(:city)
                                      .where('cities.name = ?', @city_name)
                                      .where('charter_routes.name LIKE ?', "%#{@route_keyword}%")
    
      # 查询可用车型
      @available_vehicle = VehicleType.find_by(name: @vehicle_type_name, data_version: @data_version)
    
      {
        task: "请预订#{@travel_date.strftime('%Y年%m月%d日')}的#{@city_name}#{@route_keyword}包车路线，选择#{@vehicle_type_name}车型，#{@duration_hours}小时服务（半日游）",
        city: @city_name,
        route_keyword: @route_keyword,
        vehicle_type: @vehicle_type_name,
        duration_hours: @duration_hours,
        passenger_count: @passenger_count,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        hint: "1. 在包车游搜索页选择北京城市\n2. 浏览并选择包含'文化深度游'的路线\n3. 在车型选择页选择6小时服务时长\n4. 选择'豪华5座'车型\n5. 填写联系人信息并提交订单",
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
      add_assertion "路线正确（北京文化深度游）", weight: 15 do
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
      add_assertion "车型正确（豪华5座）", weight: 20 do
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
      # 验证包车时长为6小时（半日游标准服务时长）
      add_assertion "服务时长正确（6小时）", weight: 15 do
        @charter_bookings.each do |booking|
          duration = booking.duration_hours
          
          expect(duration).to eq(@duration_hours),
            "服务时长错误。期望: #{@duration_hours}小时, 实际: #{duration}小时"
        end
      end
      
      # 断言5: 出发日期正确（权重10%）
      add_assertion "出发日期正确（5天后#{@travel_date}）", weight: 10 do
        @charter_bookings.each do |booking|
          expect(booking.departure_date).to be_present,
            "缺少出发日期"
          
          expect(booking.departure_date).to eq(@travel_date),
            "出发日期错误。期望: #{@travel_date}（5天后），实际: #{booking.departure_date}"
        end
      end
      
      # 断言6: 联系人信息正确（权重10%）
      # 张三、李四任选其一，电话号码需匹配
      add_assertion "联系人信息正确（张三或李四）", weight: 10 do
        @charter_bookings.each do |booking|
          # 验证联系人姓名
          expect(@expected_contact_names).to include(booking.contact_name),
            "联系人姓名错误。期望: 张三或李四，实际: #{booking.contact_name}"
          
          # 验证电话号码与联系人匹配
          expected_phone = @expected_contact_phones[booking.contact_name]
          expect(booking.contact_phone).to eq(expected_phone),
            "联系电话与联系人不匹配。联系人: #{booking.contact_name}，期望电话: #{expected_phone}，实际电话: #{booking.contact_phone}"
        end
      end
      
      # 断言7: 订单信息完整（权重5%）
      # 验证出发时间格式、预订模式
      add_assertion "订单信息完整", weight: 5 do
        @charter_bookings.each do |booking|
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
      
      # 断言8: 价格计算正确（权重5%）
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
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end
  
    def restore_from_state(data)
      @city_name = data['city_name']
      @route_keyword = data['route_keyword']
      @vehicle_type_name = data['vehicle_type_name']
      @duration_hours = data['duration_hours']
      @passenger_count = data['passenger_count']
      @travel_date = Date.parse(data['travel_date'])
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
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
    
      # 随机选择联系人（张三或李四）
      selected_contact = [@zhangsan, @lisi].sample
    
      # 创建订单
      CharterBooking.create!(
        user_id: user.id,
        charter_route_id: route.id,
        vehicle_type_id: vehicle_type.id,
        departure_date: @travel_date,
        departure_time: '09:00',
        duration_hours: @duration_hours,
        booking_mode: 'by_route',
        passengers_count: @passenger_count,
        contact_name: selected_contact.name,
        contact_phone: selected_contact.phone,
        total_price: price,
        status: 'pending',
        data_version: @data_version
      )
    end
  end
end
