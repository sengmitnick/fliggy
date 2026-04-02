# frozen_string_literal: true

require_relative '../base_validator'

# V245: 张三6天后要飞往洛杉矶参加国际会议，需要预订北京→洛杉矶航班
#
# 任务描述:
#   张三6天后要飞往洛杉矶参加国际会议，需要预订从北京到洛杉矶的长途国际航班。
#
# 业务流程:
#   1. 客户咨询：张三表示需要预订6天后从北京飞往洛杉矶的航班，参加重要国际会议
#   2. 查询航班：搜索北京→洛杉矶航线的可用航班，确认航班日期
#   3. 确认信息：核对乘客信息（姓名：张三，身份证号，联系电话）
#   4. 选择航班：选择合适的航班
#   5. 提交订单：填写乘客信息和联系方式，创建航班订单
#   6. 完成支付：确认订单信息，支付机票费用
#
# 复杂度分析:
#   1. 国际航线查询：需要查询跨太平洋长途国际航线，航班数量较少
#   2. 乘客信息验证：需要准确填写国际航班所需的乘客信息（姓名、身份证号）
#   3. 价格验证：需要验证长途国际航班的高票价（通常7000-15000元）
#   4. 日期灵活性：出发日期为6天后，需要在±3天范围内选择合适航班
#
# 评分标准:
#   1. 创建了航班订单 (20%) - 基础操作
#   2. 航线正确（北京→洛杉矶） (15%) - 核心要求
#   3. 出发日期合理（6天后） (15%) - 时间要求
#   4. 机票价格正确 (25%) - 价格验证（长途国际航班高票价）
#   5. 乘客信息正确（张三） (15%) - 信息准确性
#   6. 订单状态有效 (10%) - 订单完整性
module V201V250
  class V245BookWidebodyAircraftValidator < BaseValidator
    self.validator_id = 'v245_book_widebody_aircraft_validator'
    self.task_id = '0ff06bff-1f1f-1f3f-3f4f-2f5a6b7c8d9f'
    self.title = '张三6天后要飞往洛杉矶参加国际会议，需要预订北京→洛杉矶航班'
    self.description = '张三6天后要飞往洛杉矶参加国际会议，需要预订从北京到洛杉矶的长途国际航班'
    self.timeout_seconds = 300
    
    def prepare
      # 设置航线和日期
      @departure_city = '北京'
      @destination_city = '洛杉矶'
      @departure_date = Date.today + 6.days  # 6天后
      
      # 查询demo_user乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三')
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_contact_phone = @passenger.phone
      
      # 查找可用航班（北京→洛杉矶国际航线，±3天范围）
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).where('flight_date BETWEEN ? AND ?', @departure_date - 3.days, @departure_date + 3.days).to_a
      
      raise "未找到可用的#{@departure_city}→#{@destination_city}航班" if @available_flights.empty?
      
      # 使用实际航班日期
      @flight_date = @available_flights.first.flight_date
      
      # 统计信息（方便调试和优化）
      puts "\n=== 北京→洛杉矶航班统计 ==="
      puts "可用航班总数: #{@available_flights.size}个"
      puts "航班列表:"
      @available_flights.each do |f|
        puts "  - #{f.flight_number}: #{f.price}元, 日期: #{f.flight_date}, 机型: #{f.aircraft_type || 'N/A'}"
      end
      puts "价格区间: #{@available_flights.map(&:price).min}-#{@available_flights.map(&:price).max}元"
      puts "\n乘客信息: #{@passenger.name}（#{@passenger.id_number}）"
      puts "出发日期: #{@departure_date}（6天后）"
      puts "==========================\n\n"
      
      {
        task: "请预订从#{@departure_city}到#{@destination_city}的航班，出发日期#{@departure_date}左右（6天后）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          departure_date: @departure_date.to_s,
          passenger_name: '张三',
          purpose: '参加国际会议'
        },
        hint: "这是跨太平洋长途国际航线，飞行时间约13小时。"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单（基础操作）
      add_assertion "创建了航班订单", weight: 20 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到航班订单。请检查是否已创建Booking记录。"
        @flight_booking = all_bookings.first
      end
      
      return if @flight_booking.nil?
      
      # 断言2: 航线正确（北京→洛杉矶）（核心要求）
      add_assertion "航线正确（#{@departure_city}→#{@destination_city}）（国际长途航线）", weight: 15 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city),
          "出发城市错误。期望: #{@departure_city}（跨太平洋航线起点）, 实际: #{flight.departure_city}"
        expect(flight.destination_city).to eq(@destination_city),
          "目的地城市错误。期望: #{@destination_city}（美国西海岸），实际: #{flight.destination_city}"
      end
      
      # 断言3: 出发日期合理（6天后）（时间要求）
      add_assertion "出发日期合理（#{@departure_date}左右）", weight: 15 do
        flight = @flight_booking.flight
        date_diff = (flight.flight_date - @departure_date).abs
        expect(date_diff).to be <= 3,
          "出发日期偏差过大。期望: #{@departure_date}左右（6天后）, 实际: #{flight.flight_date}，偏差#{date_diff}天（航班号: #{flight.flight_number}）"
      end
      
      # 断言4: 机票价格正确（长途国际航班高票价）
      add_assertion "机票价格正确（长途国际航班）", weight: 25 do
        flight = @flight_booking.flight
        expect(@flight_booking.total_price).to be > 0,
          "订单总价异常（价格为0或负数）。实际总价: #{@flight_booking.total_price}元"
        expect(@flight_booking.total_price).to eq(flight.price),
          "订单总价与航班票价不符。期望: #{flight.price}元（跨太平洋长途航班）, 实际: #{@flight_booking.total_price}元（航班号: #{flight.flight_number}）"
      end
      
      # 断言5: 乘客信息正确（张三）（信息准确性）
      add_assertion "乘客信息正确（#{@expected_passenger_name}）", weight: 15 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}（国际航班需准确姓名）, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证号错误。期望: #{@expected_passenger_id}（国际航班需准确证件号）, 实际: #{@flight_booking.passenger_id_number}"
      end
      
      # 断言6: 订单状态有效（订单完整性）
      add_assertion "订单状态有效", weight: 10 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。期望状态: pending/paid/completed, 实际状态: #{@flight_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三')
      
      # 选择第一个可用的国际航班（北京→洛杉矶）
      flight = @available_flights.first
      
      # 创建航班订单（国际长途航班，票价较高）
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
        departure_date: @departure_date.to_s,
        flight_date: @flight_date.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @departure_date = Date.parse(data['departure_date'])
      @flight_date = Date.parse(data['flight_date'])
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_contact_phone = data['expected_contact_phone']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).where('flight_date BETWEEN ? AND ?', @departure_date - 3.days, @departure_date + 3.days).to_a
    end
  end
end
