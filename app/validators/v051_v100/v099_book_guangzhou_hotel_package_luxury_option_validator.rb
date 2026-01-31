# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例99: 囤货广州地区酒店套餐（1晚，1份，豪华套餐选项）
# 
# 任务描述:
#   Agent 需要在系统中搜索广州地区的酒店套餐，
#   囤货购买1晚套餐，购买数量为1份（先囤再约），
#   并从该套餐的多个选项中选择豪华套餐选项（包含早餐+晚餐，服务最全面）
# 
# 复杂度分析:
#   1. 需要搜索"广州"地区的酒店套餐（从多个城市中筛选）
#   2. 需要选择1晚的套餐（筛选night_count）
#   3. 需要理解套餐选项的差异和服务内容
#   4. 需要从多个套餐选项中选择豪华套餐（包含早餐+晚餐）
#   5. 需要填写购买信息（联系人、手机等）
#   ❌ 不能一次性提供：需要先搜索套餐→对比选项→识别豪华套餐→囤货购买
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（广州）(15分)
#   - 套餐晚数正确（1晚）(15分)
#   - 选择了豪华套餐选项（而非标准或含早套餐）(30分)
#   - 订单价格和数量正确 (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v099_book_guangzhou_hotel_package_luxury_option_validator/start
#   
#   # Agent 通过界面操作完成囤货购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V099BookGuangzhouHotelPackageLuxuryOptionValidator < BaseValidator
  self.validator_id = 'v099_book_guangzhou_hotel_package_luxury_option_validator'
  self.task_id = 'c7f3d8e2-4b9a-4c1f-8e5d-2a6b9f3c8d7e'
  self.title = '囤货广州地区酒店套餐（1晚，1份，豪华套餐选项）'
  self.description = '需要搜索广州地区的1晚酒店套餐，囤货购买1份（先囤再约），从套餐选项中选择豪华套餐（包含早餐+晚餐）'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @city = '广州'
    @night_count = 1
    @quantity = 1
    
    # 查找广州地区的1晚套餐（注意：查询基线数据 data_version=0）
    @available_packages = HotelPackage.where(
      city: @city,
      night_count: @night_count,
      data_version: 0
    )
    
    # 返回给 Agent 的任务信息
    {
      task: "请囤货购买#{@city}地区的酒店套餐（#{@night_count}晚，1份），先囤货后预约，请选择豪华套餐选项（包含早餐和晚餐）",
      city: @city,
      night_count: @night_count,
      quantity: @quantity,
      hint: "系统中的酒店套餐通常有多个选项：标准套餐（不含早餐）、含早套餐（含双人早餐）、豪华套餐（含双人早餐+晚餐）。请选择服务最全面的豪华套餐选项。",
      available_packages_count: @available_packages.count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（基于当前会话）
    add_assertion "订单已创建", weight: 20 do
      all_orders = HotelPackageOrder
        .where(data_version: @data_version)
        .order(created_at: :desc)
        .to_a
      
      expect(all_orders).not_to be_empty, "未找到任何酒店套餐订单记录"
      
      @package_order = all_orders.first
    end
    
    return unless @package_order # 如果没有订单，后续断言无法继续
    
    # 断言2: 城市正确
    add_assertion "城市正确（广州）", weight: 15 do
      actual_city = @package_order.hotel_package.city
      expect(actual_city).to eq(@city),
        "城市错误。期望: #{@city}, 实际: #{actual_city}"
    end
    
    # 断言3: 套餐晚数正确
    add_assertion "套餐晚数正确（1晚）", weight: 15 do
      actual_nights = @package_order.hotel_package.night_count
      expect(actual_nights).to eq(@night_count),
        "套餐晚数错误。期望: #{@night_count}晚, 实际: #{actual_nights}晚"
    end
    
    # 断言4: 选择了豪华套餐选项（核心评分项）
    add_assertion "选择了豪华套餐选项（包含早餐+晚餐）", weight: 30 do
      selected_option = @package_order.package_option
      option_name = selected_option.name
      option_description = selected_option.description
      
      # 检查是否选择了豪华套餐
      is_luxury = option_name.include?('豪华')
      
      expect(is_luxury).to be_truthy,
        "未选择豪华套餐选项。" \
        "豪华套餐包含早餐和晚餐，是服务最全面的选项，" \
        "实际选择: #{option_name}（#{option_description}）。" \
        "建议选择名称中包含'豪华'的套餐选项。"
    end
    
    # 断言5: 订单价格和数量正确
    add_assertion "订单价格和数量正确", weight: 20 do
      expected_total = @package_order.package_option.price * @package_order.quantity
      actual_total = @package_order.total_price
      
      expect(actual_total).to eq(expected_total),
        "订单总价错误。期望: #{expected_total}元（单价#{@package_order.package_option.price}元 × #{@package_order.quantity}份），实际: #{actual_total}元"
      
      expect(@package_order.quantity).to eq(@quantity),
        "订单数量错误。期望: #{@quantity}份, 实际: #{@package_order.quantity}份"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      city: @city,
      night_count: @night_count,
      quantity: @quantity
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @city = data['city']
    @night_count = data['night_count']
    @quantity = data['quantity']
    
    # 重新加载可用套餐列表
    @available_packages = HotelPackage.where(
      city: @city,
      night_count: @night_count,
      data_version: 0
    )
  end
  
  # 模拟 AI Agent 操作：囤货购买广州地区豪华套餐
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找测试乘客（数据包中已创建）
    passenger = Passenger.find_by!(phone: '13800138000', data_version: 0)
    
    # 3. 查找广州地区的1晚套餐
    available_packages = HotelPackage.where(
      city: @city,
      night_count: @night_count,
      data_version: 0
    )
    
    raise "未找到符合条件的酒店套餐" if available_packages.empty?
    
    # 4. 选择第一个套餐（简化逻辑）
    target_package = available_packages.first
    
    # 5. 从该套餐的选项中选择豪华套餐
    target_option = target_package.package_options
      .where(data_version: 0)
      .find { |opt| opt.name.include?('豪华') }
    
    # 如果没有豪华套餐，fallback到含早套餐
    target_option ||= target_package.package_options
      .where(data_version: 0)
      .find { |opt| opt.name.include?('含早') }
    
    raise "未找到可用的套餐选项" unless target_option
    
    # 6. 创建酒店套餐订单（囤货模式：不需要入住日期）
    package_order = HotelPackageOrder.create!(
      hotel_package_id: target_package.id,
      package_option_id: target_option.id,
      user_id: user.id,
      passenger_id: passenger.id,
      quantity: @quantity,
      total_price: target_option.price * @quantity,
      booking_type: 'stockup',
      status: 'pending',
      contact_name: passenger.name,
      contact_phone: passenger.phone
    )
    
    # 返回操作信息
    {
      action: 'create_hotel_package_order',
      order_id: package_order.id,
      order_number: package_order.order_number,
      package_title: target_package.title,
      package_brand: target_package.brand_name,
      option_name: target_option.name,
      option_description: target_option.description,
      price: target_option.price,
      quantity: @quantity,
      total_price: package_order.total_price,
      booking_type: 'stockup',
      user_email: user.email
    }
  end
end
