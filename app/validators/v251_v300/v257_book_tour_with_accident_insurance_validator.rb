# frozen_string_literal: true

require_relative '../base_validator'

# V257: 张三和李四5天后要去黄山跟团游(2天行程,2人)，需要预订跟团游并购买境内旅游保险(意外伤害保障,保险天数≥2天)
#
# 任务描述:
#   张三和李四计划5天后参加黄山跟团游（2天行程，2人），为保障旅途安全，
#   需要为跟团游购买境内旅游保险（意外伤害保障），保险天数需覆盖旅游天数。
#
# 业务流程:
#   1. 用户输入：目的地（黄山）、出发日期（5天后）、人数（2人：张三、李四）、需求（意外伤害保险）
#   2. 系统筛选：显示黄山跟团游产品（2天行程），同时展示适配的境内旅游保险
#   3. 用户选择：选择合适的跟团游套餐，确认保险天数与旅游天数匹配
#   4. 填写信息：联系人（张三或李四）、投保人（张三、李四），确认保险保障范围（意外伤害）
#   5. 确认支付：核对跟团游信息（目的地、日期、人数）、保险信息（类型、天数、投保人）、总价格
#   6. 完成订单：生成跟团游订单和保险订单，获取旅游凭证和保险凭证
#
# 复杂度分析:
#   1. **跨模型订单关联**（中）：需同时创建TourGroupBooking和InsuranceOrder，并建立关联关系
#   2. **保险天数匹配逻辑**（中）：保险天数必须≥旅游天数，需查询min_days/max_days范围
#   3. **多人投保处理**（中）：2人跟团游，保险订单需包含2个投保人（insured_persons数组）
#   4. **保险类型识别**（低）：识别境内旅游保险（product_type: 'domestic'）
#   5. **价格计算验证**（低）：保险价格 = 单价(price_per_day × 天数) × 人数
#
# 评分标准（总分100%）:
#   - 创建了跟团游订单 (18%) - 基础操作
#   - 出发日期正确（5天后） (5%) - 日期准确性
#   - 创建了保险订单 (18%) - 核心操作
#   - 保险类型正确（境内旅游保险 domestic）(18%) - 核心要求（最高权重之一）
#   - 保险保障天数与旅游天数匹配（≥2天）(15%) - 业务逻辑正确性
#   - 联系人信息正确（张三或李四） (10%) - 信息完整性
#   - 投保人信息正确（张三、李四） (10%) - 多人投保验证
#   - 订单状态有效 (6%) - 订单可用性
module V251V300
  class V257BookTourWithAccidentInsuranceValidator < BaseValidator
    self.validator_id = 'v257_book_tour_with_accident_insurance_validator'
    self.task_id = '685c598f-4c18-4710-ac08-c68f515ff29e'
    self.title = '张三和李四5天后要去黄山跟团游(2天行程,2人)，需要预订跟团游并购买境内旅游保险(意外伤害保障,保险天数≥2天)'
    self.description = '张三和李四5天后要去黄山跟团游（2天行程，2人），需要预订跟团游并购买境内旅游保险（意外伤害保障，保险天数≥2天）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '黄山'
      @travel_date = Date.current + 5.days
      @adult_count = 2
      
      # 查询 demo_user 和乘客信息（基线数据）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_contact_names = [@zhangsan.name, @lisi.name]
      @expected_contact_phones = { '张三' => @zhangsan.phone, '李四' => @lisi.phone }
      @expected_insured_names = [@zhangsan.name, @lisi.name]
      
      # 查找跟团游产品
      @tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where('duration >= ?', 2)
        .first
      
      raise "未找到#{@destination}的跟团游产品" unless @tour_product
      
      @duration = @tour_product.duration
      
      # 查找适合跟团游的保险产品
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @duration, @duration)
        .to_a
      
      raise "未找到适合#{@duration}天的保险产品" if @available_insurances.empty?
      
      {
        title: "今天是#{Date.current.strftime('%Y年%m月%d日')}。#{self.class.title}",
        description: self.class.description,
        requirements: {
          destination: @destination,
          travel_date: @travel_date,
          duration: "#{@duration}天",
          passengers: '张三、李四（2人）',
          insurance_type: '境内旅游保险（domestic）',
          insurance_coverage: '意外伤害保障',
          insurance_days: "至少#{@duration}天（覆盖旅游天数）",
          purpose: '跟团游安全保障'
        },
        hint: "跟团游建议购买境内旅游保险（product_type: domestic），保险天数应≥旅游天数（#{@duration}天）。"
      }
    end
    
    def verify
      # 断言1: 创建了跟团游订单 (18%) - 基础操作
      add_assertion "创建了跟团游订单", weight: 18 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .to_a
        
        @tour_booking = all_bookings.first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游订单"
      end
      
      return if @tour_booking.nil?
      
      # 断言2: 出发日期正确（5天后） (5%) - 日期准确性
      add_assertion "出发日期正确（5天后#{@travel_date}）", weight: 5 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出发日期错误。期望: #{@travel_date}（5天后），实际: #{@tour_booking.travel_date}"
      end
      
      # 断言3: 创建了保险订单 (18%) - 核心操作
      add_assertion "创建了保险订单", weight: 18 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      # 断言4: 保险类型正确（境内旅游保险 domestic） (18%) - 核心要求（最高权重之一）
      add_assertion "保险类型正确（境内旅游保险 domestic）", weight: 18 do
        product_type = @insurance_order.insurance_product.product_type
        expect(product_type).to eq('domestic'),
          "保险类型错误，无法保障境内跟团游。期望: domestic（境内旅游保险），实际: #{product_type}（保险产品: #{@insurance_order.insurance_product.name}）"
      end
      
      # 断言5: 保险保障天数与旅游天数匹配（≥2天） (15%) - 业务逻辑正确性
      add_assertion "保险保障天数与旅游天数匹配（≥#{@duration}天）", weight: 15 do
        insurance_days = @insurance_order.days
        tour_duration = @tour_booking.tour_group_product.duration
        
        expect(insurance_days).to be >= tour_duration,
          "保险天数不足，无法覆盖全程旅游。期望: ≥#{tour_duration}天（旅游天数），实际: #{insurance_days}天（保险产品: #{@insurance_order.insurance_product.name}）"
      end
      
      # 断言6: 联系人信息正确（张三或李四） (10%) - 信息完整性
      add_assertion "联系人信息正确（张三或李四）", weight: 10 do
        expect(@expected_contact_names).to include(@tour_booking.contact_name),
          "联系人姓名错误。期望: 张三或李四，实际: #{@tour_booking.contact_name}"
        
        expected_phone = @expected_contact_phones[@tour_booking.contact_name]
        expect(@tour_booking.contact_phone).to eq(expected_phone),
          "联系电话与联系人不匹配。联系人: #{@tour_booking.contact_name}，期望电话: #{expected_phone}，实际电话: #{@tour_booking.contact_phone}"
      end
      
      # 断言7: 投保人信息正确（张三、李四） (10%) - 多人投保验证
      add_assertion "投保人信息正确（张三、李四）", weight: 10 do
        insured = @insurance_order.insured_persons || []
        expect(insured).not_to be_empty, "未填写投保人信息"
        
        # 验证投保人数量
        expect(insured.size).to eq(2),
          "投保人数量错误。期望: 2人（张三、李四），实际: #{insured.size}人"
        
        # 验证每个投保人的姓名
        actual_names = insured.map { |p| p['name'] }.compact.sort
        expected_names = @expected_insured_names.sort
        expect(actual_names).to eq(expected_names),
          "投保人姓名错误。期望: #{expected_names.join('、')}，实际: #{actual_names.join('、')}"
        
        # 验证每个投保人都有身份证号
        @expected_insured_names.each do |name|
          person = insured.find { |p| p['name'] == name }
          expect(person).not_to be_nil,
            "投保人列表中缺少#{name}。期望: [张三, 李四]，实际: #{actual_names.join('、')}"
          expect(person['id_number']).to be_present,
            "投保人#{name}的身份证号缺失"
        end
      end
      
      # 断言8: 订单状态有效 (6%) - 订单可用性
      add_assertion "订单状态有效", weight: 6 do
        expect(@tour_booking.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@insurance_order.status).to be_in(['pending', 'paid'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建跟团游订单
      tour_package = @tour_product.tour_packages.where(data_version: 0).first!
      
      # 随机选择联系人（张三或李四）
      contact = [@zhangsan, @lisi].sample
      
      tour_booking = TourGroupBooking.create!(
        user: user,
        tour_group_product: @tour_product,
        tour_package: tour_package,
        travel_date: @travel_date,
        adult_count: @adult_count,
        child_count: 0,
        contact_name: contact.name,
        contact_phone: contact.phone,
        insurance_type: 'none',
        total_price: @tour_product.price * @adult_count,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 创建保险订单
      insurance_product = @available_insurances.first
      start_date = @travel_date
      end_date = start_date + @duration - 1
      unit_price = insurance_product.price_per_day * @duration
      
      # 构建投保人数据（必须包含name和id_number）
      insured_persons_data = [
        { name: @zhangsan.name, id_number: @zhangsan.id_number },
        { name: @lisi.name, id_number: @lisi.id_number }
      ]
      
      InsuranceOrder.create!(
        user: user,
        insurance_product: insurance_product,
        source: 'standalone',
        related_booking_type: 'TourGroupBooking',
        related_booking_id: tour_booking.id,
        start_date: start_date,
        end_date: end_date,
        days: @duration,
        destination: @destination,
        destination_type: 'domestic',
        insured_persons: insured_persons_data,
        unit_price: unit_price,
        quantity: @adult_count,
        total_price: unit_price * @adult_count,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date.to_s,
        adult_count: @adult_count,
        duration: @duration,
        tour_product_id: @tour_product&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones,
        expected_insured_names: @expected_insured_names
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date'])
      @adult_count = data['adult_count']
      @duration = data['duration']
      @expected_contact_names = data['expected_contact_names']
      @expected_contact_phones = data['expected_contact_phones']
      @expected_insured_names = data['expected_insured_names']
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      
      @tour_product = TourGroupProduct.find(data['tour_product_id']) if data['tour_product_id']
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @duration, @duration)
        .to_a
    end
  end
end
