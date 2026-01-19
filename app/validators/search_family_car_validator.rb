# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例8: 搜索成都适合家庭的7座SUV
# 
# 任务描述:
#   Agent 需要搜索成都的租车服务，
#   找到适合家庭的7座SUV并创建订单
# 
# 评分标准:
#   - 搜索到了符合条件的车辆 (20分)
#   - 城市正确（成都） (20分)
#   - 车辆类型正确（SUV） (30分)
#   - 座位数正确（7座） (30分)
# 
# 难点:
#   - 需要理解"适合家庭"的概念（7座）
#   - 需要筛选SUV类型
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/search_family_car_cd/prepare
#   
#   # Agent 通过界面操作完成搜索和预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class SearchFamilyCarValidator < BaseValidator
  self.validator_id = 'search_family_car_cd'
  self.title = '搜索成都适合家庭的7座SUV'
  self.description = '搜索成都的租车服务，找到适合家庭的7座SUV并租赁'
  self.timeout_seconds = 300
  
  # 准备阶段：插入测试数据
  def prepare
    # 数据已经通过 load_data_pack 自动加载
    @location = '成都'
    @category = 'SUV'
    @required_seats = 7
    
    # 查找符合条件的车辆（注意：查询基线数据）
    suitable_cars = Car.where(
      location: @location,
      category: @category,
      seats: @required_seats,
      data_version: 0
    )
    
    @suitable_count = suitable_cars.count
    
    # 返回给 Agent 的任务信息
    {
      task: "请搜索#{@location}适合家庭的#{@required_seats}座#{@category}并租赁",
      location: @location,
      category: @category,
      seats: @required_seats,
      hint: "适合家庭的车辆通常是7座SUV，空间大、舒适度高",
      suitable_cars_count: @suitable_count
    }
  end
  
  # 验证阶段：检查是否找到并预订了正确的车辆
  def verify
    # 断言1: 必须有订单创建
    add_assertion "订单已创建", weight: 20 do
      @order = CarOrder.order(created_at: :desc).first
      expect(@order).not_to be_nil, "未找到任何租车订单记录"
    end
    
    return unless @order
    
    # 断言2: 城市正确
    add_assertion "城市正确（成都）", weight: 20 do
      expect(@order.car.location).to eq(@location),
        "城市不正确。预期: #{@location}, 实际: #{@order.car.location}"
    end
    
    # 断言3: 车辆类型正确（核心评分）
    add_assertion "车辆类型正确（SUV）", weight: 30 do
      expect(@order.car.category).to eq(@category),
        "车辆类型不正确。预期: #{@category}, 实际: #{@order.car.category}"
    end
    
    # 断言4: 座位数正确（核心评分）
    add_assertion "座位数正确（7座）", weight: 30 do
      expect(@order.car.seats).to eq(@required_seats),
        "座位数不正确。预期: #{@required_seats}座, 实际: #{@order.car.seats}座"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      location: @location,
      category: @category,
      required_seats: @required_seats,
      suitable_count: @suitable_count
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @location = data['location']
    @category = data['category']
    @required_seats = data['required_seats']
    @suitable_count = data['suitable_count']
  end
  
  # 模拟 AI Agent 操作：搜索成都7座SUV并租赁
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的车辆
    suitable_cars = Car.where(
      location: @location,
      category: @category,
      seats: @required_seats,
      data_version: 0
    )
    
    # 随机选择一辆
    target_car = suitable_cars.sample
    
    # 3. 创建订单（固定参数）
    pickup_date = Date.current + 2.days
    rental_days = 3
    total_price = target_car.price_per_day * rental_days
    return_date = pickup_date + rental_days.days
    
    order = CarOrder.create!(
      car_id: target_car.id,
      user_id: user.id,
      pickup_date: pickup_date,
      return_date: return_date,
      rental_days: rental_days,
      daily_rate: target_car.price_per_day,
      total_price: total_price,
      pickup_location: target_car.pickup_location,
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_car_order',
      order_id: order.id,
      car_model: "#{target_car.brand} #{target_car.car_model}",
      seats: target_car.seats,
      category: target_car.category,
      daily_rate: target_car.price_per_day,
      rental_days: rental_days,
      total_price: total_price,
      user_email: user.email
    }
  end
end
