# frozen_string_literal: true

require_relative '../base_validator'

# V164BookRoundTripTrainAndHotelValidator
# 验证用例164: 给张三预订明天上海到杭州的往返火车（去程明天，返程第4天），并预订杭州酒店3晚住宿（明天入住，第4天退房）
#
# 任务描述:
#   张三计划预订上海到杭州的往返火车和酒店住宿：明天出发去杭州，在杭州住3晚，第4天退房并返回上海。
#   1. 去程火车（明天上海→杭州）
#   2. 返程火车（第4天杭州→上海）
#   3. 酒店住宿（明天入住杭州酒店，住3晚后第4天退房当天返程）
#
# 任务分解步骤:
#   1. 查询去程火车（明天上海→杭州，从Train获取最便宜火车）
#   2. 查询返程火车（第4天杭州→上海，从Train获取最便宜火车）
#   3. 创建去程火车订单（乘客=张三，联系人=张三）
#   4. 创建返程火车订单（乘客=张三，联系人=张三）
#   5. 查询杭州酒店（从Hotel获取杭州酒店）
#   6. 创建酒店订单（明天入住，住3晚后第4天退房，退房当天返程，入住人=张三）
#
# 评分标准（总分100分）:
#   1. 创建了去程火车订单（上海→杭州） (20分)
#   2. 创建了返程火车订单（杭州→上海） (20分)
#   3. 去程日期正确（明天） (10分)
#   4. 返程日期正确（第4天） (10分)
#   5. 创建了酒店订单 (15分)
#   6. 酒店入住日期和时长正确（明天入住，住3晚，第4天退房） (12分)
#   7. 乘客信息正确（张三） (5分)
#   8. 酒店入住人信息正确（张三） (8分)

module V151V200
  class V164BookRoundTripTrainAndHotelValidator < BaseValidator
    self.validator_id = 'v164_book_round_trip_train_and_hotel_validator'
    self.task_id = 'b4c5d6e7-8f9a-0b1c-2d3e-4f5a6b7c8d9e'
    self.title = '给张三预订明天上海到杭州的往返火车（去程明天，返程第4天），并预订杭州酒店3晚住宿（明天入住，第4天退房）'
    self.description = '给张三预订明天上海到杭州的往返火车和酒店住宿：去程明天出发，返程第4天返回，酒店明天入住，住3晚后第4天退房当天返程'
    self.timeout_seconds = 300

    def prepare
      @departure_city = '上海'
      @arrival_city = '杭州'
      @outbound_date = Date.current + 1.day  # 明天
      @return_date = @outbound_date + 3.days  # 第4天返回
      @hotel_checkin_date = @outbound_date
      @hotel_checkout_date = @hotel_checkin_date + 3.days  # 住3晚，第4天退房当天返程
      @nights = 3
      
      # 预查询demo_user的乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_name = @passenger.name
      @expected_phone = @passenger.phone
      @expected_id_number = @passenger.id_number
      
      # 查找去程火车
      @available_outbound_trains = Train
        .where(departure_city: @departure_city, arrival_city: @arrival_city, data_version: 0)
        .by_date(@outbound_date)
        .order(price_second_class: :asc)
        .to_a
      
      expect(@available_outbound_trains).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}的火车（明天#{@outbound_date}）"
      
      # 查找返程火车
      @available_return_trains = Train
        .where(departure_city: @arrival_city, arrival_city: @departure_city, data_version: 0)
        .by_date(@return_date)
        .order(price_second_class: :asc)
        .to_a
      
      expect(@available_return_trains).not_to be_empty, "数据包缺少#{@arrival_city}→#{@departure_city}的返程火车（第4天#{@return_date}）"
      
      # 查找酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(phone: @passenger.phone, data_version: 0)
      
      # 创建去程火车订单
      outbound_train = @available_outbound_trains.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: outbound_train.id,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        seat_type: 'second_class',
        total_price: outbound_train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建返程火车订单
      return_train = @available_return_trains.first
      TrainBooking.create!(
        user_id: user.id,
        train_id: return_train.id,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        contact_phone: @passenger.phone,
        seat_type: 'second_class',
        total_price: return_train.price_second_class,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建酒店订单
      hotel = @available_hotels.first
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date,
        guest_name: @passenger.name,
        guest_phone: @passenger.phone,
        payment_method: '花呗',
        total_price: room.price * @nights,
        data_version: @data_version
      )
    end

    def execution_state_data
      {
        data_version: @data_version,
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        outbound_date: @outbound_date.to_s,
        return_date: @return_date.to_s,
        hotel_checkin_date: @hotel_checkin_date.to_s,
        hotel_checkout_date: @hotel_checkout_date.to_s,
        nights: @nights,
        expected_name: @expected_name,
        expected_phone: @expected_phone,
        expected_id_number: @expected_id_number
      }
    end

    def restore_from_state(data)
      @data_version = data['data_version']
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @outbound_date = Date.parse(data['outbound_date']) if data['outbound_date']
      @return_date = Date.parse(data['return_date']) if data['return_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
      @nights = data['nights']
      @expected_name = data['expected_name']
      @expected_phone = data['expected_phone']
      @expected_id_number = data['expected_id_number']
    end

    def verify
      # 断言1: 创建了去程火车订单
      add_assertion "创建了去程火车订单（#{@departure_city}→#{@arrival_city}）", weight: 20 do
        all_tickets = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @departure_city, arrival_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @outbound_ticket = all_tickets.first
        expect(@outbound_ticket).not_to be_nil, "未找到去程火车订单"
      end
      
      return if @outbound_ticket.nil?
      
      # 断言2: 创建了返程火车订单
      add_assertion "创建了返程火车订单（#{@arrival_city}→#{@departure_city}）", weight: 20 do
        all_tickets = TrainBooking
          .joins(:train)
          .includes(:train)
          .where(trains: { departure_city: @arrival_city, arrival_city: @departure_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @return_ticket = all_tickets.first
        expect(@return_ticket).not_to be_nil, "未找到返程火车订单"
      end
      
      return if @return_ticket.nil?
      
      # 断言3: 去程日期正确（明天）
      add_assertion "去程日期正确（明天）", weight: 10 do
        outbound_train_date = @outbound_ticket.train.departure_time.to_date
        # 动态计算期望日期：使用实际火车订单的日期
        expected_outbound_date = @outbound_date
        
        expect(outbound_train_date).to eq(expected_outbound_date),
          "去程日期错误。期望: #{expected_outbound_date}（明天）, 实际: #{outbound_train_date}"
      end
      
      # 断言4: 返程日期正确（第4天）
      add_assertion "返程日期正确（第4天）", weight: 10 do
        return_train_date = @return_ticket.train.departure_time.to_date
        # 动态计算期望日期：使用实际火车订单的日期
        expected_return_date = @return_date
        
        expect(return_train_date).to eq(expected_return_date),
          "返程日期错误。期望: #{expected_return_date}（第4天）, 实际: #{return_train_date}"
      end
      
      # 断言5: 创建了酒店订单
      add_assertion "创建了酒店订单", weight: 15 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言6: 酒店入住日期和时长正确（明天入住，住3晚，第4天退房）
      add_assertion "酒店入住日期和时长正确（明天入住，住3晚，第4天退房）", weight: 12 do
        # 动态计算期望的入住日期和退房日期（基于去程和返程火车日期）
        expected_checkin = @outbound_ticket.train.departure_time.to_date  # 明天（去程当天）
        expected_checkout = @return_ticket.train.departure_time.to_date  # 第4天退房（返程当天）
        
        expect(@hotel_booking.check_in_date).to eq(expected_checkin),
          "入住日期错误。期望: #{expected_checkin}（去程#{@outbound_ticket.train.departure_time.to_date.strftime('%m月%d日')}当天/明天）, 实际: #{@hotel_booking.check_in_date}"
        
        expect(@hotel_booking.check_out_date).to eq(expected_checkout),
          "退房日期错误。期望: #{expected_checkout}（返程#{@return_ticket.train.departure_time.to_date.strftime('%m月%d日')}当天/第4天）, 实际: #{@hotel_booking.check_out_date}"
        
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "住宿天数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      # 断言7: 乘客信息正确（张三）
      add_assertion "乘客信息正确（#{@expected_name}）", weight: 5 do
        expect(@outbound_ticket.passenger_name).to eq(@expected_name),
          "乘客姓名错误。期望: #{@expected_name}, 实际: #{@outbound_ticket.passenger_name}"
        expect(@outbound_ticket.passenger_id_number).to eq(@expected_id_number),
          "乘客身份证号错误。期望: #{@expected_id_number}, 实际: #{@outbound_ticket.passenger_id_number}"
      end
      
      # 断言8: 酒店入住人信息正确（#{@expected_name}）
      add_assertion "酒店入住人信息正确（#{@expected_name}）", weight: 8 do
        expect(@hotel_booking.guest_name).to eq(@expected_name),
          "酒店入住人姓名错误。期望: #{@expected_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end
  end
end