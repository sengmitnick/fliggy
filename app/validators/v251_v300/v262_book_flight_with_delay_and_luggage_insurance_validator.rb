# frozen_string_literal: true

require_relative '../base_validator'

# V262: 预订北京到上海航班并购买含延误保障的交通意外险
#
# 任务描述:
#   用户需要预订3天后从北京到上海的航班，并购买交通意外险（必须包含航班延误保障）
#
# 评分标准:
#   - 创建了航班订单 (20分) - 核心评分项
#   - 创建了保险订单 (15分)
#   - 航班日期正确（3天后）(15分)
#   - 用户一致性（航班和保险为同一用户）(10分)
#   - 保险日期与航班日期匹配 (10分)
#   - 保险类型正确（交通意外险）(15分) - 核心评分项
#   - 乘客信息正确（张三）(10分)
#   - 保险被保险人信息正确 (0分)
#   - 保险包含延误保障 (0分)
#   - 订单状态有效 (5分)
module V251V300
  class V262BookFlightWithDelayAndLuggageInsuranceValidator < BaseValidator
    self.validator_id = 'v262_book_flight_with_delay_and_luggage_insurance_validator'
    self.task_id = '440e142a-b196-4ea2-a3db-3a7da7eb9633'
    self.title = '帮张三预订3天后从北京到上海的航班，并购买交通意外险（必须包含航班延误保障）'
    self.description = '帮张三预订3天后从北京到上海的航班，并购买交通意外险（必须包含航班延误保障）'
    self.timeout_seconds = 300
    
    def prepare
      @from_city = '北京'
      @to_city = '上海'
      @travel_date = Date.current + 3.days
      
      # 查询用户和乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @zhangsan.name
      @expected_passenger_id_number = @zhangsan.id_number
      @expected_contact_phone = @zhangsan.phone
      
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
        task: "请帮张三预订#{@from_city}到#{@to_city}的航班（#{@travel_date.strftime('%Y年%m月%d日')}，3天后），并购买含航班延误保障的交通意外险。",
        requirements: {
          from_city: @from_city,
          to_city: @to_city,
          travel_date: @travel_date,
          insurance_type: '交通意外险',
          insurance_coverage: '航班延误保障'
        },
        hint: "航班出行建议购买含航班延误保障的交通意外险。"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单 (20分) - 核心评分项
      add_assertion "创建了航班订单", weight: 20 do
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
      
      # 断言2: 创建了保险订单 (15分)
      add_assertion "创建了保险订单", weight: 15 do
        @insurance_order = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@insurance_order).not_to be_nil, "未找到保险订单"
      end
      
      return if @insurance_order.nil?
      
      # 断言3: 航班日期正确（3天后） (15分)
      add_assertion "航班日期正确（#{@travel_date}，3天后）", weight: 15 do
        flight_date = @flight_booking.flight.departure_time.to_date
        expect(flight_date).to eq(@travel_date),
          "航班日期错误。期望: #{@travel_date}（3天后），实际: #{flight_date}"
      end
      
      # 断言4: 用户一致性（航班和保险为同一用户） (10分)
      add_assertion "用户一致性（航班和保险为同一用户）", weight: 10 do
        flight_user_id = @flight_booking.user_id
        insurance_user_id = @insurance_order.user_id
        
        expect(insurance_user_id).to eq(flight_user_id),
          "用户不一致。航班订单用户ID: #{flight_user_id}，保险订单用户ID: #{insurance_user_id}"
      end
      
      # 断言5: 保险日期与航班日期匹配 (10分)
      add_assertion "保险日期与航班日期匹配", weight: 10 do
        flight_date = @flight_booking.flight.departure_time.to_date
        insurance_start_date = @insurance_order.start_date
        
        expect(insurance_start_date).to eq(flight_date),
          "保险日期与航班日期不匹配。航班日期: #{flight_date}，保险起始日期: #{insurance_start_date}"
      end
      
      # 断言6: 保险类型正确（交通意外险） (15分) - 核心评分项
      add_assertion "保险类型正确（交通意外险）", weight: 15 do
        product_type = @insurance_order.insurance_product.product_type
        expect(product_type).to eq('transport'),
          "保险类型错误。航班需购买交通意外险。期望: transport，实际: #{product_type}"
      end
      
      # 断言7: 乘客信息正确（张三） (10分)
      add_assertion "乘客信息正确（张三）", weight: 10 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}，实际: #{@flight_booking.passenger_name}"
      end
      
      # 断言8: 保险被保险人信息正确 (0分)
      add_assertion "保险被保险人信息正确", weight: 0 do
        insured_persons = @insurance_order.insured_persons || []
        actual_names = insured_persons.map { |p| p.is_a?(Hash) ? p['name'] : p }.compact
        expect(actual_names).to include(@expected_passenger_name),
          "被保险人信息错误。期望包含: #{@expected_passenger_name}，实际: #{actual_names.join('、')}"
      end
      
      # 断言9: 保险包含延误保障 (0分)
      add_assertion "保险包含延误保障", weight: 0 do
        scenes = @insurance_order.insurance_product.scenes || []
        has_delay_coverage = scenes.include?('航班延误保障') || 
                             scenes.include?('航空保障') ||
                             scenes.include?('航班取消保障')
        
        expect(has_delay_coverage).to be_truthy,
          "保险不包含延误保障。保险场景: #{scenes.inspect}，需要包含'航班延误保障'或'航空保障'"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@insurance_order.status).to be_in(['pending', 'paid'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 创建航班订单（使用预查询的乘客信息）
      flight_booking = Booking.create!(
        user: user,
        flight: @flight,
        passenger_name: @expected_passenger_name,
        passenger_id_number: @expected_passenger_id_number,
        contact_phone: @expected_contact_phone,
        total_price: @flight.price,
        status: 'paid',
        accept_terms: true,
        data_version: @data_version
      )
      
      # 2. 创建保险订单（使用预查询的乘客信息）
      insurance_product = @available_insurances.first
      start_date = @travel_date
      end_date = @travel_date
      days = 1
      unit_price = insurance_product.price_per_day * days
      
      insured_persons_data = [{
        name: @zhangsan.name,
        id_number: @zhangsan.id_number
      }]
      
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
        insured_persons: insured_persons_data,
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
        flight_id: @flight&.id,
        zhangsan_id: @zhangsan&.id
      }
    end
    
    def restore_from_state(data)
      @from_city = data['from_city']
      @to_city = data['to_city']
      @travel_date = Date.parse(data['travel_date'])
      
      @flight = Flight.find(data['flight_id']) if data['flight_id']
      
      # 恢复乘客信息
      if data['zhangsan_id']
        @zhangsan = Passenger.find(data['zhangsan_id'])
        @expected_passenger_name = @zhangsan.name
        @expected_passenger_id_number = @zhangsan.id_number
        @expected_contact_phone = @zhangsan.phone
      end
      
      @available_insurances = InsuranceProduct
        .where(product_type: 'transport', data_version: 0)
        .where('min_days <= ? AND max_days >= ?', 1, 1)
        .select { |p| p.scenes&.include?('航班延误保障') || p.scenes&.include?('航空保障') }
    end
  end
end
