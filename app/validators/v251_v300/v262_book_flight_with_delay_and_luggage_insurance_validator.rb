# frozen_string_literal: true

require_relative '../base_validator'

# V262: 预订航班+延误险+行李险组合
#
# 任务描述:
#   用户需要预订航班并购买延误险和行李险组合保险
#
# 评分标准:
#   - 创建了航班订单 (30%)
#   - 创建了保险订单 (25%)
#   - 保险类型正确（交通意外险或航空保险）(20%)
#   - 保险包含延误保障 (15%)
#   - 订单状态有效 (10%)
module V251V300
  class V262BookFlightWithDelayAndLuggageInsuranceValidator < BaseValidator
    self.validator_id = 'v262_book_flight_with_delay_and_luggage_insurance_validator'
    self.task_id = 'f257a001-0001-4001-8001-000000000262'
    self.title = '预订航班+延误险+行李险组合'
    self.description = '用户需要预订航班并购买延误险和行李险组合保险'
    self.timeout_seconds = 300
    
    def prepare
      @from_city = '北京'
      @to_city = '上海'
      @travel_date = Date.today + 3.days
      
      # 查找航班
      @flight = Flight
        .where(departure_city: @from_city, destination_city: @to_city, data_version: 0)
        .where('departure_time::date = ?', @travel_date)
        .first
      
      raise "未找到#{@from_city}到#{@to_city}的航班" unless @flight
      
      # 查找交通意外险（含航班延误保障）
      @available_insurances = InsuranceProduct
        .where(product_type: 'transport', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', 1, 1)
        .select { |p| p.scenes&.include?('航班延误保障') || p.scenes&.include?('航空保障') }
      
      raise "未找到包含航班延误保障的保险产品" if @available_insurances.empty?
      
      {
        task: "请预订#{@from_city}到#{@to_city}的航班（#{@travel_date.strftime('%Y年%m月%d日')}），并购买延误险+行李险组合保险。",
        requirements: {
          from_city: @from_city,
          to_city: @to_city,
          travel_date: @travel_date,
          insurance_type: '航空保险',
          insurance_coverage: '延误+行李'
        },
        hint: "航班出行建议购买含航班延误保障和行李丢失保障的交通意外险。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 30 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @from_city, destination_city: @to_city })
          .where(data_version: @data_version)
          .to_a
        
        @flight_booking = all_bookings.first
        expect(@flight_booking).not_to be_nil, "未找到#{@from_city}到#{@to_city}的航班订单"
      end
      
      return if @flight_booking.nil?
      
      add_assertion "创建了保险订单", weight: 25 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      add_assertion "保险类型正确（交通意外险或航空保险）", weight: 20 do
        product_type = @insurance_order.insurance_product.product_type
        expect(product_type).to eq('transport'),
          "保险类型错误。航班需购买交通意外险。期望: transport，实际: #{product_type}"
      end
      
      add_assertion "保险包含延误保障", weight: 15 do
        scenes = @insurance_order.insurance_product.scenes || []
        has_delay_coverage = scenes.include?('航班延误保障') || 
                             scenes.include?('航空保障') ||
                             scenes.include?('航班取消保障')
        
        expect(has_delay_coverage).to be_truthy,
          "保险不包含延误保障。保险场景: #{scenes.inspect}，需要包含'航班延误保障'或'航空保障'"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@insurance_order.status).to be_in(['pending', 'paid'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建航班订单
      flight_booking = Booking.create!(
        user: user,
        flight: @flight,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: @flight.price,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      # 2. 创建保险订单
      insurance_product = @available_insurances.first
      start_date = @travel_date
      end_date = @travel_date
      days = 1
      unit_price = insurance_product.price_per_day * days
      
      InsuranceOrder.create!(
        user: user,
        insurance_product: insurance_product,
        source: 'standalone',
        related_booking_type: 'Booking',
        related_booking_id: flight_booking.id,
        start_date: start_date,
        end_date: end_date,
        days: days,
        destination: @to_city,
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
        from_city: @from_city,
        to_city: @to_city,
        travel_date: @travel_date.to_s,
        flight_id: @flight&.id
      }
    end
    
    def restore_from_state(data)
      @from_city = data['from_city']
      @to_city = data['to_city']
      @travel_date = Date.parse(data['travel_date'])
      
      @flight = Flight.find(data['flight_id']) if data['flight_id']
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'transport', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', 1, 1)
        .select { |p| p.scenes&.include?('航班延误保障') || p.scenes&.include?('航空保障') }
    end
  end
end
