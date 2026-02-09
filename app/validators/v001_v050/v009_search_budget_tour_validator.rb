# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 帮张三订去昆明的跟团游（预算5000元以内，选最受欢迎的）
# 
# 任务描述:
#   Agent 需要在跟团游搜索页面中选择"昆明"作为目的地，
#   筛选出符合预算（≤5000元/人）的产品（任意天数、任意旅游类型），
#   并选择其中最受欢迎的（销量最高）完成预订（1人出行，联系人张三）
# 
# 评分标准:
#   - 成功创建订单 (20分)
#   - 目的地正确（昆明） (15分)
#   - 价格符合预算 (15分)
#   - 选择了销量最高的产品 (30分)
#   - 出行人数正确 (10分)
#   - 联系人信息正确（demo_user数据） (10分)
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
module V001V050
  class V009SearchBudgetTourValidator < BaseValidator
    self.validator_id = 'v009_search_budget_tour_validator'
    self.task_id = '1d9a9d05-c081-476c-b60f-307fa723a85c'
    self.title = '帮张三订去昆明的跟团游（预算5000元以内，选最受欢迎的）'
    self.description = '在跟团游搜索页选择"昆明"目的地，筛选预算内（≤5000元/人）最受欢迎的产品并预订（1人出行，联系人张三）'
    self.timeout_seconds = 300
  
    # 准备阶段：插入测试数据
    def prepare
      # 数据已经通过 load_data_pack 自动加载
      @destination = '昆明'
      @budget = 5000
      @adult_count = 1  # 出行人数
    
      # 查找所有昆明的产品（注意：查询基线数据）
      all_products = TourGroupProduct.by_destination(@destination).where(data_version: 0)
    
      # 筛选符合预算的产品
      @budget_products = all_products.select { |p| p.price <= @budget }
    
      # 找出最受欢迎的（销量最高）
      @most_popular = @budget_products.max_by { |p| p.sales_count }
    
      # 查找联系人（demo_user 的 passengers）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @contact_passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
      # 返回给 Agent 的任务信息
      {
        task: "请访问跟团游搜索页面，选择'#{@destination}'作为目的地城市，找出预算#{@budget}元以内最受欢迎的产品并预订（#{@adult_count}人出行，联系人：#{@contact_passenger.name}）",
        destination: @destination,
        budget: @budget,
        adult_count: @adult_count,
        contact_name: @contact_passenger.name,
        contact_phone: @contact_passenger.phone,
        tour_types: "任意类型（跟团游、独立成团、自由出行均可）",
        duration: "任意天数",
        hint: "使用城市选择器选择'昆明'作为目的地，然后筛选价格≤#{@budget}元的产品，对比销量找出最受欢迎的产品",
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
      # 断言1: 创建了订单（查询时过滤核心实体：昆明）
      add_assertion "创建了跟团游订单", weight: 20 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product, :tour_package)
          .where(tour_group_products: { destination: @destination })  # ✅ 过滤核心实体
          .where(data_version: @data_version)  # ✅ 会话隔离
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何昆明跟团游订单记录"
        @booking = all_bookings.first
      end
    
      return unless @booking
    
      # 断言2: 目的地正确（昆明）
      add_assertion "目的地正确（#{@destination}）", weight: 15 do
        destination = @booking.tour_group_product.destination
        expect(destination).to include(@destination),
          "目的地不正确。期望: #{@destination}，实际: #{destination}"
      end
    
      # 断言3: 价格符合预算
      add_assertion "价格符合预算（≤#{@budget}元/人）", weight: 15 do
        # 获取成人单价（不含保险）
        adult_unit_price = @booking.tour_package.price
      
        expect(adult_unit_price).to be <= @budget,
          "价格超出预算。预算: ≤#{@budget}元/人，实际: #{adult_unit_price}元/人"
      end
    
      # 断言4: 选择了销量最高的产品（核心评分）
      add_assertion "选择了预算内销量最高的产品", weight: 30 do
        # 重新查找所有符合预算的昆明产品
        all_products = TourGroupProduct.by_destination(@destination).where(data_version: 0)
        budget_products = all_products.select { |p| p.price <= @budget }
      
        # 找出最高销量
        max_sales = budget_products.map(&:sales_count).max
      
        # 实际预订的产品销量
        booked_sales = @booking.tour_group_product.sales_count
      
        expect(booked_sales).to eq(max_sales),
          "未选择销量最高的产品。最高销量: #{max_sales}，实际选择: #{booked_sales}（产品：#{@booking.tour_group_product.title}）"
      end
    
      # 断言5: 出行人数正确（1人）
      add_assertion "出行人数正确（#{@adult_count}人）", weight: 10 do
        expect(@booking.adult_count).to eq(@adult_count),
          "出行人数不正确。期望: #{@adult_count}人，实际: #{@booking.adult_count}人"
      end
    
      # 断言6: 联系人信息正确（来自demo_user，不是硬编码）
      add_assertion "联系人信息正确（张三 13800138000）", weight: 10 do
        expect(@booking.contact_name).to eq('张三'),
          "联系人姓名错误。期望: 张三（demo_user数据），实际: #{@booking.contact_name}"
        expect(@booking.contact_phone).to eq('13800138000'),
          "联系人电话错误。期望: 13800138000（demo_user数据），实际: #{@booking.contact_phone}"
      end
    end
  
    private
  
    # 保存执行状态数据
    def execution_state_data
      {
        destination: @destination,
        budget: @budget,
        adult_count: @adult_count,
        budget_products_count: @budget_products.count,
        most_popular_id: @most_popular&.id,
        most_popular_sales: @most_popular&.sales_count,
        contact_passenger_id: @contact_passenger&.id
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @destination = data['destination']
      @budget = data['budget']
      @adult_count = data['adult_count'] || 1
      @budget_products_count = data['budget_products_count']&.to_i
      @most_popular = TourGroupProduct.find_by(id: data['most_popular_id']) if data['most_popular_id']
      @most_popular_sales = data['most_popular_sales']&.to_i
      @contact_passenger = Passenger.find_by(id: data['contact_passenger_id']) if data['contact_passenger_id']
    end
  
    # 模拟 AI Agent 操作：搜索昆明预算内最受欢迎产品并预订
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找联系人（使用 demo_user 的 passengers 数据）
      contact_passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
      # 3. 查找符合预算的昆明产品（destination = '昆明'）
      all_products = TourGroupProduct.by_destination(@destination).where(data_version: 0)
      budget_products = all_products.select { |p| p.price <= @budget }
    
      # 4. 找出销量最高的
      target_product = budget_products.max_by { |p| p.sales_count }
    
      # 如果产品没有套餐，先生成
      target_product.generate_packages if target_product.tour_packages.empty?
    
      # 5. 选择套餐（经济型）
      target_package = target_product.tour_packages.find_by(name: '经济型') || target_product.tour_packages.first
    
      # 6. 创建订单（使用 demo_user 数据）
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
        contact_name: contact_passenger.name,      # ✅ 来自 demo_user
        contact_phone: contact_passenger.phone,    # ✅ 来自 demo_user
        insurance_type: 'none',
        total_price: total_price,
        status: 'pending',
        data_version: @data_version  # ✅ 会话隔离
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
        contact_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        user_email: user.email
      }
    end
    end
end
