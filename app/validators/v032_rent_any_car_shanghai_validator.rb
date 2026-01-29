# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例32: 租赁明天上海任意车辆（1天）
# 
# 任务描述:
#   Agent 需要在系统中搜索上海的租车服务，
#   选择任意一辆车并成功创建租赁1天的订单
# 
# 复杂度分析:
#   1. 需要搜索上海的租车服务
#   2. 需要选择"明天"取车日期
#   3. 需要计算1天的租期
#   ❌ 无车型价格限制，任意车辆即可
# 
# 评分标准:
#   - 订单已创建 (30分)
#   - 城市正确（上海） (30分)
#   - 取车日期正确（明天） (20分)
#   - 租赁天数正确（1天） (20分)
#
class V032RentAnyCarShanghaiValidator < BaseValidator
  self.validator_id = 'v032_rent_any_car_shanghai_validator'
  self.task_id = '1607085c-0377-4907-96a1-58b0b2a1791d'
  self.title = '租赁明天上海任意车辆（1天）'
  self.description = '搜索上海的租车服务，选择任意一辆车并租赁1天'
  self.timeout_seconds = 240
  
  def prepare
    @location = '上海'
    @rental_days = 1
    @pickup_date = Date.current + 1.day
    
    available_cars = Car.where(location: @location, data_version: 0)
    
    {
      task: "请租赁一辆明天在#{@location}取车的任意车辆（租期1天）",
      location: @location,
      rental_days: @rental_days,
      pickup_date: @pickup_date.to_s,
      pickup_date_description: "明天（#{@pickup_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多辆车可选，选择任意一辆即可",
      available_cars_count: available_cars.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 30 do
      @order = CarOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何租车订单记录"
    end
    
    return unless @order
    
    add_assertion "城市正确（上海）", weight: 30 do
      expect(@order.car.location).to eq(@location),
        "城市不正确。期望: #{@location}, 实际: #{@order.car.location}"
    end
    
    add_assertion "取车日期正确（明天）", weight: 20 do
      pickup_date = @order.pickup_datetime.to_date
      expect(pickup_date).to eq(@pickup_date),
        "取车日期不正确。期望: #{@pickup_date}, 实际: #{pickup_date}"
    end
    
    add_assertion "租赁天数正确（1天）", weight: 20 do
      return_date = @order.return_datetime.to_date
      pickup_date = @order.pickup_datetime.to_date
      actual_days = (return_date - pickup_date).to_i + 1
      
      expect(actual_days).to eq(@rental_days),
        "租赁天数不正确。期望: #{@rental_days}天, 实际: #{actual_days}天"
    end
  end
  
  private
  
  def execution_state_data
    { location: @location, rental_days: @rental_days, pickup_date: @pickup_date.to_s }
  end
  
  def restore_from_state(data)
    @location = data['location']
    @rental_days = data['rental_days']
    @pickup_date = Date.parse(data['pickup_date'])
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    target_car = Car.where(location: @location, data_version: 0).sample
    
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
    
    { action: 'create_car_order', car_model: "#{target_car.brand} #{target_car.car_model}" }
  end
end