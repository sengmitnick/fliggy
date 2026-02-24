# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 给张三在成都租一辆7座SUV适合家庭出行（后天上午9:00取车，租3天）
# 
# 任务描述:
#   Agent 需要搜索成都的租车服务，
#   找到适合家庭的7座SUV并创建订单（后天上午9:00取车，租3天）
# 
# 评分标准:
#   - 搜索到了符合条件的车辆 (15分)
#   - 城市正确（成都） (15分)
#   - 车辆类型正确（SUV） (20分)
#   - 座位数正确（7座） (20分)
#   - 取车时间正确（后天上午9:00） (15分)
#   - 租期天数正确（3天） (15分)
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
module V001V050
  class V013SearchFamilyCarValidator < BaseValidator
    self.validator_id = 'v013_search_family_car_validator'
    self.task_id = '6c21ca8e-7ad4-4e17-88b0-856d95b31498'
    self.title = '给张三租一辆适合家庭的SUV（后天上午9:00取车，租3天）'
    self.description = '给张三在成都租一辆7座SUV适合家庭出行（后天上午9:00取车，租3天）'
    self.timeout_seconds = 300
  
    # 准备阶段：插入测试数据
    def prepare
      # 数据已经通过 load_data_pack 自动加载
      @location = '成都'
      @category = 'SUV'
      @required_seats = 7
      @pickup_date = Date.current + 2.days  # 后天
      @pickup_time = '09:00'  # 上午9:00
      @rental_days = 3  # 租3天
    
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
        task: "给张三租一辆适合家庭的SUV（后天上午9:00取车，租3天）",
        task_detail: "请搜索#{@location}适合家庭的#{@required_seats}座#{@category}并租赁（后天上午#{@pickup_time}取车，租#{@rental_days}天）",
        location: @location,
        category: @category,
        seats: @required_seats,
        pickup_date: @pickup_date.to_s,
        pickup_date_description: "后天（#{@pickup_date.strftime('%Y年%m月%d日')}）",
        pickup_time: @pickup_time,
        rental_days: @rental_days,
        hint: "适合家庭的车辆通常是7座SUV，空间大、舒适度高",
        suitable_cars_count: @suitable_count
      }
    end
  
    # 验证阶段：检查是否找到并预订了正确的车辆
    def verify
      # 断言1: 必须有订单创建（查询过滤核心实体：城市+车型）
      add_assertion "创建了租车订单", weight: 20 do
        all_orders = CarOrder
          .joins(:car)
          .where(
            cars: {
              location: @location,
              category: @category,
              data_version: 0
            },
            data_version: @data_version
          )
          .order(created_at: :desc)
          .to_a
        
        expect(all_orders).not_to be_empty, "未找到任何#{@location}#{@category}的租车订单记录"
        @order = all_orders.first
      end
    
      return if @order.nil?
    
      # 断言2: 城市正确
      add_assertion "城市正确（成都）", weight: 5 do
        expect(@order.car.location).to eq(@location),
          "城市不正确。期望: #{@location}, 实际: #{@order.car.location}"
      end
    
      # 断言3: 驾驶员信息正确（验证来自 demo_user，不是硬编码）
      add_assertion "驾驶员信息正确（张三 13800138000）", weight: 5 do
        expect(@order.driver_name).to eq('张三'),
          "驾驶员姓名错误。期望: 张三（demo_user数据）, 实际: #{@order.driver_name}"
        expect(@order.contact_phone).to eq('13800138000'),
          "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@order.contact_phone}"
      end
    
      # 断言4: 车辆类型正确（核心评分）
      add_assertion "车辆类型正确（SUV）", weight: 20 do
        expect(@order.car.category).to eq(@category),
          "车辆类型不正确。预期: #{@category}, 实际: #{@order.car.category}"
      end
    
      # 断言5: 座位数正确（核心评分）
      add_assertion "座位数正确（7座）", weight: 20 do
        expect(@order.car.seats).to eq(@required_seats),
          "座位数不正确。预期: #{@required_seats}座, 实际: #{@order.car.seats}座"
      end
    
      # 断言6: 取车时间正确（后天上午9:00）
      add_assertion "取车时间正确（后天上午#{@pickup_time}）", weight: 15 do
        expected_pickup_datetime = @pickup_date.to_time.in_time_zone.change(hour: 9, min: 0)
        actual_pickup_date = @order.pickup_datetime.to_date
        actual_pickup_hour = @order.pickup_datetime.hour
      
        expect(actual_pickup_date).to eq(@pickup_date),
          "取车日期不正确。预期: #{@pickup_date.strftime('%Y年%m月%d日')}, 实际: #{actual_pickup_date.strftime('%Y年%m月%d日')}"
      
        expect(actual_pickup_hour).to eq(9),
          "取车时间不正确。预期: 上午9:00, 实际: #{@order.pickup_datetime.strftime('%H:%M')}"
      end
    
      # 断言7: 租期天数正确（3天）
      add_assertion "租期天数正确（#{@rental_days}天）", weight: 15 do
        # 计算租期天数：从取车日期到还车日期的天数差+1
        actual_rental_days = (@order.return_datetime.to_date - @order.pickup_datetime.to_date).to_i + 1
      
        expect(actual_rental_days).to eq(@rental_days),
          "租期天数不正确。预期: #{@rental_days}天, 实际: #{actual_rental_days}天"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        location: @location,
        category: @category,
        required_seats: @required_seats,
        pickup_date: @pickup_date.to_s,
        pickup_time: @pickup_time,
        rental_days: @rental_days,
        suitable_count: @suitable_count
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @location = data['location']
      @category = data['category']
      @required_seats = data['required_seats']
      @pickup_date = Date.parse(data['pickup_date']) if data['pickup_date']
      @pickup_time = data['pickup_time'] || '09:00'
      @rental_days = data['rental_days'] || 3
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
    
      # 3. 创建订单
      pickup_date = Date.current + 2.days
      rental_days = 3
      total_price = target_car.price_per_day * rental_days
      pickup_datetime = pickup_date.to_time.in_time_zone.change(hour: 9, min: 0)
      # 3天租期：第1天上午9点 -> 第3天下午6点（正好3天）
      return_datetime = (pickup_date + (rental_days - 1).days).to_time.in_time_zone.change(hour: 18, min: 0)
    
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
        total_price: total_price,
        data_version: @data_version
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
end
