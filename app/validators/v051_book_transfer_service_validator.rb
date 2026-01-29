# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例51: 预订上海虹桥机场接机服务（北京→上海航班，选择最便宜套餐）
# 
# 任务描述:
#   用户后天从北京飞往上海，需要在上海虹桥T2机场接机送到市区。
#   Agent 需要找到对应航班，预订接机服务，选择价格最低的套餐并成功创建订单
# 
# 业务流程:
#   1. 用户选择"接我"服务（from_airport = 从机场接到市区）
#   2. 根据航班的起降城市，确定降落机场（如：北京→上海，降落在上海虹桥T2）
#   3. 上车点：降落机场（location_from = 虹桥T2，自动确定）
#   4. 下车点：上海火车站（location_to = 上海火车站，距离虹桥约20公里）
#   5. 浏览可用车型套餐，选择最便宜的
# 
# 复杂度分析:
#   1. 需要理解"接机"含义：from_airport = 从机场出发，送到市区
#   2. 需要根据航班降落城市确定机场（location_from = 虹桥T2）
#   3. 需要选择下车地点为上海火车站
#   4. 需要对比不同供应商的价格（阳光出行、伙力专车等）
#   5. 需要对比不同车型的价格（经济5座、舒适5座、经济7座）
#   6. 需要选择最低价格的套餐
#   7. 需要填写乘车信息（联系人、手机号）
#   ❌ 不能一次性提供：需要先理解航班→确定机场→选地址→对比价格→预订
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 服务类型正确（airport_pickup）(15分)
#   - 选择了车辆类型 (15分)
#   - 选择了最便宜的套餐 (30分)
#   - 订单价格正确 (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v051_book_transfer_service_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V051BookTransferServiceValidator < BaseValidator
  self.validator_id = 'v051_book_transfer_service_validator'
  self.task_id = 'fa751c19-28f4-4c7e-abdc-76fbef90ca1f'
  self.title = '预订虹桥机场接机送到上海火车站（北京→上海）'
  self.description = '后天北京飞上海，虹桥T2机场接机送到上海火车站，选择最便宜的套餐'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @service_type = 'from_airport' # 接机服务：从机场接到市区
    @transfer_type = 'airport_pickup' # 服务类型：机场接送
    
    # 模拟场景：用户乘坐航班从北京飞往上海，抵达上海后需要从虹桥T2机场接到上海火车站
    @departure_city = '北京' # 航班出发城市
    @arrival_city = '上海' # 航班降落城市
    @arrival_airport = '虹桥T2' # 降落机场（上车点）
    @destination_address = '上海站' # 下车点（上海火车站，明确要求）
    @flight_date = (Date.current + 2.days).strftime('%Y-%m-%d') # 后天
    
    @location_from = @arrival_airport # 上车点 = 虹桥T2
    @location_to = @destination_address # 下车点 = 上海站
    @pickup_datetime = Date.current + 2.days + 10.hours # 后天上午10点（预计落地时间）
    
    # 查找所有可用的接送机套餐（注意：查询基线数据 data_version=0）
    @available_packages = TransferPackage.where(
      is_active: true,
      data_version: 0
    )
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订机场接机服务，选择价格最便宜的服务商",
      scenario: "后天从北京飞往上海，在虹桥T2机场接机，送到上海火车站",
      flight_info: {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date
      },
      service_type: "接机（from_airport）",
      pickup_location: "#{@arrival_airport}（上车点，自动确定）",
      dropoff_location: @destination_address,
      pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
      flow_hint: "1. 找到北京→上海的航班 → 2. 确认降落机场为虹桥T2 → 3. 选择接机服务 → 4. 上车点自动=虹桥T2 → 5. 下车点选择'上海站'（上海火车站） → 6. 对比车型价格 → 7. 选择最便宜的套餐",
      available_packages_count: @available_packages.count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @transfer = Transfer.order(created_at: :desc).first
      expect(@transfer).not_to be_nil, "未找到任何接送机订单记录"
    end
    
    return unless @transfer # 如果没有订单，后续断言无法继续
    
    # 断言2: 服务类型正确
    add_assertion "服务类型正确（airport_pickup）", weight: 15 do
      actual_type = @transfer.transfer_type
      expect(actual_type).to eq(@transfer_type),
        "服务类型错误。期望: #{@transfer_type}, 实际: #{actual_type}"
    end
    
    # 断言3: 选择了车辆类型
    add_assertion "选择了车辆类型", weight: 15 do
      expect(@transfer.transfer_package_id).not_to be_nil, "未选择车辆套餐"
      expect(@transfer.transfer_package).not_to be_nil, "车辆套餐记录不存在"
    end
    
    # 断言4: 选择了最便宜的套餐（核心评分项）
    add_assertion "选择了最便宜的套餐", weight: 30 do
      # 获取所有可用套餐
      all_packages = TransferPackage.where(
        is_active: true,
        data_version: 0
      )
      
      # 找到价格最低的
      cheapest_package = all_packages.min_by(&:price)
      actual_price = @transfer.transfer_package.price
      cheapest_price = cheapest_package.price
      
      expect(@transfer.transfer_package_id).to eq(cheapest_package.id),
        "未选择最便宜的套餐。" \
        "应选: #{cheapest_package.name} #{cheapest_package.category_name}（#{cheapest_price}元），" \
        "实际选择: #{@transfer.transfer_package.name} #{@transfer.transfer_package.category_name}（#{actual_price}元）"
    end
    
    # 断言5: 订单价格正确
    add_assertion "订单价格正确", weight: 20 do
      expected_price = @transfer.transfer_package.price
      actual_price = @transfer.total_price
      
      expect(actual_price).to eq(expected_price),
        "订单价格错误。期望: #{expected_price}元，实际: #{actual_price}元"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      service_type: @service_type,
      transfer_type: @transfer_type,
      departure_city: @departure_city,
      arrival_city: @arrival_city,
      arrival_airport: @arrival_airport,
      destination_address: @destination_address,
      flight_date: @flight_date,
      location_from: @location_from,
      location_to: @location_to,
      pickup_datetime: @pickup_datetime.to_s
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @service_type = data['service_type']
    @transfer_type = data['transfer_type']
    @departure_city = data['departure_city']
    @arrival_city = data['arrival_city']
    @arrival_airport = data['arrival_airport']
    @destination_address = data['destination_address']
    @flight_date = data['flight_date']
    @location_from = data['location_from']
    @location_to = data['location_to']
    @pickup_datetime = DateTime.parse(data['pickup_datetime']) if data['pickup_datetime']
    
    # 重新加载可用套餐列表
    @available_packages = TransferPackage.where(
      is_active: true,
      data_version: 0
    )
  end
  
  # 模拟 AI Agent 操作：预订接送机服务，选择最便宜的套餐
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找所有可用的接送机套餐
    available_packages = TransferPackage.where(
      is_active: true,
      data_version: 0
    )
    
    raise "未找到任何可用的接送机套餐" if available_packages.empty?
    
    # 3. 选择价格最低的套餐
    cheapest_package = available_packages.min_by(&:price)
    
    raise "未找到可用的接送机套餐" unless cheapest_package
    
    # 4. 创建接送机订单
    transfer = Transfer.create!(
      user_id: user.id,
      transfer_package_id: cheapest_package.id,
      transfer_type: @transfer_type,
      service_type: @service_type,
      location_from: @location_from,
      location_to: @location_to,
      pickup_datetime: @pickup_datetime,
      passenger_name: '张三',
      passenger_phone: '13800138000',
      total_price: cheapest_package.price,
      discount_amount: 0,
      status: 'pending',
      driver_status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_transfer',
      order_id: transfer.id,
      package_name: cheapest_package.name,
      vehicle_category: cheapest_package.category_name,
      price: cheapest_package.price,
      location_from: @location_from,
      location_to: @location_to,
      pickup_datetime: @pickup_datetime.strftime('%Y-%m-%d %H:%M'),
      user_email: user.email
    }
  end
end