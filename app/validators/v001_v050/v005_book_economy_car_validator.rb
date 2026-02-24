# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 帮张三在深圳宝安机场GTC地面交通中心租一辆经济型轿车（后天取车，租3天，预算≤200元/天）
# 
# 任务描述:
#   Agent 需要在系统中搜索深圳的租车服务，
#   找到经济型轿车（预算≤200元/天）并成功创建租车3天的订单
#   
#   租赁要求:
#     - 城市: 深圳
#     - 车型: 经济型轿车
#     - 取车地点: 宝安机场GTC地面交通中心（指定取车点以确保测试可预测性）
#     - 取车日期: 后天（当前日期 + 2天）
#     - 还车日期: 取车后第3天（租赁3天）
#     - 预算: 每天不超过200元
#     - 总租赁时长: 3天
#   
#   示例: 如果今天是1月10日
#     - 取车时间: 1月12日 09:00
#     - 还车时间: 1月15日 18:00
#     - 租赁天数: 3天（1月12日-14日，共3个日历日）
#   
#   注意: 租赁天数计算公式为 (还车日期 - 取车日期).days
#         例如: 2月26日00:00 到 3月1日00:00 = 3天（26、27、28三个日历日）
# 
# 评分标准:
#   - 订单已创建 (15分)
#   - 城市正确（深圳） (10分)
#   - 车辆类型正确（经济轿车） (20分)
#   - 取车地点正确（宝安机场GTC地面交通中心） (10分)
#   - 价格符合预算（≤200元/天） (20分)
#   - 取车日期正确（后天） (10分)
#   - 租赁天数正确（3天） (10分)
#   - 驾驶员信息正确（张三 13800138000） (5分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_economy_car_sz/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V005BookEconomyCarValidator < BaseValidator
    self.validator_id = 'v005_book_economy_car_validator'
    self.task_id = 'd62b9468-fc02-43ad-aa50-642bf54d0bc1'
    self.title = '帮张三租后天深圳的经济型轿车（3天，预算≤200元/天）'
    self.description = '帮张三在深圳宝安机场GTC地面交通中心租一辆经济型轿车（后天取车，租3天，预算≤200元/天）'
    self.timeout_seconds = 300
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @location = '深圳'
      @category = '经济轿车'
      @budget_per_day = 200
      @rental_days = 3
      @pickup_date = Date.current + 2.days  # 后天
      @pickup_location = '宝安机场GTC地面交通中心'  # 指定取车点，确保测试可预测
    
      # 查找符合条件的车辆（用于后续验证）
      # 注意：
      #   1. 查询基线数据 (data_version=0)
      #   2. 必须指定取车点，因为不同取车点的车型和价格不同
      #      深圳共有4个取车点，车型各不相同，需指定以确保测试可预测性
      suitable_cars = Car.where(
        location: @location,
        category: @category,
        pickup_location: @pickup_location,
        data_version: 0
      ).where('price_per_day <= ?', @budget_per_day)
    
      @suitable_count = suitable_cars.count
    
      # 返回给 Agent 的任务信息
      {
        task: "帮张三租后天深圳的经济型轿车（3天，预算≤200元/天）",
        location: @location,
        category: @category,
        budget_per_day: @budget_per_day,
        rental_days: @rental_days,
        pickup_date: @pickup_date.to_s,
        pickup_date_description: "后天（#{@pickup_date.strftime('%Y年%m月%d日')}）",
        return_date: (@pickup_date + @rental_days).to_s,
        return_date_description: "#{@rental_days}天后（#{(@pickup_date + @rental_days).strftime('%Y年%m月%d日')}）",
        hint: "深圳#{@pickup_location}有#{@suitable_count}辆符合条件的经济轿车",
        pickup_location: @pickup_location,
        suitable_cars_count: @suitable_count
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（最近创建的一条）
      add_assertion "订单已创建", weight: 15 do
        all_orders = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何租车订单记录"
        @order = all_orders.first
      end
    
      return unless @order # 如果没有订单，后续断言无法继续
    
      # 断言2: 城市正确
      add_assertion "城市正确（深圳）", weight: 10 do
        expect(@order.car.location).to eq(@location),
          "城市不正确。预期: #{@location}, 实际: #{@order.car.location}"
      end
    
      # 断言3: 车辆类型正确
      add_assertion "车辆类型正确（经济轿车）", weight: 20 do
        expect(@order.car.category).to eq(@category),
          "车辆类型不正确。预期: #{@category}, 实际: #{@order.car.category}"
      end
    
      # 断言4: 取车地点正确（确保测试可预测性）
      add_assertion "取车地点正确（#{@pickup_location}）", weight: 10 do
        expect(@order.car.pickup_location).to eq(@pickup_location),
          "取车地点不正确。预期: #{@pickup_location}, 实际: #{@order.car.pickup_location}"
      end
    
      # 断言5: 价格符合预算（核心评分项）
      add_assertion "价格符合预算（≤#{@budget_per_day}元/天）", weight: 20 do
        daily_price = @order.car.price_per_day
      
        expect(daily_price).to be <= @budget_per_day,
          "价格超出预算。预算: ≤#{@budget_per_day}元/天, 实际: #{daily_price}元/天"
      end
    
      # 断言6: 取车日期正确
      add_assertion "取车日期正确（后天 #{@pickup_date.strftime('%Y-%m-%d')}）", weight: 10 do
        pickup_date = @order.pickup_datetime.to_date
      
        expect(pickup_date).to eq(@pickup_date),
          "取车日期不正确。预期: #{@pickup_date}（后天）, 实际: #{pickup_date}"
      end
    
      # 断言7: 租赁天数正确
      add_assertion "租赁天数正确（3天）", weight: 10 do
        # 从订单中计算天数（日期差，不加1）
        # 公式: (还车日期 - 取车日期).days
        # 例如: 2月26日 到 3月1日 = 3天（26、27、28三个日历日）
        return_date = @order.return_datetime.to_date
        pickup_date = @order.pickup_datetime.to_date
        actual_days = (return_date - pickup_date).to_i
      
        expect(actual_days).to eq(@rental_days),
          "租赁天数不正确。预期: #{@rental_days}天, 实际: #{actual_days}天"
      end
    
      # 断言8: 驾驶员信息正确（来自 demo_user）
      add_assertion "驾驶员信息正确（张三 13800138000）", weight: 5 do
        expect(@order.driver_name).to eq('张三'),
          "驾驶员姓名错误。期望: 张三（demo_user数据）, 实际: #{@order.driver_name}"
        expect(@order.contact_phone).to eq('13800138000'),
          "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@order.contact_phone}"
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
        pickup_location: @pickup_location,
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
      @pickup_location = data['pickup_location']
      @suitable_count = data['suitable_count']
    end
  
    # 模拟 AI Agent 操作：租赁深圳经济型轿车
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 获取驾驶员信息（从 demo_user 的 passengers）
      driver = user.passengers.find_by!(name: '张三', data_version: 0)
    
      # 3. 查找符合条件的车辆
      # 必须限制取车点：深圳有4个取车点（T3航站楼/GTC地面交通中心/停车场/深圳北站），
      # 每个取车点的车型和价格不同，需指定取车点以确保测试可预测性
      suitable_cars = Car.where(
        location: @location,
        category: @category,
        pickup_location: @pickup_location,
        data_version: 0
      ).where('price_per_day <= ?', @budget_per_day)
    
      # 随机选择一辆
      target_car = suitable_cars.sample
    
      # 4. 创建订单（使用 demo_user 数据）
      total_price = target_car.price_per_day * @rental_days
      pickup_datetime = @pickup_date.to_time.in_time_zone.change(hour: 9, min: 0) # 上午9点
      # 租赁天数计算：(还车日期 - 取车日期).days
      # 例如：2月26日00:00 到 3月1日00:00 = 3天（26、27、28三个日历日）
      return_datetime = (@pickup_date + @rental_days.days).to_time.in_time_zone.change(hour: 18, min: 0) # 下午6点
    
      order = CarOrder.create!(
        car_id: target_car.id,
        user_id: user.id,
        driver_name: driver.name,
        driver_id_number: driver.id_number,
        contact_phone: driver.phone,
        pickup_datetime: pickup_datetime,
        return_datetime: return_datetime,
        pickup_location: target_car.pickup_location,
        status: 'pending',
        total_price: total_price,
        data_version: @data_version
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
end
