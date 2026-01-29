# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例34: 租赁明天深圳最便宜的车（租车1天，预算≤100元/天）
# 
# 任务描述:
#   Agent 需要在系统中搜索深圳的租车服务，
#   找到价格≤100元/天的车辆中最便宜的并成功创建租赁1天的订单
# 
# 复杂度分析:
#   1. 需要搜索深圳的租车服务
#   2. 需要选择"明天"取车日期
#   3. 需要筛选价格≤100元/天的车辆
#   4. 需要在符合预算的车辆中选择最便宜的
#   ❌ 价格优先，简化版性价比
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（深圳） (20分)
#   - 取车日期正确（明天） (20分)
#   - 价格符合预算（≤100元/天） (40分)
#
class V034RentCheapestCarShenzhenValidator < BaseValidator
  self.validator_id = 'v034_rent_cheapest_car_shenzhen_validator'
  self.task_id = '58fc94c1-6e60-45d2-8aea-c0fa3cc69ff6'
  self.title = '租赁明天深圳最便宜的车（预算≤100元/天）'
  self.description = '搜索深圳的租车服务，找到价格≤100元/天的车辆并租赁1天'
  self.timeout_seconds = 240
  
  def prepare
    @location = '深圳'
    @budget_per_day = 100
    @rental_days = 1
    @pickup_date = Date.current + 1.day
    
    eligible_cars = Car.where(location: @location, data_version: 0)
                       .where('price_per_day <= ?', @budget_per_day)
    
    @lowest_price = eligible_cars.minimum(:price_per_day)
    
    {
      task: "请租赁一辆明天在#{@location}取车的最便宜车辆（预算≤#{@budget_per_day}元/天，租期1天）",
      location: @location,
      budget_per_day: @budget_per_day,
      rental_days: @rental_days,
      pickup_date: @pickup_date.to_s,
      pickup_date_description: "明天（#{@pickup_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多辆符合预算的车辆，请选择价格最低的",
      eligible_cars_count: eligible_cars.count,
      lowest_price: @lowest_price
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @order = CarOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何租车订单记录"
    end
    
    return unless @order
    
    add_assertion "城市正确（深圳）", weight: 20 do
      expect(@order.car.location).to eq(@location)
    end
    
    add_assertion "取车日期正确（明天）", weight: 20 do
      pickup_date = @order.pickup_datetime.to_date
      expect(pickup_date).to eq(@pickup_date)
    end
    
    add_assertion "价格符合预算（≤#{@budget_per_day}元/天）", weight: 40 do
      daily_price = @order.car.price_per_day
      
      expect(daily_price <= @budget_per_day).to be_truthy,
        "价格超出预算。预算: ≤#{@budget_per_day}元/天, 实际: #{daily_price}元/天"
    end
  end
  
  private
  
  def execution_state_data
    { location: @location, budget_per_day: @budget_per_day, rental_days: @rental_days, pickup_date: @pickup_date.to_s }
  end
  
  def restore_from_state(data)
    @location = data['location']
    @budget_per_day = data['budget_per_day']
    @rental_days = data['rental_days']
    @pickup_date = Date.parse(data['pickup_date'])
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    target_car = Car.where(location: @location, data_version: 0)
                    .where('price_per_day <= ?', @budget_per_day)
                    .order(:price_per_day)
                    .first
    
    total_price = target_car.price_per_day * @rental_days
    pickup_datetime = @pickup_date.to_time.in_time_zone.change(hour: 9, min: 0)
    return_datetime = (@pickup_date + (@rental_days - 1).days).to_time.in_time_zone.change(hour: 18, min: 0)
    
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
    
    { action: 'create_car_order', car_model: "#{target_car.brand} #{target_car.car_model}", daily_rate: target_car.price_per_day }
  end
end