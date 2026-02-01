# frozen_string_literal: true

require_relative '../base_validator'

# V169: 预订多段联程航班
# 验证用户能够完成多城市联程航班预订（北京→上海→广州）

module V101V150
  class V169BookMultiCityFlightValidator < BaseValidator
    self.validator_id = 'v169_book_multi_city_flight_validator'
    self.task_id = 'a9b0c1d2-3e4f-5a6b-7c8d-9e0f1a2b3c4d'
    self.title = '预订多城市联程航班（北京→上海→广州）'
    self.description = '预订明天北京到上海的航班，以及后天上海到广州的航班，完成多城市联程'
    self.timeout_seconds = 300

    def prepare
      @city1 = '北京'
      @city2 = '上海'
      @city3 = '广州'
      @flight1_date = Date.tomorrow
      @flight2_date = @flight1_date + 1.day
      
      # 查找第一段航班
      @available_flight1 = Flight
        .where(departure_city: @city1, destination_city: @city2, flight_date: @flight1_date, data_version: 0)
        .order(price: :asc)
        .to_a
      
      expect(@available_flight1).not_to be_empty, "数据包缺少#{@city1}→#{@city2}的航班"
      
      # 查找第二段航班
      @available_flight2 = Flight
        .where(departure_city: @city2, destination_city: @city3, flight_date: @flight2_date, data_version: 0)
        .order(price: :asc)
        .to_a
      
      expect(@available_flight2).not_to be_empty, "数据包缺少#{@city2}→#{@city3}的航班"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建第一段航班订单
      flight1 = @available_flight1.first
      Booking.create!(
        user: user,
        flight: flight1,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: flight1.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建第二段航班订单
      flight2 = @available_flight2.first
      Booking.create!(
        user: user,
        flight: flight2,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: flight2.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
    end

    def verify
      # 断言1: 创建了第一段航班订单
      add_assertion "创建了第一段航班订单（#{@city1}→#{@city2}）", weight: 25 do
        @booking1 = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @city1, destination_city: @city2 })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@booking1).not_to be_nil, "未找到#{@city1}→#{@city2}的航班订单"
      end
      
      return if @booking1.nil?
      
      # 断言2: 创建了第二段航班订单
      add_assertion "创建了第二段航班订单（#{@city2}→#{@city3}）", weight: 25 do
        @booking2 = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @city2, destination_city: @city3 })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@booking2).not_to be_nil, "未找到#{@city2}→#{@city3}的航班订单"
      end
      
      return if @booking2.nil?
      
      # 断言3: 第一段航班日期正确
      add_assertion "第一段航班日期正确（#{@flight1_date}）", weight: 15 do
        expect(@booking1.flight.flight_date).to eq(@flight1_date),
          "第一段航班日期错误。期望: #{@flight1_date}（明天）, 实际: #{@booking1.flight.flight_date}"
      end
      
      # 断言4: 第二段航班日期正确
      add_assertion "第二段航班日期正确（#{@flight2_date}）", weight: 15 do
        expect(@booking2.flight.flight_date).to eq(@flight2_date),
          "第二段航班日期错误。期望: #{@flight2_date}（后天）, 实际: #{@booking2.flight.flight_date}"
      end
      
      # 断言5: 形成联程路线（北京→上海→广州）
      add_assertion "形成联程路线（#{@city1}→#{@city2}→#{@city3}）", weight: 20 do
        # 第一段终点是第二段起点
        expect(@booking1.flight.destination_city).to eq(@booking2.flight.departure_city),
          "联程路线错误。第一段终点: #{@booking1.flight.destination_city}, 第二段起点: #{@booking2.flight.departure_city}"
        
        # 第二段应该在第一段之后
        expect(@booking2.flight.flight_date).to be > @booking1.flight.flight_date,
          "第二段航班应该在第一段航班之后"
      end
    end
  end
end
