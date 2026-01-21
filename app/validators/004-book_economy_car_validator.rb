# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例7: 租赁后天深圳的经济型轿车
# 
# 任务描述:
#   Agent 需要在系统中搜索深圳的租车服务，
#   找到经济型轿车（预算≤200元/天）并成功创建订单（3天）
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（深圳） (15分)
#   - 车辆类型正确（经济型轿车） (25分)
#   - 价格符合预算（≤200元/天） (25分)
#   - 租赁天数正确（3天） (15分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_economy_car_sz/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class BookEconomyCarValidator < BaseValidator
  self.validator_id = 'book_economy_car_sz'
  self.title = '租赁后天深圳的经济型轿车（3天，预算≤200元/天）'
  self.description = '搜索深圳的租车服务，找到经济型轿车（预算≤200元/天）并租赁3天'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @location = '深圳'
    @category = '经济轿车'
    @budget_per_day = 200
    @rental_days = 3
    @pickup_date = Date.current + 2.days  # 后天
    
    # 查找符合条件的车辆（用于后续验证）
    # 注意：查询基线数据 (data_version=0)
    suitable_cars = Car.where(
      location: @location,
      category: @category,
      data_version: 0
    ).where('price_per_day <= ?', @budget_per_day)
    
    @suitable_count = suitable_cars.count
    
    # 返回给 Agent 的任务信息
    {
      task: "请租赁一辆后天在#{@location}取车的#{@category}（3天），预算每天不超过#{@budget_per_day}元",
      location: @location,
      category: @category,
      budget_per_day: @budget_per_day,
      rental_days: @rental_days,
      pickup_date: @pickup_date.to_s,
      pickup_date_description: "后天（#{@pickup_date.strftime('%Y年%m月%d日')}）",
      hint: "系统中有多个符合条件的车辆可选，请选择经济型轿车",
      suitable_cars_count: @suitable_count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @order = CarOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何租车订单记录"
    end
    
    return unless @order # 如果没有订单，后续断言无法继续
    
    # 断言2: 城市正确
    add_assertion "城市正确（深圳）", weight: 15 do
      expect(@order.car.location).to eq(@location),
        "城市不正确。预期: #{@location}, 实际: #{@order.car.location}"
    end
    
    # 断言3: 车辆类型正确
    add_assertion "车辆类型正确（经济轿车）", weight: 25 do
      expect(@order.car.category).to eq(@category),
        "车辆类型不正确。预期: #{@category}, 实际: #{@order.car.category}"
    end
    
    # 断言4: 价格符合预算（核心评分项）
    add_assertion "价格符合预算（≤#{@budget_per_day}元/天）", weight: 25 do
      daily_price = @order.car.price_per_day
      
      expect(daily_price).to be <= @budget_per_day,
        "价格超出预算。预算: ≤#{@budget_per_day}元/天, 实际: #{daily_price}元/天"
    end
    
    # 断言5: 租赁天数正确
    add_assertion "租赁天数正确（3天）", weight: 15 do
      # 从订单中计算天数
      return_date = @order.return_datetime.to_date
      pickup_date = @order.pickup_datetime.to_date
      actual_days = (return_date - pickup_date).to_i
      
      expect(actual_days).to eq(@rental_days),
        "租赁天数不正确。预期: #{@rental_days}天, 实际: #{actual_days}天"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      location: @location,
      category: @category,
      budget_per_day: @budget_per_day,
      rental_days: @rental_days,
      pickup_date: @pickup_date.to_s,
      suitable_count: @suitable_count
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @location = data['location']
    @category = data['category']
    @budget_per_day = data['budget_per_day']
    @rental_days = data['rental_days']
    @pickup_date = Date.parse(data['pickup_date'])
    @suitable_count = data['suitable_count']
  end
  
  # 模拟 AI Agent 操作：租赁深圳经济型轿车
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的车辆（预算内）
    suitable_cars = Car.where(
      location: @location,
      category: @category,
      data_version: 0
    ).where('price_per_day <= ?', @budget_per_day)
    
    # 随机选择一辆
    target_car = suitable_cars.sample
    
    # 3. 创建订单（固定参数）
    total_price = target_car.price_per_day * @rental_days
    pickup_datetime = @pickup_date.to_time + 9.hours # 上午9点
    # 3天租期：第1天上午9点 -> 第3天下午6点（正好3天）
    return_datetime = (@pickup_date + (@rental_days - 1).days).to_time + 18.hours # 下午6点
    
    order = CarOrder.create!(
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
    
    # 返回操作信息
    {
      action: 'create_car_order',
      order_id: order.id,
      car_model: "#{target_car.brand} #{target_car.car_model}",
      daily_rate: target_car.price_per_day,
      rental_days: @rental_days,
      total_price: total_price,
      user_email: user.email
    }
  end
end
