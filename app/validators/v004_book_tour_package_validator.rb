# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例5: 预订价格合适的三亚5天4晚跟团游（2成人0儿童，预算≤5000元/人，总价≤10000元，小团）
# 
# 任务描述:
#   Agent 需要在系统中搜索三亚的跟团游产品，
#   找到价格合适（预算5000元/人以内）的5天4晚产品并成功创建订单
#   要求：2个成人，0个儿童，总预算10000元以内，小团（<15人）
# 
# 评分标准:
#   - 订单已创建 (20分) - 系统中存在跟团游订单记录
#   - 目的地正确（三亚） (15分) - 订单的目的地必须是三亚
#   - 天数正确（5天4晚） (15分) - 订单的行程天数必须是5天
#   - 价格符合预算（≤5000元/人，总价≤10000元） (30分) - 成人单价不超过5000元
#   - 预订人数正确（2个成人，0个儿童，小团：<15人） (20分) - 成人数量为2，儿童数量为0，总人数<15人
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_tour_package_sanya/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V004BookTourPackageValidator < BaseValidator
  self.validator_id = 'v004_book_tour_package_validator'
  self.title = '预订价格合适的三亚5天4晚跟团游（2成人0儿童，预算≤5000元/人，小团）'
  self.description = '搜索三亚的跟团游产品，找到价格合适（预算≤5000元/人，总价≤10000元）的5天4晚产品并预订（2个成人，0个儿童，小团：<15人）'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @destination = '三亚'
    @duration = 5
    @budget_per_person = 5000  # 每人预算
    @adult_count = 2
    
    # 查找符合条件的产品（用于后续验证）
    # 注意：查询基线数据 (data_version=0)
    suitable_products = TourGroupProduct.where(
      destination: @destination,
      duration: @duration,
      data_version: 0
    ).where('price <= ?', @budget_per_person)
    
    @suitable_count = suitable_products.count
    @price_range = {
      min: suitable_products.minimum(:price),
      max: suitable_products.maximum(:price)
    }
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订一个价格合适的#{@destination}#{@duration}天#{@duration - 1}晚跟团游产品，要求：#{@adult_count}个成人、0个儿童，每人预算不超过#{@budget_per_person}元（总预算≤#{@budget_per_person * @adult_count}元）",
      destination: @destination,
      duration: @duration,
      budget_per_person: @budget_per_person,
      total_budget: @budget_per_person * @adult_count,
      adult_count: @adult_count,
      child_count: 0,
      hint: "系统中有多个符合条件的产品可选，请选择价格在预算内的",
      suitable_products_count: @suitable_count,
      price_range: @price_range
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @booking = TourGroupBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何跟团游订单记录"
    end
    
    return unless @booking # 如果没有订单，后续断言无法继续
    
    # 断言2: 目的地正确
    add_assertion "目的地正确（三亚）", weight: 15 do
      expect(@booking.tour_group_product.destination).to eq(@destination),
        "目的地不正确。预期: #{@destination}, 实际: #{@booking.tour_group_product.destination}"
    end
    
    # 断言3: 天数正确
    add_assertion "天数正确（5天）", weight: 15 do
      expect(@booking.tour_group_product.duration).to eq(@duration),
        "天数不正确。预期: #{@duration}天, 实际: #{@booking.tour_group_product.duration}天"
    end
    
    # 断言4: 价格符合预算（核心评分项）
    add_assertion "价格符合预算（≤#{@budget_per_person}元/人）", weight: 30 do
      # 获取成人单价（不含保险）
      expect(@booking.tour_package).not_to be_nil, "未找到套餐信息"
      adult_unit_price = @booking.tour_package.price
      
      expect(adult_unit_price).to be <= @budget_per_person,
        "价格超出预算。预算: ≤#{@budget_per_person}元/人, 实际: #{adult_unit_price}元/人"
    end
    
    # 断言5: 预订人数正确
    add_assertion "预订人数正确（2个成人，0个儿童）", weight: 20 do
      expect(@booking.adult_count).to eq(@adult_count),
        "成人数量不正确。预期: #{@adult_count}个成人, 实际: #{@booking.adult_count}个成人"
      
      # 儿童数应该是0
      expect(@booking.child_count).to eq(0),
        "儿童数量不正确。预期: 0个儿童, 实际: #{@booking.child_count}个儿童"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      destination: @destination,
      duration: @duration,
      budget_per_person: @budget_per_person,
      adult_count: @adult_count,
      suitable_count: @suitable_count,
      price_range: @price_range
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @destination = data['destination']
    @duration = data['duration']
    @budget_per_person = data['budget_per_person']
    @adult_count = data['adult_count']
    @suitable_count = data['suitable_count']
    @price_range = data['price_range']
  end
  
  # 模拟 AI Agent 操作：预订三亚跟团游
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合条件的产品（预算内）
    suitable_products = TourGroupProduct.where(
      destination: @destination,
      duration: @duration,
      data_version: 0
    ).where('price <= ?', @budget_per_person)
    
    # 随机选择一个
    target_product = suitable_products.sample
    
    # 3. 选择套餐（价格最低的）
    target_package = target_product.tour_packages.order(:price).first
    
    # 如果没有套餐，抛出错误
    raise "产品 #{target_product.title} 没有可用套餐" if target_package.nil?
    
    # 4. 创建订单（固定参数）
    travel_date = Date.current + 7.days  # 7天后出发
    total_price = target_package.price * @adult_count
    
    booking = TourGroupBooking.create!(
      tour_group_product_id: target_product.id,
      tour_package_id: target_package.id,
      user_id: user.id,
      travel_date: travel_date,
      adult_count: @adult_count,
      child_count: 0,
      contact_name: '张三',
      contact_phone: '13800138000',
      insurance_type: 'none',
      total_price: total_price,
      status: 'pending'
    )
    
    # 返回操作信息
    {
      action: 'create_tour_booking',
      booking_id: booking.id,
      product_title: target_product.title,
      package_name: target_package.name,
      unit_price: target_package.price,
      adult_count: @adult_count,
      total_price: total_price,
      user_email: user.email
    }
  end
end
