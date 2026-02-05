# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例289: 预订孕妇出行套餐
#
# 任务描述:
#   用户预订孕妇友好的舒适座位+医疗保障服务
#
# 评分标准:
#   - 创建航班预订 (30%)
#   - 创建医疗保险 (35%)
#   - 出发日期正确 (20%)
#   - 订单状态正确 (15%)
module V251V300
  class V289BookPregnancyTravelPackageValidator < BaseValidator
    self.validator_id = 'v289_book_pregnancy_travel_package_validator'
    self.task_id = 'd4278542-8379-49b9-8095-63846c0c97ab'
    self.title = '预订孕妇出行套餐'
    self.description = '用户预订孕妇友好的舒适座位+医疗保障服务'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @destination_city = '三亚'
      @departure_date = Date.current + 5.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 3000
        user.update!(balance: 5000)
      end
      
      {
        task: "请预订从#{@departure_city}到#{@destination_city}的孕妇友好航班，#{@departure_date.strftime('%Y年%-m月%-d日')}出发，需要舒适座位和医疗保障服务",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        hint: "预订舒适航班并购买孕妇专用医疗保险"
      }
    end
    
    def verify
      add_assertion "创建了航班预订", weight: 50 do
        @booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@booking).not_to be_nil, "未找到从#{@departure_city}到#{@destination_city}的航班预订"
      end
      
      add_assertion "创建了医疗保险", weight: 35 do
        @insurance = InsuranceOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@insurance).not_to be_nil, "未找到医疗保险订单"
      end
      
      return unless @booking
      
      add_assertion "订单状态正确", weight: 15 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@booking.status),
          "航班订单状态错误: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订航班
      flight = Flight.where(
        departure_city: @departure_city, 
        destination_city: @destination_city, 
        data_version: 0
      ).first!
      
      Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: user.name || '张三',
        contact_phone: user.phone || '13800138000',
        passenger_id_number: '440300199001011234',
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
        insured_persons: [{ name: user.name || '张三', id_number: '440300199001011234' }],
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
        departure_date: @departure_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
    end
  end
end
