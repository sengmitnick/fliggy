# frozen_string_literal: true

require_relative 'base_validator'

# 验证用例98: 立即预约上海地区酒店套餐（2晚，含早餐，指定入住日期）
# 
# 任务描述:
#   Agent 需要在系统中搜索上海地区的酒店套餐，
#   选择立即预约模式（而非囤货），选择包含早餐的套餐选项，
#   并指定具体的入住日期（从明天开始，连住2晚）
# 
# 复杂度分析:
#   1. 需要搜索"上海"地区的酒店套餐（从多个城市中筛选）
#   2. 需要选择2晚的套餐（筛选night_count）
#   3. 需要选择立即预约模式（instant booking）而非囤货模式（stockup）
#   4. 需要从套餐选项中选择含早餐的选项（而非不含早的标准套餐）
#   5. 需要选择具体的酒店和入住日期（check_in_date, check_out_date）
#   6. 需要填写联系人信息
#   ❌ 不能一次性提供：需要先搜索套餐→选择酒店→选择日期→预约
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（上海）(10分)
#   - 套餐晚数正确（2晚）(10分)
#   - 预约模式正确（instant而非stockup）(15分)
#   - 选择了含早餐的套餐选项（含早或豪华套餐）(20分)
#   - 入住日期正确（明天开始，连住2晚）(15分)
#   - 订单价格和数量正确 (10分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v098_instant_book_hotel_package_with_dates_validator/start
#   
#   # Agent 通过界面操作完成立即预约...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
class V098InstantBookHotelPackageWithDatesValidator < BaseValidator
  self.validator_id = 'v098_instant_book_hotel_package_with_dates_validator'
  self.task_id = '89f42d1c-3e8b-4a9f-b2c1-7d5e9a6f8c3a'
  self.title = '立即预约上海地区酒店套餐（2晚，含早餐，指定入住日期）'
  self.description = '需要搜索上海地区的2晚酒店套餐，选择立即预约模式，从套餐选项中选择含早餐的选项，并指定明天开始入住2晚'
  self.timeout_seconds = 300
  
  # 准备阶段：设置任务参数
  def prepare
    # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
    @city = '上海'
    @night_count = 2
    @quantity = 1
    @check_in_date = Date.tomorrow
    @check_out_date = @check_in_date + @night_count.days
    
    # 查找上海地区的2晚套餐（注意：查询基线数据 data_version=0）
    @available_packages = HotelPackage.where(
      city: @city,
      night_count: @night_count,
      data_version: 0
    )
    
    # 返回给 Agent 的任务信息
    {
      task: "请立即预约#{@city}地区的酒店套餐（#{@night_count}晚，1份），入住日期：明天（#{@check_in_date.strftime('%Y年%m月%d日')}）开始，连住#{@night_count}晚，请选择包含早餐的套餐选项",
      city: @city,
      night_count: @night_count,
      quantity: @quantity,
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      hint: "立即预约模式需要选择具体的酒店和入住日期，与囤货模式不同。系统中的酒店套餐通常有多个选项（标准套餐、含早套餐、豪华套餐），请选择含早餐的选项以获得更好的体验。",
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
    add_assertion "城市正确（上海）", weight: 10 do
      actual_city = @package_order.hotel_package.city
      expect(actual_city).to eq(@city),
        "城市错误。期望: #{@city}, 实际: #{actual_city}"
    end
    
    # 断言3: 套餐晚数正确
    add_assertion "套餐晚数正确（2晚）", weight: 10 do
      actual_nights = @package_order.hotel_package.night_count
      expect(actual_nights).to eq(@night_count),
        "套餐晚数错误。期望: #{@night_count}晚, 实际: #{actual_nights}晚"
    end
    
    # 断言4: 预约模式正确（instant而非stockup）
    add_assertion "预约模式正确（立即预约）", weight: 15 do
      actual_booking_type = @package_order.booking_type
      expect(actual_booking_type).to eq('instant'),
        "预约模式错误。期望: instant（立即预约）, 实际: #{actual_booking_type}（#{actual_booking_type == 'stockup' ? '囤货模式' : '未知'}）。立即预约需要指定入住日期和酒店。"
    end
    
    # 断言5: 选择了含早餐的选项（核心评分项）
    add_assertion "选择了含早餐的套餐选项（含早或豪华套餐）", weight: 20 do
      selected_option = @package_order.package_option
      option_name = selected_option.name
      option_description = selected_option.description
      
      # 检查是否选择了含早餐的选项
      has_breakfast = option_name.include?('含早') || 
                     option_name.include?('豪华') || 
                     (option_description.present? && !option_description.include?('不含早餐'))
      
      expect(has_breakfast).to be_truthy,
        "未选择含早餐的选项。" \
        "建议选择含早套餐或豪华套餐，" \
        "实际选择: #{option_name}（#{option_description}）"
    end
    
    # 断言6: 入住日期正确
    add_assertion "入住日期正确（明天开始，连住#{@night_count}晚）", weight: 15 do
      actual_check_in = @package_order.check_in_date
      actual_check_out = @package_order.check_out_date
      
      expect(actual_check_in).not_to be_nil, "未设置入住日期（立即预约模式必须设置入住日期）"
      expect(actual_check_out).not_to be_nil, "未设置离店日期（立即预约模式必须设置离店日期）"
      
      # 入住日期应该是明天
      expect(actual_check_in).to eq(@check_in_date),
        "入住日期错误。期望: #{@check_in_date.strftime('%Y年%m月%d日')}（明天）, 实际: #{actual_check_in&.strftime('%Y年%m月%d日')}"
      
      # 离店日期应该是入住日期 + night_count 天
      expect(actual_check_out).to eq(@check_out_date),
        "离店日期错误。期望: #{@check_out_date.strftime('%Y年%m月%d日')}（#{@night_count}晚后）, 实际: #{actual_check_out&.strftime('%Y年%m月%d日')}"
    end
    
    # 断言7: 订单价格和数量正确
    add_assertion "订单价格和数量正确", weight: 10 do
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
  
  # 模拟 AI Agent 操作：立即预约上海地区含早餐的酒店套餐
  def simulate
    # 1. 查找测试用户（数据包中已创建）
    user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
    # 2. 查找测试乘客（数据包中已创建）
    passenger = Passenger.find_by!(phone: '13800138000', data_version: 0)
    
    # 3. 查找上海地区的2晚套餐
    available_packages = HotelPackage.where(
      city: @city,
      night_count: @night_count,
      data_version: 0
    )
    
    raise "未找到符合条件的酒店套餐" if available_packages.empty?
    
    # 4. 选择第一个套餐（简化逻辑）
    target_package = available_packages.first
    
    # 5. 从该套餐的选项中选择含早餐的选项（含早套餐 > 豪华套餐 > 标准套餐）
    target_option = target_package.package_options
      .where(data_version: 0)
      .order(Arel.sql("CASE WHEN name LIKE '%含早%' THEN 1 WHEN name LIKE '%豪华%' THEN 2 ELSE 3 END"))
      .first
    
    raise "未找到可用的套餐选项" unless target_option
    
    # 6. 查找该套餐可用的酒店（选择第一个）
    available_hotels = Hotel.where(
      city: @city,
      data_version: 0
    ).limit(1)
    
    raise "未找到符合条件的酒店" if available_hotels.empty?
    target_hotel = available_hotels.first
    
    # 7. 创建酒店套餐订单（立即预约模式：需要入住日期和酒店）
    package_order = HotelPackageOrder.create!(
      hotel_package_id: target_package.id,
      package_option_id: target_option.id,
      hotel_id: target_hotel.id,
      user_id: user.id,
      passenger_id: passenger.id,
      quantity: @quantity,
      total_price: target_option.price * @quantity,
      booking_type: 'instant',  # 立即预约模式
      check_in_date: @check_in_date,
      check_out_date: @check_out_date,
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
      hotel_name: target_hotel.name,
      hotel_city: target_hotel.city,
      option_name: target_option.name,
      option_description: target_option.description,
      price: target_option.price,
      quantity: @quantity,
      total_price: package_order.total_price,
      booking_type: 'instant',
      check_in_date: @check_in_date.to_s,
      check_out_date: @check_out_date.to_s,
      user_email: user.email
    }
  end
end
