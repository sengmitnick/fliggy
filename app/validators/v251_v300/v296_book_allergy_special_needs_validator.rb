# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例296: 给张三预订4天后深圳酒店（配备健身房+购买3天医疗保险，住3晚）
#
# 任务描述:
#   张三需要预订4天后入住深圳的酒店（住3晚），要求酒店配备健身房设施方便锻炼身体，
#   并为此次出行购买3天医疗保险（保险期限与入住时长一致）。
#   Agent需要创建酒店订单并购买医疗保险产品。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、电话作为联系人）
#   2. 筛选深圳配备健身房的酒店（facilities包含"健身房"或"健身中心"或"gym"）
#   3. 优先选择评分最高的酒店
#   4. 创建酒店订单（4天后入住，住3晚）
#   5. 查询可用的医疗保险产品
#   6. 创建医疗保险订单（被保险人为张三，保险期限3天，与入住时长一致）
#
# 复杂度分析（7个关键点）：
#   1. 需要理解健身需求场景，选择配备健身房的酒店
#   2. 需要同时创建酒店订单和医疗保险订单（两个独立订单）
#   3. 需要在配备健身房的酒店中选择最优选项（评分最高）
#   4. 需要确保保险期限与酒店入住时长一致（都是3天）
#   5. 需要验证被保险人信息完整性（姓名、身份证号匹配张三）
#   6. 需要验证保险天数正确（days=3，与住3晚对应）
#   7. 需要使用真实存在的保险产品（data_version: 0）
#   ❌ 不能选择不提供健身房的酒店，必须严格满足健身需求
#
# 评分标准（8项，总计100分）：
#   1. 创建了酒店预订（20分）
#   2. 酒店在深圳且配备健身房（15分）- 核心业务逻辑
#   3. 创建了医疗保险订单（20分）
#   4. 保险天数正确（3天）（10分）- 核心业务逻辑
#   5. 入住日期正确（4天后，住3晚）（10分）
#   6. 入住人信息正确（张三）（15分）
#   7. 被保险人信息正确（张三）（5分）
#   8. 订单状态正确（5分）
#
# 使用方法:
#   rake validator:simulate_single[v296]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
module V251V300
  class V296BookAllergySpecialNeedsValidator < BaseValidator
    self.validator_id = 'v296_book_allergy_special_needs_validator'
    self.task_id = 'af3f1d29-bc35-4308-9368-1d4c82e27868'
    self.title = '给张三预订4天后深圳酒店（配备健身房+购买3天医疗保险，住3晚）'
    self.description = '给张三预订4天后入住深圳的酒店（住3晚），酒店需要配备健身房方便锻炼，并为此次出行购买3天医疗保险'
    self.timeout_seconds = 300
    
    def prepare
      @city = '深圳'
      @check_in_date = Date.current + 4.days
      @check_out_date = @check_in_date + 3.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 2000
        user.update!(balance: 3000)
      end
      
      # Pre-query passenger info
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_name = @zhangsan.name
      @expected_guest_phone = @zhangsan.phone
      @expected_insured_name = @zhangsan.name
      @expected_insured_id_number = @zhangsan.id_number
      
      {
        task: "请预订#{@city}的酒店，我想锻炼身体，#{@check_in_date.strftime('%Y年%-m月%-d日')}入住，住#{(@check_out_date - @check_in_date).to_i}晚，需要健身房和医疗保险",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        hint: "选择有健身房的酒店，并购买医疗保险"
      }
    end
    
    def verify
      add_assertion "创建了酒店预订", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店预订"
      end
      
      return unless @hotel_booking
      
      add_assertion "酒店配备健身房", weight: 15 do
        hotel = @hotel_booking.hotel
        has_gym = hotel.facilities.to_s.match?(/健身房|健身中心|健身|gym/i)
        expect(has_gym).to be_truthy,
          "酒店未配备健身房。当前设施: #{hotel.facilities}"
      end
      
      add_assertion "创建了医疗保险", weight: 20 do
        @insurance = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@insurance).not_to be_nil, "未找到医疗保险订单"
      end
      
      return unless @insurance
      
      add_assertion "保险天数正确（3天）", weight: 10 do
        expected_days = (@check_out_date - @check_in_date).to_i
        expect(@insurance.days).to eq(expected_days),
          "保险天数错误。期望: #{expected_days}天（住#{expected_days}晚），实际: #{@insurance.days}天"
      end
      
      add_assertion "入住日期正确", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "入住人信息正确（张三）", weight: 15 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_guest_phone),
          "入住人电话错误。期望: #{@expected_guest_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "被保险人信息正确（张三）", weight: 5 do
        return unless @insurance
        insured = @insurance.insured_persons.first
        expect(insured['name']).to eq(@expected_insured_name),
          "被保险人姓名错误。期望: #{@expected_insured_name}, 实际: #{insured['name']}"
        expect(insured['id_number']).to eq(@expected_insured_id_number),
          "被保险人身份证错误。期望: #{@expected_insured_id_number}, 实际: #{insured['id_number']}"
      end
      
      add_assertion "订单状态正确", weight: 5 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订有健身房的酒店
      hotels_with_gym = Hotel
        .where(city: @city, data_version: 0)
        .select { |h| h.facilities.to_s.match?(/健身房|健身中心|健身|gym/i) }
      
      raise "未找到有健身房的#{@city}酒店" if hotels_with_gym.empty?
      
      hotel = hotels_with_gym.max_by(&:rating)
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @zhangsan.name,
        guest_phone: @zhangsan.phone,
        payment_method: '花呗',
        total_price: hotel.price * (@check_out_date - @check_in_date).to_i,
        status: 'pending',
        data_version: @data_version
      )
      
      # 2. 购买医疗保险
      insurance_product = InsuranceProduct.where(data_version: 0).first!
      insurance_days = (@check_out_date - @check_in_date).to_i
      InsuranceOrder.create!(
        user_id: user.id,
        insurance_product_id: insurance_product.id,
        start_date: @check_in_date,
        end_date: @check_out_date - 1.day,  # 保险结束日期不包含退房当天
        days: insurance_days,
        insured_persons: [{ name: @zhangsan.name, id_number: @zhangsan.id_number }],
        unit_price: insurance_product.price_per_day,
        quantity: 1,
        total_price: insurance_product.price_per_day * insurance_days,
        status: 'paid',
        source: 'standalone',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        expected_guest_name: @expected_guest_name,
        expected_guest_phone: @expected_guest_phone,
        expected_insured_name: @expected_insured_name,
        expected_insured_id_number: @expected_insured_id_number
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @expected_guest_name = data['expected_guest_name']
      @expected_guest_phone = data['expected_guest_phone']
      @expected_insured_name = data['expected_insured_name']
      @expected_insured_id_number = data['expected_insured_id_number']
    end
  end
end
