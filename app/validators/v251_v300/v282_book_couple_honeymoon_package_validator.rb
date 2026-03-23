# frozen_string_literal: true

require_relative '../base_validator'

# V282: 给张三和王芳预订3天后三亚希尔顿高档酒店套餐（至少2晚）
#
# 任务描述:
#   张三和王芳计划3天后入住三亚希尔顿品牌的高档酒店，需要预订酒店套餐。
#   要求选择三亚希尔顿品牌的酒店套餐，套餐时长至少2晚，按价格降序选择高档产品。
#   Agent 需要在符合条件的酒店套餐中，选择合适的产品，并填写联系人信息完成预订。
#
# 业务流程（6个关键步骤）：
#   1. 搜索酒店套餐产品
#   2. 筛选希尔顿品牌的酒店套餐
#   3. 选择套餐时长至少2晚的产品
#   4. 按价格降序排列，选择高档产品
#   5. 填写入住日期（3天后）和联系人信息（张三）
#   6. 提交订单并确认预订
#
# 复杂度分析（5个关键点）：
#   1. 需要理解品牌筛选：选择三亚希尔顿品牌的酒店套餐
#   2. 需要理解套餐时长：至少2晚的套餐
#   3. 需要理解价格排序：按价格降序选择高档产品
#   4. 需要理解入住日期计算：3天后（Date.current + 3.days）
#   5. 需要理解联系人选择：张三及其电话号码
#   ❌ 不能随机选择：必须精确匹配品牌关键词、套餐时长、入住日期
#
# 评分标准（6项，总计100分）：
#   - 创建了酒店套餐订单（25分）
#   - 套餐品牌正确（三亚希尔顿品牌）（20分）
#   - 入住日期正确（3天后）（10分）
#   - 联系人信息正确（张三）（15分）
#   - 套餐时长正确（≥2晚）（15分）
#   - 订单状态正确（15分）
module V251V300
  class V282BookCoupleHoneymoonPackageValidator < BaseValidator
    self.validator_id = 'v282_book_couple_honeymoon_package_validator'
    self.task_id = '34788f50-b5af-484d-b9ee-e8fe13d134bf'
    self.title = '给张三和王芳预订3天后三亚希尔顿高档酒店套餐（至少2晚）'
    self.description = '给张三和王芳预订3天后三亚希尔顿高档酒店套餐（至少2晚）'
    self.timeout_seconds = 300
    
    def prepare
      @keyword = '希尔顿'
      @min_night_count = 2
      @check_in_date = Date.current + 3.days
      @package = HotelPackage.where('title LIKE ?', "%#{@keyword}%")
                            .where(data_version: 0)
                            .where('night_count >= ?', @min_night_count)
                            .order(price: :desc)
                            .first!
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_contact_name = @zhangsan.name
      @expected_contact_phone = @zhangsan.phone
      
      if user.balance < @package.price
        user.update!(balance: @package.price + 1000)
      end
      
      {
        task: "请给张三和王芳预订#{@check_in_date.strftime('%Y年%m月%d日')}入住的三亚希尔顿高档酒店套餐「#{@package.title}」",
        package_title: @package.title,
        price: @package.price.to_f,
        night_count: @package.night_count,
        check_in_date: @check_in_date.strftime('%Y-%m-%d'),
        hint: "选择三亚希尔顿品牌的高档酒店套餐，至少2晚"
      }
    end
    
    def verify
      add_assertion "创建了酒店套餐订单", weight: 25 do
        @order = HotelPackageOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@order).not_to be_nil, "未找到酒店套餐订单"
      end
      
      return unless @order
      
      add_assertion "套餐品牌正确（#{@keyword}）", weight: 20 do
        package = @order.hotel_package
        expect(package).not_to be_nil, "订单没有关联套餐"
        expect(package.title).to include(@keyword),
          "酒店品牌不匹配。期望包含: #{@keyword}, 实际: #{package.title}"
      end
      
      add_assertion "入住日期正确（3天后#{@check_in_date.strftime('%Y-%m-%d')}）", weight: 10 do
        expect(@order.check_in_date).to be_present,
          "缺少入住日期"
        
        expect(@order.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date.strftime('%Y-%m-%d')}（3天后），实际: #{@order.check_in_date}"
      end
      
      add_assertion "联系人信息正确（张三）", weight: 15 do
        expect(@order.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@order.contact_name}"
        expect(@order.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}, 实际: #{@order.contact_phone}"
      end
      
      add_assertion "套餐时长正确（≥#{@min_night_count}晚）", weight: 15 do
        package = @order.hotel_package
        expect(package.night_count).to be >= @min_night_count,
          "套餐时长不足。期望: ≥#{@min_night_count}晚, 实际: #{package.night_count}晚"
      end
      
      add_assertion "订单状态正确", weight: 15 do
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
        keyword: @keyword,
        min_night_count: @min_night_count,
        check_in_date: @check_in_date&.to_s,
        package_id: @package&.id,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @keyword = data['keyword']
      @min_night_count = data['min_night_count']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @package = HotelPackage.find(data['package_id']) if data['package_id']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
