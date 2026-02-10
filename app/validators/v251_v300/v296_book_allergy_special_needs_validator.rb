# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例296: 给张三预订深圳酒店（含健身房和医疗保险）
#
# 任务描述:
#   张三需要预订深圳的酒店，要求有健身房设施，并购买医疗保险
#
# 评分标准:
#   - 创建酒店预订 (25%)
#   - 酒店配备健身房 (15%)
#   - 创建医疗保险 (25%)
#   - 入住日期正确 (10%)
#   - 入住人信息正确（张三）(15%)
#   - 被保险人信息正确 (5%)
#   - 订单状态正确 (5%)
module V251V300
  class V296BookAllergySpecialNeedsValidator < BaseValidator
    self.validator_id = 'v296_book_allergy_special_needs_validator'
    self.task_id = 'af3f1d29-bc35-4308-9368-1d4c82e27868'
    self.title = '给张三预订深圳酒店（4天后，需要健身房和医疗保险）'
    self.description = '张三需要订深圳的酒店，想锻炼身体，需要健身房，再买个医疗保险'
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
      add_assertion "创建了酒店预订", weight: 25 do
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
      
      add_assertion "创建了医疗保险", weight: 25 do
        @insurance = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@insurance).not_to be_nil, "未找到医疗保险订单"
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
      InsuranceOrder.create!(
        user_id: user.id,
        insurance_product_id: insurance_product.id,
        start_date: @check_in_date,
        end_date: @check_out_date,
        days: (@check_out_date - @check_in_date).to_i,
        insured_persons: [{ name: @zhangsan.name, id_number: @zhangsan.id_number }],
        unit_price: insurance_product.price_per_day,
        quantity: 1,
        total_price: insurance_product.price_per_day * (@check_out_date - @check_in_date).to_i,
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
