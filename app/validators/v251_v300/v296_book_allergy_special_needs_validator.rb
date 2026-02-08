# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例296: 预订过敏体质特殊需求
#
# 任务描述:
#   用户预订过敏体质特殊需求服务
#
# 评分标准:
#   - 创建酒店预订 (40%)
#   - 创建医疗保险 (35%)
#   - 入住日期正确 (15%)
#   - 订单状态正确 (10%)
module V251V300
  class V296BookAllergySpecialNeedsValidator < BaseValidator
    self.validator_id = 'v296_book_allergy_special_needs_validator'
    self.task_id = 'af3f1d29-bc35-4308-9368-1d4c82e27868'
    self.title = '预订过敏体质特殊需求（4天后入住）'
    self.description = '用户预订过敏体质特殊需求服务'
    self.timeout_seconds = 300
    
    def prepare
      @city = '深圳'
      @check_in_date = Date.current + 4.days
      @check_out_date = @check_in_date + 3.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 2000
        user.update!(balance: 3000)
      end
      
      {
        task: "请预订#{@city}的酒店，我对花粉过敏，#{@check_in_date.strftime('%Y年%-m月%-d日')}入住，住#{(@check_out_date - @check_in_date).to_i}晚，需要空气净化器和医疗保险",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        hint: "选择环境友好的酒店，并购买医疗保险"
      }
    end
    
    def verify
      add_assertion "创建了酒店预订", weight: 40 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店预订"
      end
      
      add_assertion "创建了医疗保险", weight: 35 do
        @insurance = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@insurance).not_to be_nil, "未找到医疗保险订单"
      end
      
      return unless @hotel_booking
      
      add_assertion "入住日期正确", weight: 15 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "订单状态正确", weight: 10 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订环境友好酒店
      hotel = Hotel.where(city: @city, data_version: 0)
        .order(rating: :desc)
        .first!
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name || '张三',
        guest_phone: user.phone || '13800138000',
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
        insured_persons: [{ name: user.name || '张三', id_number: '440300199001011234' }],
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
        check_out_date: @check_out_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
    end
  end
end
