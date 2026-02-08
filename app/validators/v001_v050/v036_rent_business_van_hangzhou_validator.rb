# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例36: 租赁明天杭州商务车（租车2天，5座以上）
# 
# 任务描述:
#   Agent 需要在系统中搜索杭州的租车服务，
#   找到商务车车型（5座以上）并成功创建租赁2天的订单
# 
# 复杂度分析:
#   1. 需要搜索杭州的租车服务
#   2. 需要选择"明天"取车日期
#   3. 需要筛选商务车车型
#   4. 需要验证座位数≥5
#   ❌ 车型+座位数筛选，无价格限制
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（杭州） (20分)
#   - 车型正确（商务车） (30分)
#   - 座位数符合要求（≥5座） (30分)
#
module V001V050
  class V036RentBusinessVanHangzhouValidator < BaseValidator
    self.validator_id = 'v036_rent_business_van_hangzhou_validator'
    self.task_id = '73f0ea71-c91a-4c62-b5f0-fcaadc96b5a7'
    self.title = '帮张三租明天杭州商务车（2天，5座以上）'
    self.description = '搜索杭州的租车服务，找到商务车车型（5座以上）并租赁2天'
    self.timeout_seconds = 240
  
    def prepare
      @location = '杭州'
      @category = '商务车'
      @min_seats = 5
      @rental_days = 2
      @pickup_date = Date.current + 1.day
    
      suitable_cars = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).where('seats >= ?', @min_seats)
    
      {
        task: "帮张三租一辆明天在#{@location}取车的#{@category}（5座以上，租期2天）",
        location: @location,
        category: @category,
        min_seats: @min_seats,
        rental_days: @rental_days,
        pickup_date: @pickup_date.to_s,
        pickup_date_description: "明天（#{@pickup_date.strftime('%Y年%m月%d日')}）",
        hint: "系统中有多辆商务车可选，请选择5座以上的车型",
        suitable_cars_count: suitable_cars.count
      }
    end
  
    def verify
      add_assertion "订单已创建", weight: 15 do
        all_orders = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何租车订单记录"
        @order = all_orders.first
      end
    
      return unless @order
    
      add_assertion "城市正确（杭州）", weight: 15 do
        expect(@order.car.location).to eq(@location)
      end
    
      add_assertion "取车日期正确（明天 #{@pickup_date.strftime('%Y-%m-%d')}）", weight: 15 do
        pickup_date = @order.pickup_datetime.to_date
        expect(pickup_date).to eq(@pickup_date),
          "取车日期不正确。期望: #{@pickup_date}（明天）, 实际: #{pickup_date}"
      end
    
      add_assertion "车型正确（商务车）", weight: 25 do
        expect(@order.car.category).to eq(@category),
          "车型不正确。期望: #{@category}, 实际: #{@order.car.category}"
      end
    
      add_assertion "座位数符合要求（≥5座）", weight: 20 do
        seats = @order.car.seats
        expect(seats >= @min_seats).to be_truthy,
          "座位数不符合要求。要求: ≥#{@min_seats}座, 实际: #{seats}座"
      end
    
      add_assertion "驾驶人信息正确（张三 13800138000）", weight: 10 do
        expect(@order.driver_name).to eq('张三'),
          "驾驶人姓名错误。期望: 张三（demo_user数据）, 实际: #{@order.driver_name}"
        expect(@order.contact_phone).to eq('13800138000'),
          "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@order.contact_phone}"
        expect(@order.driver_id_number).to eq('110101199001011234'),
          "身份证号错误。期望: 110101199001011234（demo_user数据）, 实际: #{@order.driver_id_number}"
      end
    end
  
    private
  
    def execution_state_data
      { location: @location, category: @category, min_seats: @min_seats, rental_days: @rental_days, pickup_date: @pickup_date.to_s }
    end
  
    def restore_from_state(data)
      @location = data['location']
      @category = data['category']
      @min_seats = data['min_seats']
      @rental_days = data['rental_days']
      @pickup_date = Date.parse(data['pickup_date'])
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
      target_car = Car.where(
        location: @location,
        category: @category,
        data_version: 0
      ).where('seats >= ?', @min_seats).sample
    
      total_price = target_car.price_per_day * @rental_days
      pickup_datetime = @pickup_date.to_time.in_time_zone.change(hour: 9, min: 0)
      return_datetime = (@pickup_date + (@rental_days - 1).days).to_time.in_time_zone.change(hour: 18, min: 0)
    
      CarOrder.create!(
        car_id: target_car.id,
        user_id: user.id,
        driver_name: passenger.name,
        driver_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        pickup_datetime: pickup_datetime,
        return_datetime: return_datetime,
        pickup_location: target_car.pickup_location,
        status: 'pending',
        total_price: total_price,
        data_version: @data_version
      )
    
      { action: 'create_car_order', car_model: "#{target_car.brand} #{target_car.car_model}", seats: target_car.seats }
    end
    end
end
