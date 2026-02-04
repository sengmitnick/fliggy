# frozen_string_literal: true

require_relative '../base_validator'

# V265: 预订家庭游+全家保险套餐（2大1小）
#
# 任务描述:
#   用户需要预订家庭游并购买全家保险套餐（2成人+1儿童）
#
# 评分标准:
#   - 创建了跟团游订单 (30%)
#   - 创建了保险订单 (25%)
#   - 保险适合家庭出行 (20%)
#   - 投保人数正确（3人）(15%)
#   - 订单状态有效 (10%)
module V251V300
  class V265BookFamilyTourWithFamilyInsuranceValidator < BaseValidator
    self.validator_id = 'v265_book_family_tour_with_family_insurance_validator'
    self.task_id = 'f257a001-0001-4001-8001-000000000265'
    self.title = '预订家庭游+全家保险套餐（2大1小）'
    self.description = '用户需要预订家庭游并购买全家保险套餐（2成人+1儿童）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '三亚'
      @travel_date = Date.today + 7.days
      @adult_count = 2
      @child_count = 1
      @total_persons = @adult_count + @child_count
      
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
        task: "请预订#{@destination}家庭游（#{@travel_date.strftime('%Y年%m月%d日')}出发，#{@duration}天，2大1小共3人），并购买全家保险套餐。",
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
      add_assertion "创建了跟团游订单", weight: 30 do
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
      
      add_assertion "创建了保险订单", weight: 25 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险适合家庭出行", weight: 20 do
        scenes = @insurance_order.insurance_product.scenes || []
        is_family_suitable = scenes.include?('亲子游') || 
                             scenes.include?('家庭保障') ||
                             @insurance_order.insurance_product.product_type == 'domestic'
        
        expect(is_family_suitable).to be_truthy,
          "保险不适合家庭出行。保险场景: #{scenes.inspect}"
      end
      
      add_assertion "投保人数正确（3人）", weight: 15 do
        quantity = @insurance_order.quantity
        expect(quantity).to eq(@total_persons),
          "投保人数错误。期望: #{@total_persons}人（2大1小），实际: #{quantity}人"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@tour_booking.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@insurance_order.status).to be_in(['pending', 'paid'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建跟团游订单
      tour_booking = TourGroupBooking.create!(
        user: user,
        tour_group_product: @tour_product,
        tour_package: @tour_product.tour_packages.where(data_version: 0).first || TourPackage.create!(
          tour_group_product: @tour_product,
          name: "#{@tour_product.title}标准套餐",
          price: @tour_product.price,
          child_price: @tour_product.price * 0.5,
          data_version: 0
        ),
        travel_date: @travel_date,
        adult_count: @adult_count,
        child_count: @child_count,
        contact_name: user.name,
        contact_phone: '13800138000',
        insurance_type: 'none',
        total_price: @tour_product.price * (@adult_count + @child_count * 0.5),
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 创建保险订单
      insurance_product = @available_insurances.first
      start_date = @travel_date
      end_date = start_date + @duration - 1
      unit_price = insurance_product.price_per_day * @duration
      
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
        insured_persons: ['张三（爸爸）', '李四（妈妈）', '张小明（儿童，8岁）'],
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
        tour_product_id: @tour_product&.id
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
