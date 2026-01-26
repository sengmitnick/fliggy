# frozen_string_literal: true

require_relative 'base_validator'

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
class V036RentBusinessVanHangzhouValidator < BaseValidator
  self.validator_id = 'v036_rent_business_van_hangzhou_validator'
  self.title = '租赁明天杭州商务车（2天，5座以上）'
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
      task: "请租赁一辆明天在#{@location}取车的#{@category}（5座以上，租期2天）",
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
    add_assertion "订单已创建", weight: 20 do
      @order = CarOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何租车订单记录"
    end
    
    return unless @order
    
    add_assertion "城市正确（杭州）", weight: 20 do
      expect(@order.car.location).to eq(@location)
    end
    
    add_assertion "车型正确（商务车）", weight: 30 do
      expect(@order.car.category).to eq(@category),
        "车型不正确。期望: #{@category}, 实际: #{@order.car.category}"
    end
    
    add_assertion "座位数符合要求（≥5座）", weight: 30 do
      seats = @order.car.seats
      expect(seats >= @min_seats).to be_truthy,
        "座位数不符合要求。要求: ≥#{@min_seats}座, 实际: #{seats}座"
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
    
    target_car = Car.where(
      location: @location,
      category: @category,
      data_version: 0
    ).where('seats >= ?', @min_seats).sample
    
    total_price = target_car.price_per_day * @rental_days
    pickup_datetime = @pickup_date.to_time + 9.hours
    return_datetime = (@pickup_date + (@rental_days - 1).days).to_time + 18.hours
    
    CarOrder.create!(
      car_id: target_car.id,
      user_id: user.id,
      driver_name: '张三',
      driver_id_number: '110101199001011234',
      contact_phone: '13800138000',
      pickup_datetime: pickup_datetime,
      return_datetime: return_datetime,
      pickup_location: target_car.pickup_location,
      status: 'pending',
      total_price: total_price
    )
    
    { action: 'create_car_order', car_model: "#{target_car.brand} #{target_car.car_model}", seats: target_car.seats }
  end
end
