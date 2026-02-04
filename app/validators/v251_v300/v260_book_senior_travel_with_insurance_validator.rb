# frozen_string_literal: true

require_relative '../base_validator'

# V260: 预订老年人出行+高龄旅游保险
#
# 任务描述:
#   用户需要为老年人（65岁以上）预订出行并购买高龄旅游保险
#
# 评分标准:
#   - 创建了跟团游或门票订单 (30%)
#   - 创建了保险订单 (25%)
#   - 保险类型正确（境内旅游保险）(20%)
#   - 保险适合高龄人群 (15%)
#   - 订单状态有效 (10%)
module V251V300
  class V260BookSeniorTravelWithInsuranceValidator < BaseValidator
    self.validator_id = 'v260_book_senior_travel_with_insurance_validator'
    self.task_id = 'f257a001-0001-4001-8001-000000000260'
    self.title = '预订老年人出行+高龄旅游保险'
    self.description = '用户需要为老年人（65岁以上）预订出行并购买高龄旅游保险'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '桂林'
      @travel_date = Date.today + 10.days
      @senior_count = 2
      
      # 查找适合老年人的跟团游
      @tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where('duration <= ?', 5)  # 老年人适合短期游
        .first
      
      raise "未找到#{@destination}的适合老年人的跟团游产品" unless @tour_product
      
      @duration = @tour_product.duration
      
      # 查找保险产品
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @duration, @duration)
        .to_a
      
      raise "未找到适合#{@duration}天的保险产品" if @available_insurances.empty?
      
      {
        task: "请为#{@senior_count}位老年人（65岁以上）预订#{@destination}跟团游（#{@travel_date.strftime('%Y年%m月%d日')}出发，#{@duration}天），并购买高龄旅游保险。",
        requirements: {
          destination: @destination,
          travel_date: @travel_date,
          duration: @duration,
          senior_count: @senior_count,
          age_group: '65岁以上',
          insurance_type: '境内旅游保险',
          insurance_coverage: '老年人专属'
        },
        hint: "老年人出行需要购买境内旅游保险，保障应涵盖意外伤害和医疗费用。"
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
      
      add_assertion "保险类型正确（境内旅游保险）", weight: 20 do
        product_type = @insurance_order.insurance_product.product_type
        expect(product_type).to eq('domestic'),
          "保险类型错误。期望: domestic（境内旅游），实际: #{product_type}"
      end
      
      add_assertion "保险适合高龄人群", weight: 15 do
        # 检查保险是否有足够的意外伤害和医疗保障
        coverage = @insurance_order.insurance_product.coverage_details || {}
        accident_coverage = coverage['accident'] || 0
        medical_coverage = coverage['medical'] || 0
        
        expect(accident_coverage).to be >= 500000,
          "意外伤害保额不足。老年人建议至少50万元，实际: #{accident_coverage/10000}万元"
        expect(medical_coverage).to be >= 50000,
          "医疗费用保额不足。老年人建议至少5万元，实际: #{medical_coverage/10000}万元"
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
        adult_count: @senior_count,
        child_count: 0,
        contact_name: user.name,
        contact_phone: '13800138000',
        insurance_type: 'none',
        total_price: @tour_product.price * @senior_count,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 2. 创建保险订单（选择保额较高的产品）
      insurance_product = @available_insurances
        .select { |p| (p.coverage_details['accident'] || 0) >= 500000 }
        .first || @available_insurances.first
      
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
        insured_persons: ['王大爷（68岁）', '李大妈（66岁）'],
        unit_price: unit_price,
        quantity: @senior_count,
        total_price: unit_price * @senior_count,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date.to_s,
        senior_count: @senior_count,
        duration: @duration,
        tour_product_id: @tour_product&.id
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date'])
      @senior_count = data['senior_count']
      @duration = data['duration']
      
      @tour_product = TourGroupProduct.find(data['tour_product_id']) if data['tour_product_id']
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @duration, @duration)
        .to_a
    end
  end
end
