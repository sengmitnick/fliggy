# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例131: 帮张三预订明天北京→上海火车票（二等座）+上海火车站附近酒店（明天入住1晚）
#
# 任务描述:
#   张三明天需要从北京乘火车到上海，希望预订二等座火车票和上海火车站附近的酒店。
#   由于火车到达时间较晚，希望酒店位置靠近火车站，方便到达。
#   Agent 需要创建1个火车票订单和1个酒店订单，确保座位类型为二等座，酒店位于火车站附近（名称或地址包含"站"关键词），入住日期为火车到达当天。
#
# 业务流程（8个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、身份证号、电话作为乘客和入住人信息）
#   2. 搜索北京→上海火车（明天出发）
#   3. 创建火车票订单（使用张三的乘客信息，座位类型=二等座）
#   4. 搜索上海市区酒店
#   5. 筛选火车站附近酒店（名称或地址包含"站"关键词）
#   6. 筛选整晚房型（排除钟点房 room_category = 'overnight'）
#   7. 计算入住和退房日期（火车到达当天入住，住1晚）
#   8. 创建酒店订单（使用张三的入住人信息）
#
# 复杂度分析（8个关键点）：
#   1. 需要理解火车+酒店组合预订场景
#   2. 需要明确火车路线（北京→上海，明天出发）
#   3. 需要选择二等座座位类型（seat_type = 'second_class'）
#   4. 需要使用受益人信息作为火车乘客和酒店入住人
#   5. 需要理解"火车站附近"的地理位置要求（名称或地址包含"站"关键词）
#   6. 需要明确酒店城市（上海，到达城市）
#   7. 需要理解入住时间逻辑（火车到达当天入住，住1晚）
#   8. 需要筛选整晚房型（排除钟点房，使用 room_category = 'overnight'）
#   ❌ 不能一次性提供所有信息：需要分别查询火车和酒店数据，筛选火车站附近酒店，分步骤创建订单。
#
# 评分标准（8项，总计100分）：
#   1. 创建了火车票订单（20分）
#   2. 火车票路线正确（北京→上海）（15分）
#   3. 座位类型=二等座（10分）
#   4. 乘客信息正确（张三的姓名和身份证号）（10分）
#   5. 创建了酒店订单（15分）
#   6. 酒店城市正确（上海）（10分）
#   7. 酒店位置（火车站附近，名称或地址包含"站"）（10分）
#   8. 入住日期=火车日期（火车当天入住）（5分）
#   9. 入住人信息正确（张三的姓名和电话）（5分）
#
# 使用方法:
#   rake validator:simulate_single[v131_book_train_and_hotel_near_station_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V101V150
  class V131BookTrainAndHotelNearStationValidator < BaseValidator
    self.validator_id = 'v131_book_train_and_hotel_near_station_validator'
    self.task_id = 'a4b5c6d7-8e9f-0a1b-2c3d-4e5f6a7b8c9d'
    self.title = '帮张三预订明天北京→上海火车票（二等座）+上海火车站附近酒店（明天入住1晚）'
    self.description = '帮张三预订明天北京→上海火车票（二等座）+上海火车站附近酒店（明天入住1晚）'
    self.timeout_seconds = 300

    def task_description
      "帮张三订明天从北京到上海的火车票（二等座），同时订上海火车站附近的酒店住1晚"
    end

    def prepare
      @departure_city = "北京"
      @arrival_city = "上海"
      @train_date = Date.current + 1.day
      @hotel_city = "上海"
      @check_in_date = @train_date
      @check_out_date = @train_date + 1.day
      
      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_passenger_id = @passenger.id_number
      @expected_phone = @passenger.phone
      
      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).order(price_second_class: :asc)

      raise "未找到符合条件的火车" if @available_trains.empty?

      # 筛选酒店：地址包含"站"关键词
      all_hotels = Hotel.where(city: @hotel_city, data_version: 0).order(price: :asc)
      @available_hotels = all_hotels.select { |h| h.address.to_s.include?("站") || h.name.to_s.include?("站") }

      raise "未找到火车站附近的酒店" if @available_hotels.empty?
    end

    def verify
      add_assertion "创建了火车票订单", weight: 20 do
        all_train_bookings = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @train_booking = all_train_bookings.first
        expect(@train_booking).not_to be_nil, "未找到火车票订单"
      end

      return if @train_booking.nil?

      add_assertion "火车票路线正确（#{@departure_city}→#{@arrival_city}）", weight: 15 do
        expect(@train_booking.train.departure_city).to eq(@departure_city)
        expect(@train_booking.train.arrival_city).to eq(@arrival_city)
      end

      add_assertion "座位类型=二等座", weight: 10 do
        expect(@train_booking.seat_type).to eq('second_class')
      end

      add_assertion "乘客信息正确（张三）", weight: 10 do
        expect(@train_booking.passenger_name).to eq(@expected_passenger_name),
          "乘客姓名错误。期望: #{@expected_passenger_name}, 实际: #{@train_booking.passenger_name}"
        expect(@train_booking.passenger_id_number).to eq(@expected_passenger_id),
          "乘客身份证号错误。期望: #{@expected_passenger_id}, 实际: #{@train_booking.passenger_id_number}"
      end

      add_assertion "创建了酒店订单", weight: 15 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @hotel_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a

        @hotel_booking = all_hotel_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end

      return if @hotel_booking.nil?

      add_assertion "酒店城市正确（#{@hotel_city}）", weight: 10 do
        expect(@hotel_booking.hotel.city).to eq(@hotel_city)
      end

      add_assertion "酒店位置（火车站附近）", weight: 10 do
        address = @hotel_booking.hotel.address.to_s
        name = @hotel_booking.hotel.name.to_s
        has_station_keyword = address.include?("站") || name.include?("站")
        expect(has_station_keyword).to be(true),
          "酒店不在火车站附近。酒店名: #{name}, 地址: #{address}"
      end

      add_assertion "入住日期=火车日期（#{@check_in_date}）", weight: 5 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（火车当天）, 实际: #{@hotel_booking.check_in_date}"
      end

      add_assertion "入住人信息正确（张三）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人联系电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)

      train = @available_trains.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: train.id,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        seat_type: 'second_class',
        total_price: train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )

      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: passenger.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end

    private

    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        train_date: @train_date.to_s,
        hotel_city: @hotel_city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_passenger_id: @expected_passenger_id,
        expected_phone: @expected_phone
      }
    end

    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @train_date = Date.parse(data['train_date'])
      @hotel_city = data['hotel_city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @expected_passenger_name = data['expected_passenger_name']
      @expected_passenger_id = data['expected_passenger_id']
      @expected_phone = data['expected_phone']

      @available_trains = Train.where(
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        data_version: 0
      ).by_date(@train_date).order(price_second_class: :asc)

      all_hotels = Hotel.where(city: @hotel_city, data_version: 0).order(price: :asc)
      @available_hotels = all_hotels.select { |h| h.address.to_s.include?("站") || h.name.to_s.include?("站") }
    end
  end
end
