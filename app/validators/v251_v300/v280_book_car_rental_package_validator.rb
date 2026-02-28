# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例280: 预订包车游
#
# 任务描述:
#   用户预订深圳包车游（经典一日游路线）
#
# 评分标准:
#   - 创建包车游订单 (25%)
#   - 路线正确（深圳） (20%)
#   - 出发日期正确 (15%)
#   - 人数正确 (10%)
#   - 联系人信息正确 (15%)
#   - 订单状态正确 (15%)
module V251V300
  class V280BookCarRentalPackageValidator < BaseValidator
    self.validator_id = 'v280_book_car_rental_package_validator'
    self.task_id = 'f6d6a9af-de20-4b9c-85f2-f63ef9397045'
    self.title = '给张三预订深圳包车游（经典一日游）'
    self.description = '帮张三预订深圳包车游经典一日游路线'
    self.timeout_seconds = 300
    
    def prepare
      @city_name = '深圳'
      @passengers_count = 3
      @departure_date = Date.current + 2.days
      
      # 查找深圳的包车游路线
      @route = CharterRoute.joins(:city)
                           .where(cities: { name: @city_name }, data_version: 0)
                           .where('charter_routes.name LIKE ?', '%经典%')
                           .first!
      
      # 确保用户有足够余额
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 1000
        raise "用户余额不足。需要: ¥1000，当前: ¥#{user.balance}"
      end
      
      {
        task: "请预订#{@city_name}的包车游，选择经典一日游路线，#{@passengers_count}人，#{@departure_date.strftime('%Y年%-m月%-d日')}出发",
        city: @city_name,
        route_name: @route.name,
        passengers_count: @passengers_count,
        departure_date: @departure_date.to_s,
        hint: "包车游包含司机和导游服务，按路线预订"
      }
    end
    
    def verify
      add_assertion "创建了包车游订单", weight: 25 do
        @order = CharterBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到包车游订单"
      end
      
      return unless @order
      
      add_assertion "路线正确（#{@city_name}）", weight: 20 do
        route = @order.charter_route
        expect(route).not_to be_nil, "订单没有关联路线"
        expect(route.city.name).to eq(@city_name),
          "城市不匹配。期望: #{@city_name}, 实际: #{route.city.name}"
      end
      
      add_assertion "出发日期正确（#{@departure_date}）", weight: 15 do
        expect(@order.departure_date).to eq(@departure_date),
          "出发日期错误。期望: #{@departure_date}, 实际: #{@order.departure_date}"
      end
      
      add_assertion "人数正确（#{@passengers_count}人）", weight: 10 do
        expect(@order.passengers_count).to eq(@passengers_count),
          "人数错误。期望: #{@passengers_count}人, 实际: #{@order.passengers_count}人"
      end
      
      add_assertion "联系人信息正确", weight: 15 do
        expect(@order.contact_name).not_to be_nil, "未填写联系人姓名"
        expect(@order.contact_phone).not_to be_nil, "未填写联系人电话"
        expect(@order.contact_phone).to match(/^1[3-9]\d{9}$/),
          "电话号码格式错误。实际: #{@order.contact_phone}"
      end
      
      add_assertion "订单状态正确", weight: 15 do
        expect(@order.status).to eq('pending').or(eq('paid')),
          "订单状态错误。期望: pending/paid, 实际: #{@order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 查找深圳的经典一日游路线
      route = CharterRoute.joins(:city)
                          .where(cities: { name: @city_name }, data_version: 0)
                          .where('charter_routes.name LIKE ?', '%经典%')
                          .first!
      
      # 查找合适的车型
      vehicle_type = VehicleType.where(data_version: 0)
                                .where('seats >= ?', @passengers_count)
                                .order(:seats)
                                .first!
      
      CharterBooking.create!(
        user_id: user.id,
        charter_route_id: route.id,
        vehicle_type_id: vehicle_type.id,
        departure_date: @departure_date,
        departure_time: '09:00',
        duration_hours: 8,
        booking_mode: 'by_route',
        contact_name: '张三',
        contact_phone: '13800138000',
        passengers_count: @passengers_count,
        pickup_address: "#{@city_name}市中心",
        total_price: vehicle_type.hourly_price_8h,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city_name: @city_name,
        passengers_count: @passengers_count,
        departure_date: @departure_date&.to_s,
        route_id: @route&.id
      }
    end
    
    def restore_from_state(data)
      @city_name = data['city_name']
      @passengers_count = data['passengers_count']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @route = CharterRoute.find(data['route_id']) if data['route_id']
    end
  end
end
