# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 给张三和李四预订三亚5天4晚跟团游（预算≤5000元/人，小团）
# 
# 任务描述:
#   Agent 需要在系统中搜索三亚的跟团游产品，
#   找到价格合适（预算5000元/人以内）的5天4晚产品并为张三和李四成功创建订单
#   要求：2个成人（张三、李四），0个儿童，总预算10000元以内，小团（<15人）
# 
# 评分标准:
#   - 订单已创建 (20分) - 系统中存在跟团游订单记录
#   - 目的地正确（三亚） (10分) - 订单的目的地必须是三亚
#   - 天数正确（5天4晚） (10分) - 订单的行程天数必须是5天
#   - 价格符合预算（≤5000元/人，总价≤10000元） (20分) - 成人单价不超过5000元
#   - 预订人数正确（2个成人，0个儿童） (10分) - 成人数量为2，儿童数量为0
#   - 联系人信息正确 (10分) - 联系人姓名和电话来自 demo_user 的 passengers（张三）
#   - 小团要求（<15人） (5分) - 所选套餐的总人数少于15人
#   - 旅客列表正确（张三、李四） (15分) - 必须选择张三和李四作为出行人
# 
# 使用方法:
#   # 准备阶段
#   POST /api/verify/book_tour_package_sanya/prepare
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V004BookTourPackageValidator < BaseValidator
    self.validator_id = 'v004_book_tour_package_validator'
    self.task_id = '7112f563-8766-4240-b041-1a25d72df7a5'
    self.title = '给张三和李四预订三亚5天4晚跟团游（预算≤5000元/人，小团）'
    self.description = '搜索三亚的跟团游产品，找到价格合适（预算≤5000元/人）的5天4晚产品并为张三和李四预订（小团：<15人）'
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
        task: "请给张三和李四预订一个#{@destination}#{@duration}天#{@duration - 1}晚跟团游产品（预算≤#{@budget_per_person}元/人，小团）",
        destination: @destination,
        duration: @duration,
        budget_per_person: @budget_per_person,
        total_budget: @budget_per_person * @adult_count,
        adult_count: @adult_count,
        child_count: 0,
        passengers: "张三、李四",
        requirement: "必须选择小团（<15人）的产品，价格在预算内，联系人使用张三（demo_user 的出行人）",
        hint: "系统中有多个符合条件的产品可选，请选择价格在预算内且为小团的产品",
        suitable_products_count: @suitable_count,
        price_range: @price_range,
        scoring_note: "价格符合预算占25%，小团要求占10%，联系人信息正确占10%，旅客列表正确占15%，请务必使用 demo_user 的出行人数据（张三和李四）"
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（最近创建的一条）
      add_assertion "订单已创建", weight: 20 do
        all_tour_group_bookings = TourGroupBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        expect(all_tour_group_bookings).not_to be_empty, "未找到任何跟团游订单记录"
        @booking = all_tour_group_bookings.first
      end
    
      return unless @booking # 如果没有订单，后续断言无法继续
    
      # 断言2: 目的地正确
      add_assertion "目的地正确（三亚）", weight: 10 do
        expect(@booking.tour_group_product.destination).to eq(@destination),
          "目的地不正确。期望: #{@destination}, 实际: #{@booking.tour_group_product.destination}"
      end
    
      # 断言3: 天数正确
      add_assertion "天数正确（5天）", weight: 10 do
        expect(@booking.tour_group_product.duration).to eq(@duration),
          "天数不正确。期望: #{@duration}天, 实际: #{@booking.tour_group_product.duration}天"
      end
    
      # 断言4: 价格符合预算（核心评分项）
      add_assertion "价格符合预算（≤#{@budget_per_person}元/人）", weight: 20 do
        # 获取成人单价（不含保险）
        expect(@booking.tour_package).not_to be_nil, "未找到套餐信息"
        adult_unit_price = @booking.tour_package.price
      
        expect(adult_unit_price).to be <= @budget_per_person,
          "价格超出预算。期望: ≤#{@budget_per_person}元/人, 实际: #{adult_unit_price}元/人"
      end
    
      # 断言5: 预订人数正确
      add_assertion "预订人数正确（2个成人，0个儿童）", weight: 10 do
        expect(@booking.adult_count).to eq(@adult_count),
          "成人数量不正确。期望: #{@adult_count}个成人, 实际: #{@booking.adult_count}个成人"
      
        # 儿童数应该是0
        expect(@booking.child_count).to eq(0),
          "儿童数量不正确。期望: 0个儿童, 实际: #{@booking.child_count}个儿童"
      end
    
      # 断言6: 联系人信息正确（来自 demo_user 数据）
      add_assertion "联系人信息正确（张三 13800138000）", weight: 10 do
        expect(@booking.contact_name).to eq('张三'),
          "联系人姓名错误。期望: 张三（demo_user 出行人）, 实际: #{@booking.contact_name}"
        expect(@booking.contact_phone).to eq('13800138000'),
          "联系人电话错误。期望: 13800138000（张三的电话）, 实际: #{@booking.contact_phone}"
      end
    
      # 断言7: 小团要求
      add_assertion "小团要求", weight: 5 do
        product = @booking.tour_group_product
        
        # 检查标题或 tags 中是否包含"小团"相关关键词
        is_small_group = product.title.include?('小团') || 
                         product.title.include?('精品小团') ||
                         (product.tags.is_a?(Array) && (product.tags.include?('小团出行') || product.tags.include?('小团')))
        
        expect(is_small_group).to eq(true),
          "不符合小团要求。期望: 产品标题或标签包含'小团', 实际产品: #{product.title}"
      end
    
      # 断言8: 旅客列表正确（张三和李四）
      add_assertion "旅客列表正确（张三、李四）", weight: 15 do
        travelers = @booking.booking_travelers.where(data_version: @data_version).to_a
        
        expect(travelers.size).to eq(2),
          "旅客数量不正确。期望: 2个旅客, 实际: #{travelers.size}个旅客"
        
        traveler_names = travelers.map(&:traveler_name).sort
        expected_names = ['张三', '李四'].sort
        
        expect(traveler_names).to eq(expected_names),
          "旅客名单不正确。期望: #{expected_names.join('、')}, 实际: #{traveler_names.join('、')}"
        
        # 验证张三的身份证号
        zhangsan = travelers.find { |t| t.traveler_name == '张三' }
        expect(zhangsan).not_to be_nil, "未找到旅客张三"
        expect(zhangsan.id_number).to eq('110101199001011234'),
          "张三身份证号错误。期望: 110101199001011234, 实际: #{zhangsan.id_number}"
        
        # 验证李四的身份证号
        lisi = travelers.find { |t| t.traveler_name == '李四' }
        expect(lisi).not_to be_nil, "未找到旅客李四"
        expect(lisi.id_number).to eq('110101199002022345'),
          "李四身份证号错误。期望: 110101199002022345, 实际: #{lisi.id_number}"
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
    
      # 2. 查找出行人（数据包中已创建）
      passenger_zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      passenger_lisi = user.passengers.find_by!(name: '李四', data_version: 0)
    
      # 3. 查找符合条件的产品（预算内）
      suitable_products = TourGroupProduct.where(
        destination: @destination,
        duration: @duration,
        data_version: 0
      ).where('price <= ?', @budget_per_person)
    
      # 随机选择一个
      target_product = suitable_products.sample
    
      # 4. 选择套餐（价格最低的）
      # 优先选择小团产品（标题包含"小团"）
      if target_product.title.include?('小团')
        target_package = target_product.tour_packages.order(:price).first
      else
        # 如果不是小团产品，尝试查找其他小团产品
        small_group_products = suitable_products.where("title LIKE ?", "%小团%")
        if small_group_products.exists?
          target_product = small_group_products.sample
          target_package = target_product.tour_packages.order(:price).first
        else
          target_package = target_product.tour_packages.order(:price).first
        end
      end
    
      # 如果没有套餐，抛出错误
      raise "产品 #{target_product.title} 没有可用套餐" if target_package.nil?
    
      # 5. 创建订单（使用 demo_user 数据）
      travel_date = Date.current + 7.days  # 7天后出发
      total_price = target_package.price * @adult_count
    
      booking = TourGroupBooking.create!(
        tour_group_product_id: target_product.id,
        tour_package_id: target_package.id,
        user_id: user.id,
        travel_date: travel_date,
        adult_count: @adult_count,
        child_count: 0,
        contact_name: passenger_zhangsan.name,
        contact_phone: passenger_zhangsan.phone,
        insurance_type: 'none',
        total_price: total_price,
        status: 'pending',
        data_version: @data_version
      )
    
      # 6. 创建出行人记录（张三和李四）
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: passenger_zhangsan.name,
        id_number: passenger_zhangsan.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
    
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: passenger_lisi.name,
        id_number: passenger_lisi.id_number,
        traveler_type: 'adult',
        data_version: @data_version
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
        contact_name: passenger_zhangsan.name,
        contact_phone: passenger_zhangsan.phone,
        travelers: [passenger_zhangsan.name, passenger_lisi.name],
        user_email: user.email
      }
    end
    end
end
