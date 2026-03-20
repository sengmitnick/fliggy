# frozen_string_literal: true

require_relative '../base_validator'

# V265: 帮张三、王芳和小明预订4天后三亚家庭跟团游（2成人+1儿童，共3人），并购买适合家庭出行的境内保险套餐（3人投保，保险类型包含亲子游或家庭保障场景）
#
# 任务描述:
#   帮张三、王芳和小明预订4天后三亚家庭跟团游（2成人+1儿童，共3人），
#   并购买适合家庭出行的境内保险套餐（境内旅游险，优先选择包含亲子游或家庭保障场景）。
#   保险需为3人投保（张三、王芳、小明），保障范围包含成人和儿童。
#   家庭游场景优先选择含亲子游或家庭保障场景的境内旅游险，其次可选择普通境内旅游险。
#
# 业务流程:
#   1. 用户输入：目的地（三亚）、出发日期（4天后）、人数（2成人+1儿童：张三、王芳、小明）、需求（家庭游+保险）
#   2. 系统筛选：显示三亚家庭跟团游产品（4天后出发），同时展示适配的家庭保险（境内旅游险，含亲子游场景）
#   3. 用户选择：选择合适的跟团游套餐，确认保险天数与旅游天数匹配
#   4. 填写信息：联系人（张三/王芳二选一）、游客信息（2成人+1儿童）、被保险人（张三、王芳、小明3人）
#   5. 确认支付：核对跟团游订单、保险订单信息和总价格
#   6. 完成订单：生成2个订单（TourGroupBooking + InsuranceOrder），保险关联到TourGroupBooking
#   7. 获取凭证：获取跟团游订单凭证、保险凭证
#
# 复杂度分析:
#   1. **跨模型订单关联逻辑**（中）：需同时创建TourGroupBooking和InsuranceOrder，并建立关联关系
#   2. **家庭保险类型筛选**（中）：优先选择包含亲子游或家庭保障场景的境内旅游险，其次可选择普通境内旅游险
#   3. **混合人群投保处理**（高）：2成人+1儿童家庭组合，保险订单需区分traveler_type（adult/child），需包含3个被保险人（insured_persons数组）和身份证号
#   4. **游客与被保险人一致性验证**（中）：验证被保险人姓名和身份证号与游客信息完全一致，含成人和儿童
#   5. **儿童游客特殊处理**（低）：验证儿童游客（小明）的traveler_type为child，计价方式不同（child_price）
#
# 评分标准（总分100%）:
#   - 创建了跟团游订单 (20%) - 基础操作（最高权重之一）
#   - 出发日期正确（4天后） (10%) - 日期准确性
#   - 创建了游客信息（张三、王芳、小明） (15%) - 游客信息完整性（含2成人+1儿童区分、身份证号）
#   - 联系人信息正确（张三/王芳二选一） (10%) - 联系人信息准确性
#   - 创建了保险订单 (15%) - 核心操作
#   - 保险适合家庭出行 (10%) - 核心要求（境内旅游险，优先选择亲子游/家庭保障场景）
#   - 被保险人与游客信息一致 (10%) - 信息一致性验证（含姓名和身份证号）
#   - 订单状态有效 (10%) - 订单可用性
module V251V300
  class V265BookFamilyTourWithFamilyInsuranceValidator < BaseValidator
    self.validator_id = 'v265_book_family_tour_with_family_insurance_validator'
    self.task_id = '89326e33-0407-4028-8d62-82ea40ebd791'
    self.title = '帮张三、王芳和小明预订4天后三亚家庭跟团游（2成人+1儿童，共3人），并购买适合家庭出行的境内保险套餐（3人投保，保险类型包含亲子游或家庭保障场景）'
    self.description = '帮张三、王芳和小明预订4天后三亚家庭跟团游（2成人+1儿童，共3人），并购买适合家庭出行的境内保险套餐（3人投保，保险类型包含亲子游或家庭保障场景）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '三亚'
      @travel_date = Date.current + 4.days
      @adult_count = 2
      @child_count = 1
      @total_persons = @adult_count + @child_count
      
      # 查询用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      @expected_contact_names = [@zhangsan.name, @wangfang.name]  # 联系人二选一
      @expected_traveler_names = [@zhangsan.name, @wangfang.name, @xiaoming.name]
      @expected_insured_names = [@zhangsan.name, @wangfang.name, @xiaoming.name]
      
      # 查找适合家庭的跟团游
      @tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .first
      
      raise "未找到#{@destination}的跟团游产品" unless @tour_product
      
      @duration = @tour_product.duration
      
      # 查找适合家庭的保险产品
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @duration, @duration)
        .select { |p| p.scenes&.include?('亲子游') || p.scenes&.include?('家庭保障') }
      
      # 如果没有家庭保险，使用普通境内保险
      if @available_insurances.empty?
        @available_insurances = InsuranceProduct
          .where(product_type: 'domestic', data_version: 0)
          .where('min_days <= ? AND max_days >= ?', @duration, @duration)
          .to_a
      end
      
      raise "未找到适合#{@duration}天的保险产品" if @available_insurances.empty?
      
      {
        task: "请帮张三、王芳和小明预订#{@destination}家庭游（#{@travel_date.strftime('%Y年%m月%d日')}出发，4天后出发，#{@duration}天，2大1小共3人），并购买全家保险套餐。3人都需要投保。",
        requirements: {
          destination: @destination,
          travel_date: @travel_date,
          duration: @duration,
          family_composition: '2大1小',
          total_persons: @total_persons,
          insurance_type: '家庭保险套餐',
          insurance_coverage: '全家保障'
        },
        hint: "家庭游建议购买适合亲子游的保险产品，需包含儿童保障，投保人数应为3人。"
      }
    end
    
    def verify
      add_assertion "创建了跟团游订单", weight: 20 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product, :booking_travelers)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .to_a
        
        @tour_booking = all_bookings.first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游订单"
      end
      
      return if @tour_booking.nil?
      
      add_assertion "出发日期正确（4天后）", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出发日期错误。期望: #{@travel_date}（4天后），实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "创建了游客信息（张三、王芳、小明）", weight: 15 do
        @travelers = @tour_booking.booking_travelers.where(data_version: @data_version).to_a
        
        expect(@travelers.size).to eq(@total_persons),
          "游客数量错误。期望: #{@total_persons}人（2大1小），实际: #{@travelers.size}人"
        
        # 验证游客姓名
        traveler_names = @travelers.map(&:traveler_name).sort
        expected_names = @expected_traveler_names.sort
        
        expect(traveler_names).to eq(expected_names),
          "游客姓名错误。期望: #{expected_names.join('、')}，实际: #{traveler_names.join('、')}"
        
        # 验证游客类型（2个成人+1个儿童）
        adult_travelers = @travelers.select { |t| t.traveler_type == 'adult' }
        child_travelers = @travelers.select { |t| t.traveler_type == 'child' }
        
        expect(adult_travelers.size).to eq(@adult_count),
          "成人游客数量错误。期望: #{@adult_count}人，实际: #{adult_travelers.size}人"
        expect(child_travelers.size).to eq(@child_count),
          "儿童游客数量错误。期望: #{@child_count}人，实际: #{child_travelers.size}人"
        
        # 验证儿童是小明
        expect(child_travelers.map(&:traveler_name)).to include(@xiaoming.name),
          "儿童游客应该是#{@xiaoming.name}"
        
        # 验证身份证号
        @travelers.each do |traveler|
          expect(traveler.id_number).not_to be_blank,
            "#{traveler.traveler_name}的身份证号不能为空"
        end
      end
      
      return if @travelers.nil? || @travelers.empty?
      
      add_assertion "联系人信息正确（张三/王芳二选一）", weight: 10 do
        contact_name = @tour_booking.contact_name
        expect(@expected_contact_names).to include(contact_name),
          "联系人姓名错误。期望: #{@expected_contact_names.join('/')}中任一人，实际: #{contact_name}"
        
        # 验证联系电话属于联系人
        contact_phone = @tour_booking.contact_phone
        valid_phones = [@zhangsan.phone, @wangfang.phone]
        expect(valid_phones).to include(contact_phone),
          "联系电话错误。期望: 张三或王芳的电话，实际: #{contact_phone}"
      end
      
      add_assertion "创建了保险订单", weight: 15 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险适合家庭出行", weight: 10 do
        scenes = @insurance_order.insurance_product.scenes || []
        is_family_suitable = scenes.include?('亲子游') || 
                             scenes.include?('家庭保障') ||
                             @insurance_order.insurance_product.product_type == 'domestic'
        
        expect(is_family_suitable).to be_truthy,
          "保险不适合家庭出行。保险场景: #{scenes.inspect}"
      end
      
      add_assertion "被保险人与游客信息一致", weight: 10 do
        insured_persons = @insurance_order.insured_persons || []
        expect(insured_persons.size).to eq(@total_persons),
          "被保险人数量错误。期望: #{@total_persons}人（2大1小），实际: #{insured_persons.size}人"
        
        # 提取被保险人姓名
        actual_insured_names = insured_persons.map { |p| p.is_a?(Hash) ? p['name'] : p }.compact.sort
        
        # 提取游客姓名
        traveler_names = @travelers.map(&:traveler_name).sort
        
        # 验证被保险人与游客一致
        expect(actual_insured_names).to eq(traveler_names),
          "被保险人与游客不一致。游客: #{traveler_names.join('、')}，被保险人: #{actual_insured_names.join('、')}"
        
        # 验证被保险人身份证号
        insured_persons.each do |person|
          name = person.is_a?(Hash) ? person['name'] : person
          id_number = person.is_a?(Hash) ? person['id_number'] : nil
          
          # 找到对应的游客
          traveler = @travelers.find { |t| t.traveler_name == name }
          expect(traveler).not_to be_nil, "被保险人#{name}在游客列表中未找到"
          
          # 验证身份证号一致
          if id_number.present?
            expect(id_number).to eq(traveler.id_number),
              "#{name}的身份证号不一致。游客: #{traveler.id_number}，被保险人: #{id_number}"
          end
        end
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@tour_booking.status).to be_in(['pending', 'paid', 'confirmed']),
          "旅游订单状态无效: #{@tour_booking.status}"
        expect(@insurance_order.status).to be_in(['pending', 'paid']),
          "保险订单状态无效: #{@insurance_order.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建跟团游订单
      tour_package = @tour_product.tour_packages.where(data_version: 0).first!
      base_price = (tour_package.price * @adult_count) + (tour_package.child_price * @child_count)
      
      tour_booking = TourGroupBooking.create!(
        user: user,
        tour_group_product: @tour_product,
        tour_package: tour_package,
        travel_date: @travel_date,
        adult_count: @adult_count,
        child_count: @child_count,
        contact_name: @zhangsan.name,
        contact_phone: @zhangsan.phone,
        insurance_type: 'none',
        total_price: base_price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 创建游客记录（2成人+1儿童）
      BookingTraveler.create!(
        tour_group_booking: tour_booking,
        traveler_name: @zhangsan.name,
        id_number: @zhangsan.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      BookingTraveler.create!(
        tour_group_booking: tour_booking,
        traveler_name: @wangfang.name,
        id_number: @wangfang.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      BookingTraveler.create!(
        tour_group_booking: tour_booking,
        traveler_name: @xiaoming.name,
        id_number: @xiaoming.id_number,
        traveler_type: 'child',
        data_version: @data_version
      )
      
      # 3. 创建保险订单（使用与游客一致的被保险人信息）
      insurance_product = @available_insurances.first
      start_date = @travel_date
      end_date = start_date + @duration - 1
      unit_price = insurance_product.price_per_day * @duration
      
      insured_persons_data = [
        { name: @zhangsan.name, id_number: @zhangsan.id_number },
        { name: @wangfang.name, id_number: @wangfang.id_number },
        { name: @xiaoming.name, id_number: @xiaoming.id_number }
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
        quantity: @total_persons,
        total_price: unit_price * @total_persons,
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
        child_count: @child_count,
        total_persons: @total_persons,
        duration: @duration,
        tour_product_id: @tour_product&.id,
        zhangsan_id: @zhangsan&.id,
        wangfang_id: @wangfang&.id,
        xiaoming_id: @xiaoming&.id,
        expected_contact_names: @expected_contact_names
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date'])
      @adult_count = data['adult_count']
      @child_count = data['child_count']
      @total_persons = data['total_persons']
      @duration = data['duration']
      
      @tour_product = TourGroupProduct.find(data['tour_product_id']) if data['tour_product_id']
      
      # 恢复乘客信息
      if data['zhangsan_id'] && data['wangfang_id'] && data['xiaoming_id']
        @zhangsan = Passenger.find(data['zhangsan_id'])
        @wangfang = Passenger.find(data['wangfang_id'])
        @xiaoming = Passenger.find(data['xiaoming_id'])
        @expected_contact_names = data['expected_contact_names'] || [@zhangsan.name, @wangfang.name]
        @expected_traveler_names = [@zhangsan.name, @wangfang.name, @xiaoming.name]
        @expected_insured_names = [@zhangsan.name, @wangfang.name, @xiaoming.name]
      end
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @duration, @duration)
        .select { |p| p.scenes&.include?('亲子游') || p.scenes&.include?('家庭保障') }
      
      if @available_insurances.empty?
        @available_insurances = InsuranceProduct
          .where(product_type: 'domestic', data_version: 0)
          .where('min_days <= ? AND max_days >= ?', @duration, @duration)
          .to_a
      end
    end
  end
end
