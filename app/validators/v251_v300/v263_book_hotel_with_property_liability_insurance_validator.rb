# frozen_string_literal: true

require_relative '../base_validator'

# V263: 预订酒店+财产保险+责任保险
#
# 任务描述:
#   用户需要预订酒店并购买财产和责任综合保险
#
# 评分标准:
#   - 创建了酒店订单 (35%)
#   - 创建了保险订单 (30%)
#   - 保险类型正确（境内旅游保险）(20%)
#   - 订单状态有效 (15%)
module V251V300
  class V263BookHotelWithPropertyLiabilityInsuranceValidator < BaseValidator
    self.validator_id = 'v263_book_hotel_with_property_liability_insurance_validator'
    self.task_id = 'f257a001-0001-4001-8001-000000000263'
    self.title = '预订酒店+财产保险+责任保险'
    self.description = '用户需要预订酒店并购买财产和责任综合保险'
    self.timeout_seconds = 300
    
    def prepare
      @city = '深圳'
      @check_in_date = Date.today + 1.day
      @check_out_date = @check_in_date + 3.days
      @nights = (@check_out_date - @check_in_date).to_i
      
      # 查找酒店
      @hotel = Hotel
        .where(city: @city, data_version: 0)
        .where('price >= ?', 300)  # 选择较好的酒店
        .first
      
      raise "未找到#{@city}的酒店" unless @hotel
      
      # 查找保险产品
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @nights, @nights)
        .to_a
      
      raise "未找到适合#{@nights}天的保险产品" if @available_insurances.empty?
      
      {
        task: "请预订#{@city}酒店（#{@check_in_date.strftime('%Y年%m月%d日')}入住，住#{@nights}晚），并购买财产保险和责任保险。",
        requirements: {
          city: @city,
          check_in_date: @check_in_date,
          nights: @nights,
          insurance_type: '旅游保险',
          insurance_coverage: '财产+责任'
        },
        hint: "住宿期间建议购买旅游保险，保障个人财产和责任风险。"
      }
    end
    
    def verify
      add_assertion "创建了酒店订单", weight: 35 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .to_a
        
        @hotel_booking = all_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "创建了保险订单", weight: 30 do
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
      
      add_assertion "订单状态有效", weight: 15 do
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@insurance_order.status).to be_in(['pending', 'paid'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建酒店订单
      room = @hotel.hotel_rooms.where(data_version: 0).first
      
      hotel_booking = HotelBooking.create!(
        user: user,
        hotel: @hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        room_count: 1,
        total_price: room.price * @nights,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
      
      # 2. 创建保险订单
      insurance_product = @available_insurances.first
      start_date = @check_in_date
      end_date = @check_out_date - 1.day
      unit_price = insurance_product.price_per_day * @nights
      
      InsuranceOrder.create!(
        user: user,
        insurance_product: insurance_product,
        source: 'standalone',
        related_booking_type: 'HotelBooking',
        related_booking_id: hotel_booking.id,
        start_date: start_date,
        end_date: end_date,
        days: @nights,
        destination: @city,
        destination_type: 'domestic',
        insured_persons: [user.name],
        unit_price: unit_price,
        quantity: 1,
        total_price: unit_price,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        hotel_id: @hotel&.id
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights']
      
      @hotel = Hotel.find(data['hotel_id']) if data['hotel_id']
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'domestic', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', @nights, @nights)
        .to_a
    end
  end
end
