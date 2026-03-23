# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例98: 给张三立即预约上海地区酒店套餐（2晚，含早餐，明天入住）
# 
# 任务描述:
#   用户想立即预约上海地区的酒店套餐，入住时间为明天开始，连住2晚。
#   要求选择包含早餐的套餐选项（含早套餐或豪华套餐），使用立即预约模式（非囤货模式）。
#   预订时需要指定房间数量（1间）、入住人数（成人1人、儿童0人）。
#   Agent 需要搜索符合条件的套餐，选择合适的酒店，并指定具体的入住日期完成预订。
# 
# 业务流程（7个关键步骤）：
#   1. 搜索上海地区的酒店套餐产品
#   2. 筛选2晚的套餐（night_count=2）
#   3. 选择包含早餐的套餐选项（含早套餐或豪华套餐）
#   4. 选择立即预约模式（instant booking，需指定入住日期和酒店）
#   5. 设置入住日期为明天（check_in_date），连住2晚（check_out_date=明天+2天）
#   6. 设置客房和入住人数（房间数量1间、成人1人、儿童0人）
#   7. 填写联系人信息并提交订单
# 
# 复杂度分析（7个关键点）：
#   1. 需要理解城市筛选：上海地区的酒店套餐
#   2. 需要理解套餐晚数：2晚（night_count=2）
#   3. 需要理解预约模式：instant（立即预约，需指定日期和酒店）vs stockup（囤货，不指定日期）
#   4. 需要理解套餐选项：从多个选项中选择含早餐的（含早套餐 > 豪华套餐 > 标准套餐）
#   5. 需要理解入住日期计算：check_in_date=明天，check_out_date=明天+2天
#   6. 需要理解客房和入住人数设置：room_count=1间、adult_count=1人、child_count=0人
#   7. 需要理解联系人信息填写：使用乘客信息中的张三
#   ❌ 不能随机选择：必须精确选择含早餐选项、正确计算入住日期、正确设置客房信息
# 
# 评分标准（10项，总计100分）：
#   - 订单已创建（15分）
#   - 城市正确（上海）（8分）
#   - 套餐晚数正确（2晚）（8分）
#   - 预约模式正确（instant立即预约）（12分）
#   - 选择了含早餐的套餐选项（12分）
#   - 入住日期正确（明天开始，连住2晚）（12分）
#   - 房间数量正确（1间）（8分）
#   - 入住人数正确（成人1人，儿童0人）（8分）
#   - 联系人信息正确（张三）（8分）
#   - 订单价格和数量正确（9分）
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v098_instant_book_hotel_package_with_dates_validator/start
#   
#   # Agent 通过界面操作完成立即预约...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V051V100
  class V098InstantBookHotelPackageWithDatesValidator < BaseValidator
    self.validator_id = 'v098_instant_book_hotel_package_with_dates_validator'
    self.task_id = '89f42d1c-3e8b-4a9f-b2c1-7d5e9a6f8c3a'
    self.title = '给张三立即预约上海地区酒店套餐（2晚，含早餐，明天入住）'
    self.description = '立即预约上海地区酒店套餐（2晚，含早餐，明天入住）'
    self.timeout_seconds = 300
  
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @city = '上海'
      @night_count = 2
      @quantity = 1
      @check_in_date = Date.tomorrow
      @check_out_date = @check_in_date + @night_count.days
    
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @passenger.name
      @expected_contact_phone = @passenger.phone
    
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
      add_assertion "订单已创建", weight: 15 do
        all_orders = HotelPackageOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
      
        expect(all_orders).not_to be_empty, "未找到任何酒店套餐订单记录"
      
        @package_order = all_orders.first
      end
    
      return unless @package_order # 如果没有订单，后续断言无法继续
    
      # 断言2: 城市正确
      add_assertion "城市正确（上海）", weight: 8 do
        actual_city = @package_order.hotel_package.city
        expect(actual_city).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{actual_city}"
      end
    
      # 断言3: 套餐晚数正确
      add_assertion "套餐晚数正确（2晚）", weight: 8 do
        actual_nights = @package_order.hotel_package.night_count
        expect(actual_nights).to eq(@night_count),
          "套餐晚数错误。期望: #{@night_count}晚, 实际: #{actual_nights}晚"
      end
    
      # 断言4: 预约模式正确（instant而非stockup）
      add_assertion "预约模式正确（立即预约）", weight: 12 do
        actual_booking_type = @package_order.booking_type
        expect(actual_booking_type).to eq('instant'),
          "预约模式错误。期望: instant（立即预约）, 实际: #{actual_booking_type}（#{actual_booking_type == 'stockup' ? '囤货模式' : '未知'}）。立即预约需要指定入住日期和酒店。"
      end
    
      # 断言5: 选择了含早餐的选项（核心评分项）
      add_assertion "选择了含早餐的套餐选项（含早或豪华套餐）", weight: 12 do
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
      add_assertion "入住日期正确（明天开始，连住#{@night_count}晚）", weight: 12 do
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
    
      # 断言7: 房间数量正确
      add_assertion "房间数量正确（1间）", weight: 8 do
        actual_room_count = @package_order.room_count
        expected_room_count = 1
      
        expect(actual_room_count).to eq(expected_room_count),
          "房间数量错误。期望: #{expected_room_count}间, 实际: #{actual_room_count}间"
      end
    
      # 断言8: 入住人数正确
      add_assertion "入住人数正确（成人1人，儿童0人）", weight: 8 do
        actual_adult_count = @package_order.adult_count
        actual_child_count = @package_order.child_count
        expected_adult_count = 1
        expected_child_count = 0
      
        expect(actual_adult_count).to eq(expected_adult_count),
          "成人数量错误。期望: #{expected_adult_count}人, 实际: #{actual_adult_count}人"
      
        expect(actual_child_count).to eq(expected_child_count),
          "儿童数量错误。期望: #{expected_child_count}人, 实际: #{actual_child_count}人"
      end
    
      # 断言9: 联系人信息正确（8%）
      add_assertion "联系人信息正确（张三）", weight: 8 do
        expect(@package_order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@package_order.contact_name}"
        expect(@package_order.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@package_order.contact_phone}"
      end
    
      # 断言10: 订单价格和数量正确（9%）
      add_assertion "订单价格和数量正确", weight: 9 do
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
        check_out_date: @check_out_date.to_s,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
  
    # 从状态恢复实例变量
    def restore_from_state(data)
      @city = data['city']
      @night_count = data['night_count']
      @quantity = data['quantity']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @expected_contact_name = data['expected_contact_name'] || '张三'
      @expected_contact_phone = data['expected_contact_phone'] || '13800138000'
    
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
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
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
      HotelPackageOrder.create!(
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
        contact_phone: passenger.phone,
        data_version: @data_version
      )
    end
  end
end