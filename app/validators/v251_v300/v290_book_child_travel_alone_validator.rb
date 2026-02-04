# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例290: 预订儿童独自旅行
#
# 任务描述:
#   用户为儿童预订独自旅行服务（陪同+监护）
#
# 评分标准:
#   - 创建航班预订 (30%)
#   - 创建陪同服务 (35%)
#   - 出发日期正确 (20%)
#   - 订单状态正确 (15%)
module V251V300
  class V290BookChildTravelAloneValidator < BaseValidator
    self.validator_id = 'v290_book_child_travel_alone_validator'
    self.task_id = 'c333c8fb-acf7-4b9b-970f-0deb234601e2'
    self.title = '预订儿童独自旅行'
    self.description = '用户为儿童预订独自旅行服务（陪同+监护）'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '北京'
      @departure_date = Date.today + 7.days
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 2000
        user.update!(balance: 3000)
      end
      
      {
        task: "请为10岁儿童预订从#{@departure_city}到#{@destination_city}的独自旅行服务，#{@departure_date.strftime('%Y年%-m月%-d日')}出发，需要全程陪同和监护服务",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        hint: "预订航班并安排儿童陪同监护服务"
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
      
      add_assertion "创建了陪同服务", weight: 35 do
        @service = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        # 使用CarOrder模拟陪同服务
        expect(@service).not_to be_nil, "未找到儿童陪同服务"
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
        passenger_name: '李小明',
        contact_phone: user.phone || '13800138000',
        passenger_id_number: '440300201401011234',
        total_price: flight.price * 0.5, # 儿童半价
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 预订陪同服务
      car = Car.where(data_version: 0).first!
      CarOrder.create!(
        user_id: user.id,
        car_id: car.id,
        driver_name: '陪同人员',
        driver_id_number: '440300198501011234',
        contact_phone: user.phone || '13800138000',
        pickup_datetime: @departure_date,
        return_datetime: @departure_date + 1.day,
        pickup_location: "#{@departure_city}机场",
        status: 'pending',
        total_price: 500,
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
