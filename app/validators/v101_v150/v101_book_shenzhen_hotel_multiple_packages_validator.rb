# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例101: 囤货深圳地区酒店套餐（2晚，2份，含早餐）
# 
# 任务描述:
#   Agent 需要在系统中搜索深圳地区的酒店套餐，
#   囤货购买2晚套餐，购买数量为2份（先囤再约），
#   并从该套餐的多个选项中选择含早餐的选项
# 
# 复杂度分析:
#   1. 需要搜索"深圳"地区的酒店套餐（从多个城市中筛选）
#   2. 需要选择2晚的套餐（筛选night_count）
#   3. 需要理解套餐选项的差异
#   4. 需要从多个套餐选项中选择含早餐的选项（含早或豪华套餐）
#   5. 需要修改购买数量为2份（而非默认的1份）
#   6. 需要正确计算订单总价（单价 × 2份）
#   ❌ 不能一次性提供：需要先搜索套餐→选择含早选项→修改数量为2份→计算总价→囤货购买
# 
# 评分标准:
#   - 订单已创建 (20分)
#   - 城市正确（深圳）(10分)
#   - 套餐晚数正确（2晚）(10分)
#   - 选择了含早餐的套餐选项（含早或豪华套餐）(25分)
#   - 购买数量正确（2份）(15分)
#   - 联系人信息正确（张三 13800138000）(10分)
#   - 订单总价正确（单价 × 2）(10分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v101_book_shenzhen_hotel_multiple_packages_validator/start
#   
#   # Agent 通过界面操作完成囤货购买...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V101V150
  class V101BookShenzhenHotelMultiplePackagesValidator < BaseValidator
    self.validator_id = 'v101_book_shenzhen_hotel_multiple_packages_validator'
    self.task_id = 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e'
    self.title = '帮张三囤货深圳的2晚酒店套餐，要买2份（先囤后约的那种），选含早餐的选项，性价比高一点的'
    self.description = '帮张三囤货深圳的2晚酒店套餐，要买2份（先囤后约的那种），选含早餐的选项，性价比高一点的'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @city = '深圳'
      @night_count = 2
      @quantity = 2
    
      # 查找深圳地区的2晚套餐（注意：查询基线数据 data_version=0）
      @available_packages = HotelPackage.where(
        city: @city,
        night_count: @night_count,
        data_version: 0
      )
    
      # 返回给 Agent 的任务信息
      {
        task: "请囤货购买#{@city}地区的酒店套餐（#{@night_count}晚，#{@quantity}份），先囤货后预约，请选择包含早餐的套餐选项（含早套餐或豪华套餐）",
        city: @city,
        night_count: @night_count,
        quantity: @quantity,
        hint: "注意：需要购买#{@quantity}份套餐，请在订单页面修改数量。系统中的酒店套餐通常有多个选项（标准套餐、含早套餐、豪华套餐），请选择含早餐的选项。订单总价应该是单价乘以#{@quantity}份。",
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
      add_assertion "城市正确（深圳）", weight: 10 do
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
    
      # 断言4: 选择了含早餐的选项
      add_assertion "选择了含早餐的套餐选项（含早或豪华套餐）", weight: 25 do
        selected_option = @package_order.package_option
        option_name = selected_option.name
        option_description = selected_option.description
      
        # 检查是否选择了含早餐的选项
        has_breakfast = option_name.include?('含早') || 
                       option_name.include?('豪华') || 
                       (option_description.present? && !option_description.include?('不含早餐'))
      
        expect(has_breakfast).to be_truthy,
          "未选择含早餐的选项。" \
          "建议选择含早套餐或豪华套餐以获得更好的性价比，" \
          "实际选择: #{option_name}（#{option_description}）"
      end
    
      # 断言5: 购买数量正确（2份）
      add_assertion "购买数量正确（#{@quantity}份）", weight: 15 do
        actual_quantity = @package_order.quantity
        expect(actual_quantity).to eq(@quantity),
          "购买数量错误。期望: #{@quantity}份, 实际: #{actual_quantity}份。" \
          "请在订单页面修改购买数量为#{@quantity}份。"
      end
    
      # 断言6: 联系人信息正确
      add_assertion "联系人信息正确（张三 13800138000）", weight: 10 do
        expect(@package_order.contact_name).to eq('张三'),
          "联系人姓名错误。期望: 张三（demo_user数据）, 实际: #{@package_order.contact_name}"
        expect(@package_order.contact_phone).to eq('13800138000'),
          "联系人电话错误。期望: 13800138000（demo_user数据）, 实际: #{@package_order.contact_phone}"
      end
    
      # 断言7: 订单总价正确（单价 × 2份）
      add_assertion "订单总价正确（单价 × #{@quantity}份）", weight: 10 do
        unit_price = @package_order.package_option.price
        expected_total = unit_price * @quantity
        actual_total = @package_order.total_price
      
        expect(actual_total).to eq(expected_total),
          "订单总价错误。期望: #{expected_total}元（单价#{unit_price}元 × #{@quantity}份），实际: #{actual_total}元"
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
  
    # 模拟 AI Agent 操作：囤货购买深圳地区含早餐的酒店套餐（2份）
    def simulate
      # 1. 查找测试用户（数据包中已创建）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 2. 查找测试乘客张三（数据包中已创建）
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
    
      # 3. 查找深圳地区的2晚套餐
      available_packages = HotelPackage.where(
        city: @city,
        night_count: @night_count,
        data_version: 0
      )
    
      raise "未找到符合条件的酒店套餐" if available_packages.empty?
    
      # 4. 选择第一个套餐（简化逻辑）
      target_package = available_packages.first
    
      # 5. 从该套餐的选项中选择含早餐的选项
      target_option = target_package.package_options
        .where(data_version: 0)
        .order(Arel.sql("CASE WHEN name LIKE '%含早%' THEN 1 WHEN name LIKE '%豪华%' THEN 2 ELSE 3 END"))
        .first
    
      raise "未找到可用的套餐选项" unless target_option
    
      # 6. 创建酒店套餐订单（囤货模式：不需要入住日期，购买2份）
      package_order = HotelPackageOrder.create!(
        hotel_package_id: target_package.id,
        package_option_id: target_option.id,
        user_id: user.id,
        passenger_id: zhangsan.id,
        quantity: @quantity,
        total_price: target_option.price * @quantity,
        booking_type: 'stockup',
        status: 'pending',
        contact_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        data_version: @data_version
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
        unit_price: target_option.price,
        quantity: @quantity,
        total_price: package_order.total_price,
        booking_type: 'stockup',
        user_email: user.email
      }
    end
  end
end
