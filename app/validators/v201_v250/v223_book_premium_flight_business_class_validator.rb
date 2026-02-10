# frozen_string_literal: true

require_relative '../base_validator'

# V223: 预订商务舱航班（价格≥2000元）
#
# 任务描述:
#   用户需要预订商务舱航班，价格≥2000元（高端出行）
#
# 评分标准:
#   - 创建了航班订单 (25%)
#   - 航班价格≥2000元 (55%)
#   - 航班路线正确 (15%)
#   - 订单状态有效 (5%)
module V201V250
  class V223BookPremiumFlightBusinessClassValidator < BaseValidator
    self.validator_id = 'v223_book_premium_flight_business_class_validator'
    self.task_id = '0ff021fe-1f1f-1f3f-3f4f-2f5a6b7c8d9f'
    self.title = '给张三预订商务舱航班（价格≥2000元）'
    self.description = '张三需要7天后从上海飞往纽约进行商务洽谈，希望预订商务舱航班，预算至少2000元起'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @arrival_city = '纽约'
      @flight_date = Date.current + 7.days
      @min_price = 2000
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_user.passenger_name,
        id_number: demo_user.passenger_id_number,
        phone: demo_user.passenger_phone
      )
      
      # 查找商务舱/高价航班
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        data_version: 0
      ).to_a.select { |f| f.price >= @min_price }
      
      raise "未找到价格≥#{@min_price}元的高端航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@arrival_city}的高端商务舱航班，价格要求≥#{@min_price}元。",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          flight_date: @flight_date,
          min_price: "≥#{@min_price}元",
          purpose: '高端商务出行'
        },
        hint: "选择价格≥#{@min_price}元的高端航班，服务品质优先。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 25 do
        @booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .first
        
        expect(@booking).not_to be_nil, "未找到从#{@departure_city}到#{@arrival_city}的航班订单"
      end
      
      return if @booking.nil?
      
      add_assertion "航班价格≥#{@min_price}元", weight: 55 do
        price = @booking.flight.price
        expect(price).to be >= @min_price,
          "航班价格过低。期望: ≥#{@min_price}元, 实际: #{price}元"
      end
      
      add_assertion "航班路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@booking.flight.departure_city).to eq(@departure_city)
        expect(@booking.flight.destination_city).to eq(@arrival_city)
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择价格适中且服务好的高端航班
      flight = @available_flights.min_by(&:price)
      
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        flight_date: @flight_date.to_s,
        min_price: @min_price
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @flight_date = Date.parse(data['flight_date'])
      @min_price = data['min_price']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @arrival_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a.select { |f| f.price >= @min_price }
    end
  end
end
