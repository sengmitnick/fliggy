# frozen_string_literal: true

require_relative '../base_validator'

# V261: 预订境外游+国际旅游综合保险
#
# 任务描述:
#   用户需要预订境外游并购买国际旅游综合保险（含医疗、意外、行李等）
#
# 评分标准:
#   - 创建了跟团游或门票订单 (30%)
#   - 创建了保险订单 (25%)
#   - 保险类型正确（境外旅游保险）(25%)
#   - 保险保障天数正确 (10%)
#   - 订单状态有效 (10%)
module V251V300
  class V261BookInternationalTravelWithInsuranceValidator < BaseValidator
    self.validator_id = 'v261_book_international_travel_with_insurance_validator'
    self.task_id = 'c8f11a6e-535a-4800-940e-df5c32cadd81'
    self.title = '预订境外游+国际旅游综合保险'
    self.description = '用户需要预订境外游并购买国际旅游综合保险（含医疗、意外、行李等）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '泰国'
      @travel_date = Date.current + 15.days
      @duration = 5
      @traveler_count = 2
      
      # 查找境外游产品
      @tour_product = TourGroupProduct
        .where("destination LIKE ?", "%#{@destination}%")
        .where(data_version: 0)
        .where('duration >= ? AND duration <= ?', @duration - 1, @duration + 1)
        .first
      
      # 如果没有找到，使用任意境外游产品
      @tour_product ||= TourGroupProduct
        .where(data_version: 0)
        .where('duration >= ? AND duration <= ?', @duration - 1, @duration + 1)
        .first
      
      raise "未找到适合的境外游产品" unless @tour_product
      
      # 查找境外保险产品
      @available_insurances = InsuranceProduct
        .where(product_type: 'international', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @duration, @duration)
        .to_a
      
      raise "未找到适合#{@duration}天的境外保险产品" if @available_insurances.empty?
      
      {
        task: "请预订#{@destination}境外游（#{@travel_date.strftime('%Y年%m月%d日')}出发，#{@duration}天，#{@traveler_count}人），并购买国际旅游综合保险（包含医疗、意外、行李等保障）。",
        requirements: {
          destination: @destination,
          travel_date: @travel_date,
          duration: @duration,
          traveler_count: @traveler_count,
          insurance_type: '境外旅游保险',
          insurance_coverage: '综合保障（医疗+意外+行李）'
        },
        hint: "境外游必须购买境外旅游保险，应包含境外医疗、意外伤害和行李丢失等保障。"
      }
    end
    
    def verify
      add_assertion "创建了境外游订单", weight: 30 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product)
          .where(data_version: @data_version)
          .to_a
        
        @tour_booking = all_bookings.first
        expect(@tour_booking).not_to be_nil, "未找到境外游订单"
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
      
      add_assertion "保险类型正确（境外旅游保险）", weight: 25 do
        product_type = @insurance_order.insurance_product.product_type
        expect(product_type).to eq('international'),
          "保险类型错误。境外游必须购买境外保险。期望: international，实际: #{product_type}"
      end
      
      add_assertion "保险保障天数正确", weight: 10 do
        insurance_days = @insurance_order.days
        tour_duration = @tour_booking.tour_group_product.duration
        
        expect(insurance_days).to be >= tour_duration,
          "保险天数不足。旅游天数: #{tour_duration}天，保险天数: #{insurance_days}天"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@tour_booking.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@insurance_order.status).to be_in(['pending', 'paid'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建境外游订单
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
        adult_count: @traveler_count,
        child_count: 0,
        contact_name: user.name,
        contact_phone: '13800138000',
        insurance_type: 'none',
        total_price: @tour_product.price * @traveler_count,
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
        destination_type: 'international',
        insured_persons: ['张三', '李四'],
        unit_price: unit_price,
        quantity: @traveler_count,
        total_price: unit_price * @traveler_count,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date.to_s,
        duration: @duration,
        traveler_count: @traveler_count,
        tour_product_id: @tour_product&.id
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date'])
      @duration = data['duration']
      @traveler_count = data['traveler_count']
      
      @tour_product = TourGroupProduct.find(data['tour_product_id']) if data['tour_product_id']
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'international', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @duration, @duration)
        .to_a
    end
  end
end
