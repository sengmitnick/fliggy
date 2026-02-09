# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例290: 给张三和小明预订亲子游
#
# 任务描述:
#   给张三和小明（10岁儿童）预订从上海到北京的亲子游
#
# 评分标准:
#   - 创建成人航班预订 (25%)
#   - 成人乘机人信息正确（张三） (15%)
#   - 创建儿童航班预订 (25%)
#   - 儿童乘机人信息正确（小明） (15%)
#   - 航班出发日期正确 (10%)
#   - 订单状态正确 (10%)
module V251V300
  class V290BookChildTravelAloneValidator < BaseValidator
    self.validator_id = 'v290_book_child_travel_alone_validator'
    self.task_id = 'c333c8fb-acf7-4b9b-970f-0deb234601e2'
    self.title = '给张三和小明预订亲子游'
    self.description = '给张三和小明（10岁儿童）预订从上海到北京的亲子游'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @destination_city = '北京'
      @departure_date = Date.current + 7.days
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      @expected_adult_name = @zhangsan.name
      @expected_adult_phone = @zhangsan.phone
      @expected_child_name = @xiaoming.name
      @expected_child_phone = @xiaoming.phone
      
      if user.balance < 2000
        user.update!(balance: 3000)
      end
      
      {
        task: "请为张三和小明（10岁儿童）预订从#{@departure_city}到#{@destination_city}的亲子游航班，#{@departure_date.strftime('%Y年%-m月%-d日')}出发，需要预订1个成人票和1个儿童票",
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date.to_s,
        hint: "分别预订成人和儿童航班机票"
      }
    end
    
    def verify
      add_assertion "创建了成人航班预订", weight: 25 do
        all_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @adult_booking = all_bookings.find { |b| b.passenger_name == @expected_adult_name }
        expect(@adult_booking).not_to be_nil, "未找到成人（张三）的航班预订"
      end
      
      add_assertion "成人乘机人信息正确（张三）", weight: 15 do
        expect(@adult_booking.passenger_name).to eq(@expected_adult_name),
          "成人乘机人姓名错误。期望: #{@expected_adult_name}（张三），实际: #{@adult_booking.passenger_name}"
        expect(@adult_booking.contact_phone).to eq(@expected_adult_phone),
          "成人联系电话错误。期望: #{@expected_adult_phone}，实际: #{@adult_booking.contact_phone}"
      end
      
      add_assertion "创建了儿童航班预订", weight: 25 do
        all_bookings = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @child_booking = all_bookings.find { |b| b.passenger_name == @expected_child_name }
        expect(@child_booking).not_to be_nil, "未找到儿童（小明）的航班预订"
      end
      
      add_assertion "儿童乘机人信息正确（小明）", weight: 15 do
        expect(@child_booking.passenger_name).to eq(@expected_child_name),
          "儿童乘机人姓名错误。期望: #{@expected_child_name}（小明），实际: #{@child_booking.passenger_name}"
        expect(@child_booking.contact_phone).to eq(@expected_child_phone),
          "儿童联系电话错误。期望: #{@expected_child_phone}，实际: #{@child_booking.contact_phone}"
      end
      
      return unless @adult_booking && @child_booking
      
      add_assertion "航班出发日期正确", weight: 10 do
        adult_date = @adult_booking.flight.departure_time.to_date
        expect(adult_date).to eq(@departure_date),
          "成人航班出发日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（7天后），实际: #{adult_date.strftime('%Y-%m-%d')}"
        
        child_date = @child_booking.flight.departure_time.to_date
        expect(child_date).to eq(@departure_date),
          "儿童航班出发日期错误。期望: #{@departure_date.strftime('%Y-%m-%d')}（7天后），实际: #{child_date.strftime('%Y-%m-%d')}"
      end
      
      add_assertion "订单状态正确", weight: 10 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@adult_booking.status),
          "成人航班订单状态错误: #{@adult_booking.status}"
        expect(valid_statuses).to include(@child_booking.status),
          "儿童航班订单状态错误: #{@child_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      
      # 选择指定日期的航班
      flight = Flight
        .where(departure_city: @departure_city, destination_city: @destination_city, data_version: 0)
        .by_date(@departure_date)
        .first!
      
      # 1. 预订成人航班
      Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: zhangsan.name,
        contact_phone: zhangsan.phone,
        passenger_id_number: zhangsan.id_number,
        total_price: flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 2. 预订儿童航班
      Booking.create!(
        user_id: user.id,
        flight_id: flight.id,
        passenger_name: xiaoming.name,
        contact_phone: xiaoming.phone,
        passenger_id_number: xiaoming.id_number,
        total_price: flight.price * 0.5, # 儿童半价
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        departure_date: @departure_date&.to_s,
        expected_adult_name: @expected_adult_name,
        expected_adult_phone: @expected_adult_phone,
        expected_child_name: @expected_child_name,
        expected_child_phone: @expected_child_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @expected_adult_name = data['expected_adult_name']
      @expected_adult_phone = data['expected_adult_phone']
      @expected_child_name = data['expected_child_name']
      @expected_child_phone = data['expected_child_phone']
    end
  end
end
