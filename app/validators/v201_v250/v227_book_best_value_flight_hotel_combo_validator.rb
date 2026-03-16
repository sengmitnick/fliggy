# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例227: 帮张三预订明天深圳→上海性价比最高航班+上海酒店（明天入住2晚），综合考虑航班时长、价格、酒店评分
#
# 任务描述:
#   张三明天需要从深圳去上海出差，需要预订航班和酒店住2晚。
#   希望综合考虑航班时长、价格、酒店评分等因素，选择性价比最高的组合。
#
# 业务流程（9个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 搜索深圳→上海航班（明天出发）
#   3. 搜索上海酒店（明天入住，2天后退房，住2晚）
#   4. 计算航班综合性价比分数（考虑飞行时长和价格，时长越短、价格越低越好）
#   5. 计算酒店综合性价比分数（考虑评分和价格，评分越高、价格越合理越好）
#   6. 选择综合性价比最高的航班
#   7. 选择综合性价比最高的酒店
#   8. 创建航班订单（Booking，乘客信息填写张三）
#   9. 创建酒店订单（HotelBooking，入住人信息填写张三）
#
# 复杂度分析（9个关键点）：
#   1. 多维度优化问题：需要同时考虑航班时长、航班价格、酒店评分、酒店价格等多个因素
#   2. 性价比评分算法：需要设计合理的评分公式，平衡不同维度的权重
#   3. 航班时长计算：需要根据起降时间计算飞行时长，并转换为评分
#   4. 价格归一化处理：不同价格区间的商品需要统一转换为评分进行比较
#   5. 多类型订单创建：航班订单+酒店订单，需要理解两种订单的字段和关系
#   6. 日期推算：明天出发+入住，2天后退房，需要正确处理相对日期
#   7. 乘客信息映射：需要将张三的姓名、身份证号、电话正确填写到两个订单中
#   8. 性价比验证：需要验证选择的航班和酒店的综合得分处于较优水平
#   9. 订单状态管理：两个订单都需要设置合理的支付状态
#
# 评分标准（9项，总计100分）：
#   1. 创建了航班订单（深圳→上海，明天出发） - 15分
#   2. 创建了酒店订单（上海，明天入住2晚） - 15分
#   3. 航班日期正确（明天） - 10分
#   4. 酒店入住日期正确（明天入住，2天后退房） - 10分
#   5. 乘客信息正确（张三，含姓名、身份证、手机号） - 5分
#   6. 入住人信息正确（张三，含姓名、手机号） - 5分
#   7. 航班性价比较优（综合考虑时长和价格） - 20分
#   8. 酒店性价比较优（综合考虑评分和价格） - 15分
#   9. 订单状态有效（两个订单都为pending/paid/completed） - 5分
#
# 使用方法:
#   rake validator:simulate_single[v227_book_best_value_flight_hotel_combo_validator]
module V201V250
  class V227BookBestValueFlightHotelComboValidator < BaseValidator
    self.validator_id = 'v227_book_best_value_flight_hotel_combo_validator'
    self.task_id = '5ff576ff-6f6f-6f8f-8f9f-7f0a1b2c3d4f'
    self.title = '帮张三预订明天深圳→上海性价比最高航班+上海酒店（明天入住2晚），综合考虑航班时长、价格、酒店评分'
    self.description = '张三明天要从深圳去上海出差，需要预订航班和酒店住2晚，希望综合考虑航班时长、价格、酒店评分等因素，选择性价比最高的组合'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '深圳'
      @destination_city = '上海'
      @flight_date = Date.today + 1.day
      @check_in_date = @flight_date
      @check_out_date = @check_in_date + 2.days
      
      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_phone = @passenger.phone
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0).to_a
      
      raise "未找到航班或酒店" if @available_flights.empty? || @available_hotels.empty?
      
      # 计算综合性价比参考值
      # 航班综合分数 = (时长分数 + 价格分数) / 2
      flight_scores = @available_flights.map do |f|
        duration_minutes = (f.arrival_time - f.departure_time) / 60
        duration_score = 100.0 / (duration_minutes / 60.0 + 1)  # 时长越短越好
        price_score = 100.0 / (f.price + 1)  # 价格越低越好
        (duration_score + price_score) / 2.0
      end
      @reference_flight_score = flight_scores.max
      
      # 酒店综合分数 = (评分分数 + 价格分数) / 2
      hotel_scores = @available_hotels.map do |h|
        rating_score = h.rating * 20  # 5星满分=100分
        price_score = 100.0 / (h.price + 1)
        (rating_score + price_score) / 2.0
      end
      @reference_hotel_score = hotel_scores.max
      
      {
        task: "请预订#{@flight_date.strftime('%Y年%m月%d日')}从#{@departure_city}到#{@destination_city}的航班和酒店（住2晚），要求综合性价比最高，综合考虑航班时长、价格、酒店评分等因素。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          flight_date: @flight_date,
          nights: 2,
          optimization: '综合性价比最高'
        },
        hint: "需要平衡多个因素：航班时长、航班价格、酒店评分、酒店价格，选择综合得分最高的组合。"
      }
    end
    
    def verify
      add_assertion "创建了航班订单", weight: 15 do
        @flight_booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@flight_booking).not_to be_nil, "未找到航班订单"
      end
      
      return if @flight_booking.nil?
      
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "航班日期正确（#{@flight_date}）", weight: 10 do
        expect(@flight_booking.flight.flight_date).to eq(@flight_date),
          "航班日期错误。期望: #{@flight_date}, 实际: #{@flight_booking.flight.flight_date}"
      end
      
      add_assertion "酒店入住日期正确（入住#{@check_in_date}，退房#{@check_out_date}）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "乘客信息正确（张三）", weight: 5 do
        expect(@flight_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@flight_booking.passenger_name}"
        expect(@flight_booking.passenger_id_number).to eq(@expected_passenger_id),
          "身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@flight_booking.passenger_id_number}"
        expect(@flight_booking.contact_phone).to eq(@expected_phone),
          "联系电话错误。期望: #{@expected_phone}, 实际: #{@flight_booking.contact_phone}"
      end
      
      add_assertion "入住人信息正确（张三）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "航班性价比较优", weight: 20 do
        flight = @flight_booking.flight
        duration_minutes = (flight.arrival_time - flight.departure_time) / 60
        duration_score = 100.0 / (duration_minutes / 60.0 + 1)
        price_score = 100.0 / (flight.price + 1)
        actual_flight_score = (duration_score + price_score) / 2.0
        
        # 允许15%的偏差
        expect(actual_flight_score).to be >= @reference_flight_score * 0.85,
          "航班综合性价比不佳。参考最佳分数: #{@reference_flight_score.round(1)}, 实际分数: #{actual_flight_score.round(1)} (时长#{(duration_minutes/60.0).round(1)}h, 价格#{flight.price}元)"
      end
      
      add_assertion "酒店性价比较优", weight: 15 do
        hotel = @hotel_booking.hotel
        rating_score = hotel.rating * 20
        price_score = 100.0 / (hotel.price + 1)
        actual_hotel_score = (rating_score + price_score) / 2.0
        
        # 允许15%的偏差
        expect(actual_hotel_score).to be >= @reference_hotel_score * 0.85,
          "酒店综合性价比不佳。参考最佳分数: #{@reference_hotel_score.round(1)}, 实际分数: #{actual_hotel_score.round(1)} (评分#{hotel.rating}星, 价格#{hotel.price}元/晚)"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@flight_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 计算每个航班的综合分数
      flight_with_scores = @available_flights.map do |f|
        duration_minutes = (f.arrival_time - f.departure_time) / 60
        duration_score = 100.0 / (duration_minutes / 60.0 + 1)
        price_score = 100.0 / (f.price + 1)
        score = (duration_score + price_score) / 2.0
        { flight: f, score: score }
      end
      best_flight = flight_with_scores.max_by { |fs| fs[:score] }[:flight]
      
      # 计算每个酒店的综合分数
      hotel_with_scores = @available_hotels.map do |h|
        rating_score = h.rating * 20
        price_score = 100.0 / (h.price + 1)
        score = (rating_score + price_score) / 2.0
        { hotel: h, score: score }
      end
      best_hotel = hotel_with_scores.max_by { |hs| hs[:score] }[:hotel]
      room = best_hotel.hotel_rooms.where(data_version: 0).first
      
      Booking.create!(
        user: user,
        flight: best_flight,
        passenger_name: @expected_passenger_name,
        passenger_id_number: @expected_passenger_id,
        contact_phone: @expected_phone,
        total_price: best_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      HotelBooking.create!(
        user: user,
        hotel: best_hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @expected_passenger_name,
        guest_phone: @expected_phone,
        room_count: 1,
        total_price: best_hotel.price * 2,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        reference_flight_score: @reference_flight_score,
        reference_hotel_score: @reference_hotel_score,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @destination_city = data['destination_city']
      @flight_date = Date.parse(data['flight_date'])
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @reference_flight_score = data['reference_flight_score'].to_f
      @reference_hotel_score = data['reference_hotel_score'].to_f
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_phone = data['expected_phone']
      
      @available_flights = Flight.where(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @flight_date,
        data_version: 0
      ).to_a
      
      @available_hotels = Hotel.where(city: @destination_city, data_version: 0).to_a
    end
  end
end
