# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例284: 给张三和王芳预订本周末7天酒店快捷1晚套餐（武汉多店通用，本周六入住、本周日退房）
#
# 任务描述:
#   张三和王芳（夫妻）计划本周末短途度假，需要预订1晚的酒店套餐。
#   要求选择经济型酒店套餐（按价格升序选择最便宜的），套餐时长1晚，本周六入住、本周日退房。
#   预订时需要指定房间数量（1间）、入住人数（成人2人、儿童0人）。
#   Agent 需要理解周末度假的日期计算，在符合条件的酒店套餐中选择性价比高的产品，并填写联系人信息完成预订。
#
# 业务流程（7个关键步骤）：
#   1. 搜索酒店套餐产品
#   2. 筛选1晚时长的套餐
#   3. 按价格升序排列，选择最便宜的产品
#   4. 计算本周末日期（本周六入住、本周日退房）
#   5. 设置客房和入住人数（房间数量1间、成人2人、儿童0人）
#   6. 填写联系人信息（张三或王芳）
#   7. 提交订单并确认预订
#
# 复杂度分析（7个关键点）：
#   1. 需要理解日期计算：计算本周六和本周日的具体日期
#   2. 需要理解周末逻辑：入住日期必须是周六，退房日期必须是周日
#   3. 需要理解套餐时长：选择1晚的短途套餐
#   4. 需要理解价格排序：按价格升序选择最经济实惠的产品
#   5. 需要理解客房和入住人数设置：room_count=1间、adult_count=2人（夫妻）、child_count=0人
#   6. 需要理解联系人选择：张三或王芳任意一人及其电话号码
#   7. 需要理解入住退房日期关系：退房日期 = 入住日期 + 1天
#   ❌ 不能随机选择：必须精确匹配套餐时长、入住日期、联系人信息、客房信息
#
# 评分标准（8项，总计100分）：
#   - 创建了酒店套餐订单（20分）
#   - 套餐时长正确（1晚）（12分）
#   - 联系人信息正确（张三或王芳）（12分）
#   - 入住日期正确（本周六）（18分）
#   - 退房日期正确（本周日）（18分）
#   - 房间数量正确（1间）（8分）
#   - 入住人数正确（成人2人，儿童0人）（8分）
#   - 订单状态正确（4分）
module V251V300
  class V284BookWeekendGetawayPackageValidator < BaseValidator
    self.validator_id = 'v284_book_weekend_getaway_package_validator'
    self.task_id = '1c21acda-6325-4222-95e3-d62e336cf477'
    self.title = '给张三和王芳预订本周末7天酒店快捷1晚套餐（武汉多店通用，本周六入住、本周日退房）'
    self.description = '给张三和王芳预订本周末7天酒店快捷1晚套餐（武汉多店通用，本周六入住、本周日退房）'
    self.timeout_seconds = 300
    
    def prepare
      # 计算本周末的日期（本周六和本周日）
      today = Date.current
      days_until_saturday = (6 - today.wday) % 7
      days_until_saturday = 7 if days_until_saturday == 0  # 如果今天是周六，则取下个周六
      @check_in_date = today + days_until_saturday.days
      @check_out_date = @check_in_date + 1.day
      
      @night_count = 1
      @package = HotelPackage.where(night_count: @night_count, data_version: 0)
                            .order(price: :asc)
                            .first!
      
      # 预查询乘客信息（张三和王芳夫妻）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 联系人可以是张三或王芳
      @valid_contact_names = [@zhangsan.name, @wangfang.name]
      @valid_contact_phones = [@zhangsan.phone, @wangfang.phone]
      
      if user.balance < @package.price
        user.update!(balance: @package.price + 500)
      end
      
      {
        task: "请给张三和王芳（夫妻）预订酒店套餐「#{@package.title}」。重要：入住日期必须是#{@check_in_date}（#{@check_in_date.strftime('%Y年%-m月%-d日')}，本周六），退房日期必须是#{@check_out_date}（#{@check_out_date.strftime('%Y年%-m月%-d日')}，本周日），享受#{@night_count}晚周末短途度假。",
        package_title: @package.title,
        night_count: @night_count,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        price: @package.price.to_f,
        hint: "必须使用指定的入住日期#{@check_in_date}和退房日期#{@check_out_date}，不要自己计算周末日期"
      }
    end
    
    def verify
      add_assertion "创建了酒店套餐订单", weight: 20 do
        @order = HotelPackageOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到酒店套餐订单"
      end
      
      return unless @order
      
      add_assertion "套餐时长正确（#{@night_count}晚）", weight: 12 do
        package = @order.hotel_package
        expect(package).not_to be_nil, "订单没有关联套餐"
        expect(package.night_count).to eq(@night_count),
          "套餐时长错误。期望: #{@night_count}晚（周末短途）, 实际: #{package.night_count}晚"
      end
      
      add_assertion "联系人信息正确（张三或王芳）", weight: 12 do
        is_valid_contact = @valid_contact_names.include?(@order.contact_name) && 
                          @valid_contact_phones.include?(@order.contact_phone)
        
        expect(is_valid_contact).to be_truthy,
          "联系人信息错误。期望: 张三(#{@zhangsan.phone})或王芳(#{@wangfang.phone}), 实际: #{@order.contact_name}(#{@order.contact_phone})"
      end
      
      add_assertion "入住日期正确（本周六）", weight: 18 do
        expect(@order.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date.strftime('%Y-%m-%d')}（本周六）, 实际: #{@order.check_in_date&.strftime('%Y-%m-%d')}"
        expect(@check_in_date.saturday?).to be_truthy,
          "入住日期不是周六。实际: #{@check_in_date.strftime('%A')}"
      end
      
      add_assertion "退房日期正确（本周日）", weight: 18 do
        expect(@order.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date.strftime('%Y-%m-%d')}（本周日）, 实际: #{@order.check_out_date&.strftime('%Y-%m-%d')}"
        expect(@check_out_date.sunday?).to be_truthy,
          "退房日期不是周日。实际: #{@check_out_date.strftime('%A')}"
      end
      
      add_assertion "房间数量正确（1间）", weight: 8 do
        actual_room_count = @order.room_count
        expected_room_count = 1
        
        expect(actual_room_count).to eq(expected_room_count),
          "房间数量错误。期望: #{expected_room_count}间, 实际: #{actual_room_count}间"
      end
      
      add_assertion "入住人数正确（成人2人，儿童0人）", weight: 8 do
        actual_adult_count = @order.adult_count
        actual_child_count = @order.child_count
        expected_adult_count = 2  # 张三和王芳夫妻
        expected_child_count = 0
        
        expect(actual_adult_count).to eq(expected_adult_count),
          "成人数量错误。期望: #{expected_adult_count}人（张三和王芳夫妻）, 实际: #{actual_adult_count}人"
        
        expect(actual_child_count).to eq(expected_child_count),
          "儿童数量错误。期望: #{expected_child_count}人, 实际: #{actual_child_count}人"
      end
      
      add_assertion "订单状态正确", weight: 4 do
        expect(@order.status).to eq('pending').or(eq('confirmed')).or(eq('paid')),
          "订单状态错误。期望: pending/confirmed/paid, 实际: #{@order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      HotelPackageOrder.create!(
        user_id: user.id,
        hotel_package_id: @package.id,
        hotel_id: @package.hotel_id,
        package_option_id: 1,
        passenger_id: user.id,
        quantity: 1,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        room_count: 1,
        adult_count: 2,  # 张三和王芳夫妻
        child_count: 0,
        total_price: @package.price,
        booking_type: 'stockup',
        status: 'pending',
        contact_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        night_count: @night_count,
        package_id: @package&.id,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        valid_contact_names: @valid_contact_names,
        valid_contact_phones: @valid_contact_phones,
        zhangsan_phone: @zhangsan&.phone,
        wangfang_phone: @wangfang&.phone
      }
    end
    
    def restore_from_state(data)
      @night_count = data['night_count']
      @package = HotelPackage.find(data['package_id']) if data['package_id']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @valid_contact_names = data['valid_contact_names'] || ['张三', '王芳']
      @valid_contact_phones = data['valid_contact_phones'] || []
      
      # 重新查询乘客信息以获取phone
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 恢复保存的phone值（如果有）
      @zhangsan_phone = data['zhangsan_phone'] if data['zhangsan_phone']
      @wangfang_phone = data['wangfang_phone'] if data['wangfang_phone']
    end
  end
end
