# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例35: 租赁后天广州豪华轿车（租车3天）
# 
# 任务描述:
#   Agent 需要在系统中搜索广州的租车服务，
#   找到豪华轿车车型并成功创建租赁3天的订单
# 
# 复杂度分析:
#   1. 需要搜索广州的租车服务
#   2. 需要选择"后天"取车日期
#   3. 需要筛选豪华轿车车型
#   4. 需要计算3天的租期
#   ❌ 车型分类，无价格限制
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（广州） (20分)
#   - 车型正确（豪华轿车） (30分)
#   - 租赁天数正确（3天） (30分)
#
class V035RentLuxuryCarGuangzhouValidator < BaseValidator
  self.validator_id = 'v035_rent_luxury_car_guangzhou_validator'
  self.task_id = '024489de-0ebb-4238-ac62-d5adef07a43e'
  self.title = '租赁后天广州豪华轿车（3天）'
  self.description = '搜索广州的租车服务，找到豪华轿车车型并租赁3天'
  self.timeout_seconds = 240
  
  def prepare
    @location = '广州'
    @category = '豪华轿车'
    @rental_days = 3
    @pickup_date = Date.current + 2.days
    
    suitable_cars = Car.where(
      location: @location,
      category: @category,
      data_version: 0
    )
    
    {
      task: "请租赁一辆后天在#{@location}取车的#{@category}（租期3天）",
      location: @location,
      category: @category,
      rental_days: @rental_days,
      pickup_date: @pickup_date.to_s,
      pickup_date_description: "后天（#{@pickup_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多辆豪华轿车可选，选择车型正确即可",
      suitable_cars_count: suitable_cars.count
    }
  end
  
  def verify
    add_assertion "订单已创建", weight: 20 do
      @order = CarOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何租车订单记录"
    end
    
    return unless @order
    
    add_assertion "城市正确（广州）", weight: 20 do
      expect(@order.car.location).to eq(@location)
    end
    
    add_assertion "车型正确（豪华轿车）", weight: 30 do
      expect(@order.car.category).to eq(@category),
        "车型不正确。期望: #{@category}, 实际: #{@order.car.category}"
    end
    
    add_assertion "租赁天数正确（3天）", weight: 30 do
      return_date = @order.return_datetime.to_date
      pickup_date = @order.pickup_datetime.to_date
      actual_days = (return_date - pickup_date).to_i + 1
      
      expect(actual_days).to eq(@rental_days),
        "租赁天数不正确。期望: #{@rental_days}天, 实际: #{actual_days}天"
    end
  end
  
  private
  
  def execution_state_data
    { location: @location, category: @category, rental_days: @rental_days, pickup_date: @pickup_date.to_s }
  end
  
  def restore_from_state(data)
    @location = data['location']
    @category = data['category']
    @rental_days = data['rental_days']
    @pickup_date = Date.parse(data['pickup_date'])
  end
  
  def simulate
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    target_car = Car.where(
      location: @location,
      category: @category,
      data_version: 0
    ).sample
    
    raise "No car found in #{@location} with category #{@category}" if target_car.nil?
    
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