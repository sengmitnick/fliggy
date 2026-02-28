# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例289: 给王芳预订孕妇出行套餐
#
# 任务描述:
#   给王芳（孕妇）预订从北京到三亚的孕妇友好的舒适座位+医疗保障服务
#
# 评分标准:
#   - 创建航班预订 (20%)
#   - 乘机人信息正确（王芳） (15%)
#   - 航班出发日期正确 (10%)
#   - 创建医疗保险 (20%)
#   - 保险被保人信息正确（王芳） (15%)
#   - 保险起止日期正确 (10%)
#   - 订单状态正确 (10%)
module V251V300
  class V289BookPregnancyTravelPackageValidator < BaseValidator
    self.validator_id = 'v289_book_pregnancy_travel_package_validator'
    self.task_id = 'd4278542-8379-49b9-8095-63846c0c97ab'
    self.title = '给王芳预订孕妇出行套餐'
    self.description = '给王芳（孕妇）预订从北京到三亚的孕妇友好的舒适座位+医疗保障服务'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '三亚'
      @departure_date = Date.current + 5.days
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_passenger_name = @wangfang.name
      @expected_contact_phone = @wangfang.phone
      
      if user.balance < 3000
        user.update!(balance: 5000)
      end
      
      {
        task: "请给王芳（孕妇）预订从#{@departure_city}到#{@destination_city}的孕妇友好航班，#{@departure_date.strftime('%Y年%-m月%-d日')}出发，需要舒适座位和医疗保障服务",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        hint: "预订舒适航班并购买孕妇专用医疗保险"
      }
    end
    
    def verify
      add_assertion "创建了航班预订", weight: 20 do
        @booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@booking).not_to be_nil, "未找到从#{@departure_city}到#{@destination_city}的航班预订"
      end
      
      return unless @booking
      
      add_assertion "乘机人信息正确（王芳）", weight: 15 do
        expect(@booking.passenger_name).to eq(@expected_passenger_name),
          "乘机人姓名错误。期望: #{@expected_passenger_name}（王芳），实际: #{@booking.passenger_name}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "乘机人联系电话错误。期望: #{@expected_contact_phone}，实际: #{@booking.contact_phone}"
      end
      
      add_assertion "航班出发日期正确", weight: 10 do
        flight = @booking.flight
        booking_date = flight.departure_time.to_date
        expect(booking_date).to eq(@departure_date),
          "航班出发日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（5天后），实际: #{booking_date.strftime('%Y-%m-%d')}"
      end
      
      add_assertion "创建了医疗保险", weight: 20 do
        @insurance = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@insurance).not_to be_nil, "未找到医疗保险订单"
      end
      
      return unless @insurance
      
      add_assertion "保险被保人信息正确（王芳）", weight: 15 do
        insured_persons = @insurance.insured_persons
        expect(insured_persons).to be_present, "被保人信息为空"
        
        first_person = insured_persons.is_a?(Array) ? insured_persons.first : insured_persons
        person_name = first_person.is_a?(Hash) ? first_person['name'] || first_person[:name] : first_person.name
        
        expect(person_name).to eq(@expected_passenger_name),
          "被保人姓名错误。期望: #{@expected_passenger_name}（王芳），实际: #{person_name}"
      end
      
      add_assertion "保险起止日期正确", weight: 10 do
        expect(@insurance.start_date).to eq(@departure_date),
          "保险开始日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（5天后），实际: #{@insurance.start_date.strftime('%Y-%m-%d')}"
        
        expected_end_date = @departure_date + 3.days
        expect(@insurance.end_date).to eq(expected_end_date),
          "保险结束日期错误。期望: #{expected_end_date.strftime('%Y-%m-%d')}（8天后），实际: #{@insurance.end_date.strftime('%Y-%m-%d')}"
      end
      
      add_assertion "订单状态正确", weight: 10 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@booking.status),
          "航班订单状态错误: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 1. 预订航班（选择指定日期的航班）
      flight = Flight
        .where(departure_city: @departure_city, destination_city: @destination_city, data_version: 0)
        .by_date(@departure_date)
        .first!
      
      Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: wangfang.name,
        contact_phone: wangfang.phone,
        passenger_id_number: wangfang.id_number,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 购买医疗保险
      insurance_product = InsuranceProduct.where(data_version: 0).first!
      InsuranceOrder.create!(
        user_id: user.id,
        insurance_product_id: insurance_product.id,
        start_date: @departure_date,
        end_date: @departure_date + 3.days,
        days: 3,
        insured_persons: [{ name: wangfang.name, id_number: wangfang.id_number }],
        unit_price: insurance_product.price_per_day,
        quantity: 1,
        total_price: insurance_product.price_per_day * 3,
        status: 'paid',
        source: 'standalone',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date&.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
