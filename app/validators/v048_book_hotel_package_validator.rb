# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例48: 预订武汉地区酒店套餐（2晚，5天后入住，最佳性价比套餐选项）
# 
# 任务描述:
#   Agent 需要在系统中搜索武汉地区的酒店套餐，
#   预订5天后入住的2晚套餐，并从该套餐的多个选项中选择性价比最佳的选项
# 
# 复杂度分析:
#   1. 需要搜索"武汉"地区的酒店套餐（从多个城市中筛选）
#   2. 需要选择2晚的套餐（筛选night_count）
#   3. 需要指定入住日期为5天后
#   4. 需要理解套餐选项的差异（标准套餐、含早套餐、豪华套餐）
#   5. 需要从多个套餐选项中选择性价比最佳的（价格合理+包含服务多）
#   6. 需要填写入住信息（联系人、手机等）
#   ❌ 不能一次性提供：需要先搜索套餐→对比选项→评估性价比→预订
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（武汉）(15分)
#   - 套餐晚数正确（2晚）(15分)
#   - 选择了含早或豪华套餐（而非不含早的标准套餐）(30分)
#   - 订单价格和数量正确 (20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v048_book_hotel_package_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V048BookHotelPackageValidator < BaseValidator
  self.validator_id = 'v048_book_hotel_package_validator'
  self.title = '预订武汉地区酒店套餐（2晚，5天后入住，最佳性价比选项）'
  self.description = '需要搜索武汉地区的2晚酒店套餐，预订5天后入住，从套餐选项中选择性价比最佳的（含早或豪华套餐）'
  self.timeout_seconds = 240
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @city = '武汉'
    @night_count = 2
    @quantity = 1
    @check_in_date = Date.current + 5.days  # 5天后入住
    @check_out_date = @check_in_date + @night_count.days  # 退房日期
    
    # 查找武汉地区的2晚套餐（注意：查询基线数据 data_version=0）
    @available_packages = HotelPackage.where(
      city: @city,
      night_count: @night_count,
      data_version: 0
    )
    
    # 返回给 Agent 的任务信息
    {
      task: "请预订#{@city}地区的酒店套餐（#{@night_count}晚，1份），入住日期为#{@check_in_date.strftime('%Y年%m月%d日')}，请选择性价比最好的套餐选项",
      city: @city,
      night_count: @night_count,
      quantity: @quantity,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      hint: "系统中的酒店套餐通常有多个选项（标准套餐、含早套餐、豪华套餐），请根据价格和包含的服务选择最佳选项。含早或豪华套餐性价比更高。",
      available_packages_count: @available_packages.count
    }
  end
  
  # 验证阶段：检查订单是否符合要求
  def verify
    # 断言1: 必须有订单创建（最近创建的一条）
    add_assertion "订单已创建", weight: 20 do
      @package_order = HotelPackageOrder.order(created_at: :desc).first
      expect(@package_order).not_to be_nil, "未找到任何酒店套餐订单记录"
    end
    
    return unless @package_order # 如果没有订单，后续断言无法继续
    
    # 断言2: 城市正确
    add_assertion "城市正确（武汉）", weight: 15 do
      actual_city = @package_order.hotel_package.city
      expect(actual_city).to eq(@city),
        "城市错误。期望: #{@city}, 实际: #{actual_city}"
    end
    
    # 断言3: 套餐晚数正确
    add_assertion "套餐晚数正确（2晚）", weight: 15 do
      actual_nights = @package_order.hotel_package.night_count
      expect(actual_nights).to eq(@night_count),
        "套餐晚数错误。期望: #{@night_count}晚, 实际: #{actual_nights}晚"
    end
    
    # 断言4: 选择了性价比更高的选项（核心评分项）
    # 性价比判断：含早套餐 > 豪华套餐 > 标准套餐
    add_assertion "选择了性价比更高的选项（含早或豪华套餐）", weight: 30 do
      selected_option = @package_order.package_option
      option_name = selected_option.name
      
      # 检查是否选择了含早或豪华套餐（而非不含早的标准套餐）
      is_good_choice = option_name.include?('含早') || option_name.include?('豪华')
      
      expect(is_good_choice).to be_truthy,
        "未选择性价比最佳的选项。" \
        "建议选择含早套餐或豪华套餐以获得更多服务，" \
        "实际选择: #{option_name}（#{selected_option.description}）"
    end
    
    # 断言5: 订单价格和数量正确
    add_assertion "订单价格和数量正确", weight: 20 do
      expected_total = @package_order.package_option.price * @package_order.quantity
      actual_total = @package_order.total_price
      
      expect(actual_total).to eq(expected_total),
        "订单总价错误。期望: #{expected_total}元（单价#{@package_order.package_option.price}元 × #{@package_order.quantity}份），实际: #{actual_total}元"
    end
  end
  
  private
  
  # 保存执行状态数据
  def execution_state_data
    {
      city: @city,
      night_count: @night_count,
      quantity: @quantity,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s
    }
  end
  
  # 从状态恢复实例变量
  def restore_from_state(data)
    @city = data['city']
    @night_count = data['night_count']
    @quantity = data['quantity']
    @check_in_date = Date.parse(data['check_in_date'])
    @check_out_date = Date.parse(data['check_out_date'])
    
    # 重新加载可用套餐列表
    @available_packages = HotelPackage.where(
      city: @city,
      night_count: @night_count,
      data_version: 0
    )
  end
  
  # 模拟 AI Agent 操作：预订武汉地区性价比最佳的酒店套餐
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找测试乘客（数据包中已创建）
    passenger = Passenger.find_by!(phone: '13800138000', data_version: 0)
    
    # 3. 查找武汉地区的2晚套餐
    available_packages = HotelPackage.where(
      city: @city,
      night_count: @night_count,
      data_version: 0
    )
    
    raise "未找到符合条件的酒店套餐" if available_packages.empty?
    
    # 4. 选择第一个套餐（简化逻辑）
    target_package = available_packages.first
    
    # 5. 从该套餐的选项中选择性价比最好的（含早套餐 > 豪华套餐 > 标准套餐）
    # 优先选择含早套餐
    target_option = target_package.package_options
      .where(data_version: 0)
      .order(Arel.sql("CASE WHEN name LIKE '%含早%' THEN 1 WHEN name LIKE '%豪华%' THEN 2 ELSE 3 END"))
      .first
    
    raise "未找到可用的套餐选项" unless target_option
    
    # 6. 创建酒店套餐订单
    package_order = HotelPackageOrder.create!(
      hotel_package_id: target_package.id,
      package_option_id: target_option.id,
      user_id: user.id,
      passenger_id: passenger.id,
      quantity: @quantity,
      total_price: target_option.price * @quantity,
      booking_type: 'instant',  # 立即预订
      status: 'pending',
      contact_name: passenger.name,
      contact_phone: passenger.phone,
      check_in_date: @check_in_date,
      check_out_date: @check_out_date
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
      user_email: user.email
    }
  end
end
