# frozen_string_literal: true

require_relative '../base_validator'

# V244: 预订直飞航班（不转机）
#
# 任务描述:
#   用户需要预订直飞航班（不转机）
#
# 评分标准:
#   - 创建了航班订单 (20%)
#   - 航线正确（深圳→北京） (15%)
#   - 航班为直飞（无转机） (30%)
#   - 出发日期正确（后天） (15%)
#   - 乘客信息正确 (10%)
#   - 订单状态有效 (10%)
module V201V250
  class V244BookDirectFlightValidator < BaseValidator
    self.validator_id = 'v244_book_direct_flight_validator'
    self.task_id = '9ff95aff-0f0f-0f2f-2f3f-1f4a5b6c7d8f'
    self.title = '给张三预订直飞航班（后天去北京，不转机）'
    self.description = '张三后天要从深圳去北京参加重要会议，时间紧张，需要预订直飞航班避免转机延误'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @destination_city = '北京'
      @flight_date = Date.current + 2.days
      
      # 查询demo_user乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找直飞航班（is_direct=true或stops=0）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("is_direct = ? OR stops = 0", true).to_a
      
      raise "未找到直飞航班" if @available_flights.empty?
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}（后天）从#{@departure_city}到#{@destination_city}的直飞航班（不转机）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          flight_type: '直飞',
          purpose: '避免转机'
        },
        hint: "选择直飞航班，不需要转机。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到航班订单"
        @flight_booking = all_bookings.first
      end
      
      return if @flight_booking.nil?
      
      add_assertion "航线正确（#{@departure_city}→#{@destination_city}）", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}, 实际: #{flight.departure_city}"
        expect(flight.destination_city).to eq(@destination_city),
          "目的地城市错误。期望: #{@destination_city}, 实际: #{flight.destination_city}"
      end
      
      add_assertion "航班为直飞（无转机）", weight: 30 do
        flight = @flight_booking.flight
        is_direct = flight.is_direct || (flight.respond_to?(:stops) && flight.stops == 0)
        
        expect(is_direct).to eq(true),
          "航班不是直飞。航班号: #{flight.flight_number}, 是否直飞: #{flight.is_direct}, 转机次数: #{flight.respond_to?(:stops) ? flight.stops : '未知'}"
      end
      
      add_assertion "出发日期正确（#{@flight_date}，后天）", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.flight_date).to eq(@flight_date),
          "出发日期错误。期望: #{@flight_date}（后天）, 实际: #{flight.flight_date}"
      end
      
      add_assertion "乘客信息正确（张三）", weight: 10 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@flight_booking.passenger_id_number}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@flight_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择第一个直飞航班
      flight = @available_flights.first
      
      Booking.create!(
        user: user,
        flight: flight,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
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
        destination_city: @destination_city,
        flight_date: @flight_date.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).where("is_direct = ? OR stops = 0", true).to_a
    end
  end
end
