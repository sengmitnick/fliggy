# frozen_string_literal: true

require_relative '../base_validator'

# V261: 预订境外游+国际旅游综合保险
#
# 任务描述:
#   用户需要预订境外游并购买国际旅游综合保险（含医疗、意外、行李等）
#
# 评分标准:
#   - 创建了跟团游订单 (20%)
#   - 创建了出行人信息（张三、李四）(15%)
#   - 创建了保险订单 (20%)
#   - 保险类型正确（境外旅游保险）(15%)
#   - 被保险人与出行人一致 (15%)
#   - 保险时间覆盖出行时间 (10%)
#   - 订单状态有效 (5%)
module V251V300
  class V261BookInternationalTravelWithInsuranceValidator < BaseValidator
    self.validator_id = 'v261_book_international_travel_with_insurance_validator'
    self.task_id = 'c8f11a6e-535a-4800-940e-df5c32cadd81'
    self.title = '帮张三和李四预订泰国5天境外游（15天后出发，2人），并购买国际旅游综合保险（含医疗、意外、行李等）'
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
      add_assertion "创建了境外游订单", weight: 20 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .includes(:tour_group_product, :booking_travelers)
          .where(data_version: @data_version)
          .to_a
        
        @tour_booking = all_bookings.first
        expect(@tour_booking).not_to be_nil, "未找到境外游订单"
      end
      
      return if @tour_booking.nil?
      
      add_assertion "创建了出行人信息（张三、李四）", weight: 15 do
        @travelers = @tour_booking.booking_travelers.where(data_version: @data_version).to_a
        
        expect(@travelers.size).to eq(2),
          "出行人数量错误。期望: 2人，实际: #{@travelers.size}人"
        
        traveler_names = @travelers.map(&:traveler_name).sort
        expected_names = @expected_insured_names.sort
        
        expect(traveler_names).to eq(expected_names),
          "出行人姓名错误。期望: #{expected_names.join('、')}，实际: #{traveler_names.join('、')}"
        
        # 验证身份证号
        @travelers.each do |traveler|
          expect(traveler.id_number).not_to be_blank,
            "#{traveler.traveler_name}的身份证号不能为空"
        end
      end
      
      return if @travelers.nil? || @travelers.empty?
      
      add_assertion "创建了保险订单", weight: 20 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险类型正确（境外旅游保险）", weight: 15 do
        product_type = @insurance_order.insurance_product.product_type
        expect(product_type).to eq('international'),
          "保险类型错误。境外游必须购买境外保险。期望: international，实际: #{product_type}"
      end
      
      add_assertion "被保险人与出行人一致（张三、李四）", weight: 15 do
        insured_persons = @insurance_order.insured_persons || []
        expect(insured_persons.size).to eq(2), "被保险人数量错误。期望: 2人，实际: #{insured_persons.size}人"
        
        # 提取被保险人姓名
        actual_insured_names = insured_persons.map { |p| p.is_a?(Hash) ? p['name'] : p }.compact.sort
        
        # 提取出行人姓名
        traveler_names = @travelers.map(&:traveler_name).sort
        
        # 验证被保险人与出行人一致
        expect(actual_insured_names).to eq(traveler_names),
          "被保险人与出行人不一致。出行人: #{traveler_names.join('、')}，被保险人: #{actual_insured_names.join('、')}"
        
        # 验证被保险人身份证号
        insured_persons.each do |person|
          name = person.is_a?(Hash) ? person['name'] : person
          id_number = person.is_a?(Hash) ? person['id_number'] : nil
          
          # 找到对应的出行人
          traveler = @travelers.find { |t| t.traveler_name == name }
          expect(traveler).not_to be_nil, "被保险人#{name}在出行人列表中未找到"
          
          # 验证身份证号一致
          if id_number.present?
            expect(id_number).to eq(traveler.id_number),
              "#{name}的身份证号不一致。出行人: #{traveler.id_number}，被保险人: #{id_number}"
          end
        end
      end
      
      add_assertion "保险时间覆盖出行时间", weight: 10 do
        # 旅游出发日期
        tour_start_date = @tour_booking.travel_date
        tour_duration = @tour_booking.tour_group_product.duration
        tour_end_date = tour_start_date + tour_duration - 1
        
        # 保险起止日期
        insurance_start = @insurance_order.start_date
        insurance_end = @insurance_order.end_date
        insurance_days = @insurance_order.days
        
        # 验证保险天数覆盖旅游天数
        expect(insurance_days).to be >= tour_duration,
          "保险天数不足。旅游天数: #{tour_duration}天，保险天数: #{insurance_days}天"
        
        # 验证保险起始日期不晚于出发日期
        expect(insurance_start).to be <= tour_start_date,
          "保险起始日期晚于出发日期。出发日期: #{tour_start_date}，保险起始日期: #{insurance_start}"
        
        # 验证保险结束日期不早于返程日期
        expect(insurance_end).to be >= tour_end_date,
          "保险结束日期早于返程日期。返程日期: #{tour_end_date}，保险结束日期: #{insurance_end}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@tour_booking.status).to be_in(['pending', 'paid', 'confirmed']),
          "旅游订单状态无效: #{@tour_booking.status}"
        expect(@insurance_order.status).to be_in(['pending', 'paid']),
          "保险订单状态无效: #{@insurance_order.status}"
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
      
      # 2. 创建出行人记录（张三和李四）
      BookingTraveler.create!(
        tour_group_booking: tour_booking,
        traveler_name: @zhangsan.name,
        id_number: @zhangsan.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      BookingTraveler.create!(
        tour_group_booking: tour_booking,
        traveler_name: @lisi.name,
        id_number: @lisi.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      # 3. 创建保险订单（使用与出行人一致的被保险人信息）
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
