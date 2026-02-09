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
    self.title = '给张三和李四预订泰国5天游（15天后出发）+国际旅游综合保险'
    self.description = '帮张三和李四预订泰国5天境外游（15天后出发，2人），并购买国际旅游综合保险（含医疗、意外、行李等）'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '泰国'
      @travel_date = Date.current + 15.days
      @duration = 5
      @traveler_count = 2
      
      # 查询用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_insured_names = [@zhangsan.name, @lisi.name]
      @expected_contact_phone = @zhangsan.phone
      
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
        task: "请帮张三和李四预订#{@destination}境外游（#{@travel_date.strftime('%Y年%m月%d日')}出发，#{@duration}天，2人），并购买国际旅游综合保险（包含医疗、意外、行李等保障）。",
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
      
      add_assertion "被保险人信息正确（张三、李四）", weight: 10 do
        insured_persons = @insurance_order.insured_persons || []
        expect(insured_persons.size).to eq(2), "被保险人数量错误。期望: 2人，实际: #{insured_persons.size}人"
        
        actual_names = insured_persons.map { |p| p.is_a?(Hash) ? p['name'] : p }.compact
        expect(actual_names).to match_array(@expected_insured_names),
          "被保险人姓名错误。期望: #{@expected_insured_names.join('、')}，实际: #{actual_names.join('、')}"
      end
      
      add_assertion "保险保障天数正确", weight: 5 do
        insurance_days = @insurance_order.days
        tour_duration = @tour_booking.tour_group_product.duration
        
        expect(insurance_days).to be >= tour_duration,
          "保险天数不足。旅游天数: #{tour_duration}天，保险天数: #{insurance_days}天"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@tour_booking.status).to be_in(['pending', 'paid', 'confirmed'])
        expect(@insurance_order.status).to be_in(['pending', 'paid'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建境外游订单
      tour_package = @tour_product.tour_packages.where(data_version: 0).first!
      
      tour_booking = TourGroupBooking.create!(
        user: user,
        tour_group_product: @tour_product,
        tour_package: tour_package,
        travel_date: @travel_date,
        adult_count: @traveler_count,
        child_count: 0,
        contact_name: @zhangsan.name,
        contact_phone: @expected_contact_phone,
        insurance_type: 'none',
        total_price: @tour_product.price * @traveler_count,
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
        destination_type: 'international',
        insured_persons: insured_persons_data,
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
        tour_product_id: @tour_product&.id,
        zhangsan_id: @zhangsan&.id,
        lisi_id: @lisi&.id
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date'])
      @duration = data['duration']
      @traveler_count = data['traveler_count']
      
      @tour_product = TourGroupProduct.find(data['tour_product_id']) if data['tour_product_id']
      
      # 恢复乘客信息
      if data['zhangsan_id'] && data['lisi_id']
        @zhangsan = Passenger.find(data['zhangsan_id'])
        @lisi = Passenger.find(data['lisi_id'])
        @expected_insured_names = [@zhangsan.name, @lisi.name]
        @expected_contact_phone = @zhangsan.phone
      end
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'international', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @duration, @duration)
        .to_a
    end
  end
end
