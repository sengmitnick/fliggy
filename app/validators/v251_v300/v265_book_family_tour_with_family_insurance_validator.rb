# frozen_string_literal: true

require_relative '../base_validator'

# V265: 给张三、王芳和小明预订4天后三亚家庭游（2大1小）+全家境内保险套餐
#
# 任务描述:
#   帮张三、王芳和小明预订4天后三亚家庭跟团游（2成人+1儿童，共3人），并购买适合家庭出行的境内保险套餐（3人投保，保险类型包含亲子游或家庭保障场景）
#
# 评分标准:
#   - 创建了跟团游订单 (25%)
#   - 出发日期正确（4天后）(10%)
#   - 创建了保险订单 (20%)
#   - 保险适合家庭出行 (15%)
#   - 投保人数正确（3人）(10%)
#   - 被保险人信息正确（张三、王芳、小明）(10%)
#   - 订单状态有效 (10%)
module V251V300
  class V265BookFamilyTourWithFamilyInsuranceValidator < BaseValidator
    self.validator_id = 'v265_book_family_tour_with_family_insurance_validator'
    self.task_id = '89326e33-0407-4028-8d62-82ea40ebd791'
    self.title = '给张三、王芳和小明预订4天后三亚家庭游（2大1小）+全家境内保险套餐'
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
      @expected_contact_phone = @zhangsan.phone
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
      add_assertion "创建了跟团游订单", weight: 25 do
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
      
      add_assertion "出发日期正确（4天后）", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出发日期错误。期望: #{@travel_date}（4天后），实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "创建了保险订单", weight: 20 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险适合家庭出行", weight: 15 do
        scenes = @insurance_order.insurance_product.scenes || []
        is_family_suitable = scenes.include?('亲子游') || 
                             scenes.include?('家庭保障') ||
                             @insurance_order.insurance_product.product_type == 'domestic'
        
        expect(is_family_suitable).to be_truthy,
          "保险不适合家庭出行。保险场景: #{scenes.inspect}"
      end
      
      add_assertion "投保人数正确（3人）", weight: 10 do
        quantity = @insurance_order.quantity
        expect(quantity).to eq(@total_persons),
          "投保人数错误。期望: #{@total_persons}人（2大1小），实际: #{quantity}人"
      end
      
      add_assertion "被保险人信息正确（张三、王芳、小明）", weight: 10 do
        insured_persons = @insurance_order.insured_persons || []
        actual_names = insured_persons.map { |p| p.is_a?(Hash) ? p['name'] : p }.compact
        expect(actual_names).to match_array(@expected_insured_names),
          "被保险人姓名错误。期望: #{@expected_insured_names.join('、')}，实际: #{actual_names.join('、')}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@tour_booking.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@insurance_order.status).to be_in(['pending', 'paid'])
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
        contact_phone: @expected_contact_phone,
        insurance_type: 'none',
        total_price: base_price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 创建保险订单（使用预查询的乘客信息）
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
        xiaoming_id: @xiaoming&.id
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
        @expected_contact_phone = @zhangsan.phone
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
