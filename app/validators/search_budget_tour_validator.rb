# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例6: 搜索预算5000元以内的云南旅游产品
# 
# 任务描述:
#   Agent 需要搜索云南的旅游产品，
#   找出符合预算（≤5000元/人）的产品，
#   并选择其中最受欢迎的（销量最高）完成预订
# 
# 评分标准:
#   - 搜索到了符合预算的产品 (20分)
#   - 正确识别价格范围 (20分)
#   - 选择了销量最高的产品 (30分)
#   - 成功创建订单 (30分)
# 
# 难点:
#   - 需要筛选多个产品
#   - 需要理解"预算5000元以内"概念
#   - 需要对比销量找出最受欢迎的
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/search_budget_tour_yn/prepare
#   
#   # Agent 通过界面操作完成搜索和预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class SearchBudgetTourValidator < BaseValidator
  self.validator_id = 'search_budget_tour_yn'
  self.title = '搜索并预订预算5000元以内的云南旅游产品'
  self.description = '搜索云南的旅游产品，找出预算内（≤5000元/人）最受欢迎的产品并完成预订'
  self.timeout_seconds = 300
  
  # 准备阶段：插入测试数据
  def prepare
    # 数据已经通过 load_data_pack 自动加载
    @destination = '云南'
    @budget = 5000
    
    # 查找所有云南的产品（注意：查询基线数据）
    all_products = TourGroupProduct.by_destination(@destination).where(data_version: 0)
    
    # 筛选符合预算的产品
    @budget_products = all_products.select { |p| p.price <= @budget }
    
    # 找出最受欢迎的（销量最高）
    @most_popular = @budget_products.max_by { |p| p.sales_count }
    
    # 返回给 Agent 的任务信息
    {
      task: "请搜索#{@destination}的旅游产品，找出预算#{@budget}元以内最受欢迎的产品并预订（1人）",
      destination: @destination,
      budget: @budget,
      hint: "系统中有多个产品可选，需要筛选价格并对比销量",
      total_products: all_products.count,
      budget_products_count: @budget_products.count,
      price_range: {
        min: @budget_products.map(&:price).min,
        max: @budget_products.map(&:price).max
      },
      most_popular_sales: @most_popular&.sales_count
    }
  end
  
  # 验证阶段：检查是否找到并预订了正确的产品
  def verify
    # 断言1: 必须有订单创建
    add_assertion "订单已创建", weight: 30 do
      @booking = TourGroupBooking.order(created_at: :desc).first
      expect(@booking).not_to be_nil, "未找到任何跟团游订单记录"
    end
    
    return unless @booking
    
    # 断言2: 目的地正确
    add_assertion "目的地正确（云南）", weight: 10 do
      destination = @booking.tour_group_product.destination
      expect(destination).to include(@destination),
        "目的地不正确。预期包含: #{@destination}, 实际: #{destination}"
    end
    
    # 断言3: 价格符合预算
    add_assertion "价格符合预算（≤#{@budget}元/人）", weight: 20 do
      # 获取成人单价（不含保险）
      adult_unit_price = @booking.tour_package.price
      
      expect(adult_unit_price).to be <= @budget,
        "价格超出预算。预算: ≤#{@budget}元/人, 实际: #{adult_unit_price}元/人"
    end
    
    # 断言4: 选择了销量最高的产品（核心评分）
    add_assertion "选择了预算内销量最高的产品", weight: 30 do
      # 重新查找所有符合预算的云南产品
      all_products = TourGroupProduct.by_destination(@destination).where(data_version: 0)
      budget_products = all_products.select { |p| p.price <= @budget }
      
      # 找出最高销量
      max_sales = budget_products.map(&:sales_count).max
      
      # 实际预订的产品销量
      booked_sales = @booking.tour_group_product.sales_count
      
      expect(booked_sales).to eq(max_sales),
        "未选择销量最高的产品。最高销量: #{max_sales}, 实际选择: #{booked_sales} (#{@booking.tour_group_product.title})"
    end
    
    # 断言5: 正确识别价格范围
    add_assertion "正确识别了价格范围", weight: 10 do
      # 验证订单价格在合理范围内
      adult_unit_price = @booking.tour_package.price
      
      # 最低价应该 > 0
      expect(adult_unit_price).to be > 0,
        "价格异常。实际: #{adult_unit_price}元"
      
      # 最高价应该 <= 预算
      expect(adult_unit_price).to be <= @budget,
        "价格超出预算。实际: #{adult_unit_price}元"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      destination: @destination,
      budget: @budget,
      budget_products_count: @budget_products.count,
      most_popular_id: @most_popular&.id,
      most_popular_sales: @most_popular&.sales_count
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @destination = data['destination']
    @budget = data['budget']
    @most_popular = TourGroupProduct.find_by(id: data['most_popular_id']) if data['most_popular_id']
  end
  
  # 模拟 AI Agent 操作：搜索云南预算内最受欢迎产品并预订
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找符合预算的云南产品
    all_products = TourGroupProduct.by_destination(@destination).where(data_version: 0)
    budget_products = all_products.select { |p| p.price <= @budget }
    
    # 3. 找出销量最高的
    target_product = budget_products.max_by { |p| p.sales_count }
    
    # 如果产品没有套餐，先生成
    target_product.generate_packages if target_product.tour_packages.empty?
    
    # 4. 选择套餐（经济型）
    target_package = target_product.tour_packages.find_by(name: '经济型') || target_product.tour_packages.first
    
    # 5. 创建订单（固定参数）
    travel_date = Date.current + 7.days  # 7天后出发
    adult_count = 1
    total_price = target_package.price * adult_count
    
    booking = TourGroupBooking.create!(
      tour_group_product_id: target_product.id,
      tour_package_id: target_package.id,
      user_id: user.id,
      travel_date: travel_date,
      adult_count: adult_count,
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
      sales_count: target_product.sales_count,
      adult_count: adult_count,
      total_price: total_price,
      user_email: user.email
    }
  end
end
