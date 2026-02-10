# frozen_string_literal: true

require_relative '../base_validator'

# V319: 预订15天后北京到三亚往返机票+三亚亚龙湾亲子度假酒店亲子家庭房（5晚，1间房，2大1小）
#
# 任务描述:
#   用户需要预订15天后北京到三亚的往返机票，以及三亚亚龙湾亲子度假酒店亲子家庭房（入住5晚，2成人+1儿童，酒店入住日期与航班衔接）
#
# 评分标准:
#   - 创建往返机票订单+航线正确 (20%)
#   - 去程日期正确（15天后） (8%)
#   - 返程日期正确（20天后） (8%)
#   - 机票乘客信息正确（刘强、陈静或小明） (7%)
#   - 创建酒店订单+酒店名称房型正确 (20%)
#   - 入住退房日期与航班衔接（5晚） (8%)
#   - 房间数和人数正确（1间2大1小） (8%)
#   - 联系人信息正确（刘强、陈静或小明） (12%)
#   - 订单状态和价格有效 (9%)
module V301V350
  class V319BookSummerVacationFamilyTourValidator < BaseValidator
    self.validator_id = 'v319_book_summer_vacation_family_tour_validator'
    self.task_id = "41296cec-e182-44c9-ac20-c2180e92c487"
    self.title = "预订15天后北京到三亚往返机票+三亚亚龙湾亲子度假酒店亲子家庭房（5晚，1间房，2大1小）"
    self.description = "用户需要预订15天后北京到三亚的往返机票，以及三亚亚龙湾亲子度假酒店亲子家庭房（入住5晚，2成人+1儿童，酒店入住日期与航班衔接）"
    self.timeout_seconds = 180

    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query existing passengers from demo_user (family: 刘强+陈静+小明)
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      @xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      
      # Expected contact info (multi-choice: 刘强、陈静 or 小明)
      @expected_contact_names = [@liuqiang.name, @chenjing.name, @xiaoming.name]
      @expected_contact_phones = {
        @liuqiang.name => @liuqiang.phone,
        @chenjing.name => @chenjing.phone,
        @xiaoming.name => @xiaoming.phone
      }
      
      # 15天后出发，5晚行程
      @departure_date = Date.current + 15.days
      @return_date = Date.current + 20.days
      @departure_city = "北京"
      @destination_city = "三亚"
      @hotel_name = "三亚亚龙湾亲子度假酒店"
      @room_type = "亲子家庭房"
      
      # 查找15天后的北京→三亚航班（任意航班）
      @outbound_flight = Flight.find_by!(
        departure_city: @departure_city,
        destination_city: @destination_city,
        flight_date: @departure_date,
        data_version: 0
      )
      
      # 查找20天后的三亚→北京航班（任意航班）
      @return_flight = Flight.find_by!(
        departure_city: @destination_city,
        destination_city: @departure_city,
        flight_date: @return_date,
        data_version: 0
      )
      
      # 查找目的地
      city = City.find_by!(name: @destination_city, data_version: 0)
      destination = Destination.find_by!(
        name: @destination_city,
        data_version: 0
      )

      # 查找亲子酒店
      @hotel = Hotel.find_by!(
        name: @hotel_name,
        city: @destination_city,
        data_version: 0
      )

      @hotel_room = @hotel.hotel_rooms.find_by!(
        room_type: @room_type,
        data_version: 0
      )

      # 查找亲子活动景点
      @attraction = Attraction.find_by!(
        name: "三亚亚龙湾热带天堂森林公园",
        city: @destination_city,
        data_version: 0
      )

      @activity = @attraction.attraction_activities.find_by!(
        name: "亲子雨林探险",
        data_version: 0
      )

      {
        task: "请为刘强家庭（刘强+陈静+小明，2大1小）预订#{@departure_date.strftime('%Y年%m月%d日')}（15天后）从北京到三亚的往返机票，以及#{@hotel_name}#{@room_type}（入住#{@departure_date.strftime('%m月%d日')}至#{@return_date.strftime('%m月%d日')}，共5晚）。",
        requirements: {
          departure_city: @departure_city,
          destination_city: @destination_city,
          departure_date: @departure_date,
          return_date: @return_date,
          nights: 5,
          hotel_name: @hotel_name,
          room_type: @room_type,
          adults: 2,
          children: 1
        },
        hint: "建议选择包含儿童设施的酒店，机票和酒店日期要衔接。返程航班在#{@return_date.strftime('%Y年%m月%d日')}（20天后）。"
      }
    end

    def verify
      # 断言1: 创建了往返机票订单 (12%)
      add_assertion "创建了往返机票订单", weight: 12 do
        all_bookings = Booking
          .joins(:flight)
          .includes(:flight, :return_flight)
          .where(flights: { 
            departure_city: @departure_city,
            destination_city: @destination_city
          })
          .where(trip_type: 'round_trip')
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到往返机票订单"
        
        @flight_bookings = all_bookings.select { |b| b.return_flight.present? }
        expect(@flight_bookings.size).to be >= 1, "未找到符合条件的往返机票"
      end

      return if @flight_bookings.nil? || @flight_bookings.empty?

      # 断言2: 航线正确（北京→三亚往返） (8%)
      add_assertion "航线正确（#{@departure_city}→#{@destination_city}往返）", weight: 8 do
        @flight_bookings.each do |booking|
          expect(booking.flight.departure_city).to eq(@departure_city),
            "去程出发城市错误。期望: #{@departure_city}, 实际: #{booking.flight.departure_city}"
          expect(booking.flight.destination_city).to eq(@destination_city),
            "去程目的城市错误。期望: #{@destination_city}, 实际: #{booking.flight.destination_city}"
          
          if booking.return_flight
            expect(booking.return_flight.departure_city).to eq(@destination_city),
              "返程出发城市错误。期望: #{@destination_city}, 实际: #{booking.return_flight.departure_city}"
            expect(booking.return_flight.destination_city).to eq(@departure_city),
              "返程目的城市错误。期望: #{@departure_city}, 实际: #{booking.return_flight.destination_city}"
          end
        end
      end

      # 断言3: 去程日期正确（15天后） (8%)
      add_assertion "去程日期正确（#{@departure_date.strftime('%Y-%m-%d')}）", weight: 8 do
        @flight_bookings.each do |booking|
          actual_date = booking.flight.departure_time.to_date
          expect(actual_date).to eq(@departure_date),
            "去程日期错误。期望: #{@departure_date}（15天后），实际: #{actual_date}"
        end
      end

      # 断言4: 返程日期正确（20天后） (8%)
      add_assertion "返程日期正确（#{@return_date.strftime('%Y-%m-%d')}）", weight: 8 do
        @flight_bookings.each do |booking|
          if booking.return_flight
            actual_return = booking.return_flight.departure_time.to_date
            expect(actual_return).to eq(@return_date),
              "返程日期错误。期望: #{@return_date}（20天后）, 实际: #{actual_return}"
          else
            raise "未找到返程航班"
          end
        end
      end
      
      # 断言5: 机票乘客信息正确（刘强、陈静或小明） (7%)
      add_assertion "机票乘客信息正确（刘强、陈静或小明）", weight: 7 do
        @flight_bookings.each do |booking|
          expect(@expected_contact_names).to include(booking.passenger_name),
            "机票乘客姓名错误。期望: #{@expected_contact_names.join('、')}, 实际: #{booking.passenger_name}"
          
          # 根据乘客姓名验证身份证号
          expected_passenger = case booking.passenger_name
          when @liuqiang.name then @liuqiang
          when @chenjing.name then @chenjing
          when @xiaoming.name then @xiaoming
          end
          
          if expected_passenger
            expect(booking.passenger_id_number).to eq(expected_passenger.id_number),
              "机票乘客身份证号错误。期望: #{expected_passenger.id_number}, 实际: #{booking.passenger_id_number}"
          end
        end
      end

      # 断言6: 创建了酒店订单 (12%)
      add_assertion "创建了#{@hotel_name}订单", weight: 12 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_hotel_bookings).not_to be_empty, "未找到酒店订单"
        
        @hotel_bookings = all_hotel_bookings
        expect(@hotel_bookings.size).to be >= 1, "未找到酒店订单"
      end

      return if @hotel_bookings.nil? || @hotel_bookings.empty?

      # 断言7: 酒店名称和房型正确 (8%)
      add_assertion "酒店名称和房型正确（#{@hotel_name} #{@room_type}）", weight: 8 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.name).to eq(@hotel_name),
            "酒店名称错误。期望: #{@hotel_name}，实际: #{booking.hotel.name}"
          expect(booking.hotel_room.room_type).to eq(@room_type),
            "房型错误。期望: #{@room_type}，实际: #{booking.hotel_room.room_type}"
        end
      end

      # 断言8: 入住退房日期与航班衔接（5晚） (8%)
      add_assertion "入住退房日期与航班衔接（#{@departure_date.strftime('%Y-%m-%d')}至#{@return_date.strftime('%Y-%m-%d')}，5晚）", weight: 8 do
        @hotel_bookings.each do |booking|
          expect(booking.check_in_date).to eq(@departure_date),
            "入住日期应与出发日期一致。期望: #{@departure_date}, 实际: #{booking.check_in_date}"
          expect(booking.check_out_date).to eq(@return_date),
            "退房日期应与返程日期一致。期望: #{@return_date}, 实际: #{booking.check_out_date}"
          
          nights = (booking.check_out_date - booking.check_in_date).to_i
          expect(nights).to eq(5),
            "住宿天数错误。期望: 5晚，实际: #{nights}晚"
        end
      end
      
      # 断言9: 房间数和人数正确（1间房，2成人，1儿童） (8%)
      add_assertion "房间数和人数正确（1间房，2成人，1儿童）", weight: 8 do
        @hotel_bookings.each do |booking|
          expect(booking.rooms_count).to eq(1),
            "房间数错误。期望: 1间房，实际: #{booking.rooms_count}间房"
          expect(booking.adults_count).to eq(2),
            "成人数错误。期望: 2成人，实际: #{booking.adults_count}成人"
          expect(booking.children_count).to eq(1),
            "儿童数错误。期望: 1儿童，实际: #{booking.children_count}儿童"
        end
      end
      
      # 断言10: 联系人信息正确（刘强、陈静或小明） (12%)
      add_assertion "联系人信息正确（刘强、陈静或小明）", weight: 12 do
        # 验证机票订单联系人
        @flight_bookings.each do |booking|
          if booking.respond_to?(:contact_name) && booking.contact_name.present?
            expect(@expected_contact_names).to include(booking.contact_name),
              "机票联系人姓名错误。期望: #{@expected_contact_names.join('、')}, 实际: #{booking.contact_name}"
            expected_phone = @expected_contact_phones[booking.contact_name]
            if expected_phone
              expect(booking.contact_phone).to eq(expected_phone),
                "机票联系电话错误。期望: #{expected_phone}, 实际: #{booking.contact_phone}"
            end
          elsif booking.contact_phone.present?
            expect(@expected_contact_phones.values).to include(booking.contact_phone),
              "机票联系电话错误。期望: #{@expected_contact_phones.values.join('/')}, 实际: #{booking.contact_phone}"
          end
        end
        
        # 验证酒店订单联系人
        @hotel_bookings.each do |booking|
          expect(@expected_contact_names).to include(booking.guest_name),
            "住客姓名错误。期望: #{@expected_contact_names.join('、')}，实际: #{booking.guest_name}"
          expected_phone = @expected_contact_phones[booking.guest_name]
          if expected_phone
            expect(booking.guest_phone).to eq(expected_phone),
              "酒店联系电话错误。期望: #{expected_phone}，实际: #{booking.guest_phone}"
          end
        end
      end
      
      # 断言11: 订单状态和价格有效 (9%)
      add_assertion "订单状态和价格有效", weight: 9 do
        @flight_bookings.each do |booking|
          expect(['pending', 'paid', 'confirmed']).to include(booking.status),
            "机票订单状态无效。期望: pending/paid/confirmed，实际: #{booking.status}"
          expect(booking.total_price).to be > 0,
            "机票订单价格无效。期望: >0，实际: #{booking.total_price}"
        end
        
        @hotel_bookings.each do |booking|
          expect(['pending', 'paid', 'confirmed']).to include(booking.status),
            "酒店订单状态无效。期望: pending/paid/confirmed，实际: #{booking.status}"
          expect(booking.total_price).to be > 0,
            "酒店订单价格无效。期望: >0，实际: #{booking.total_price}"
        end
      end
    end

    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Randomly select one from the family as contact
      contact_passenger = [@liuqiang, @chenjing, @xiaoming].sample
      
      # 1. 创建往返机票订单
      booking = Booking.create!(
        user_id: user.id,
        flight_id: @outbound_flight.id,
        return_flight_id: @return_flight.id,
        trip_type: 'round_trip',
        return_date: @return_date,
        passenger_name: contact_passenger.name,
        passenger_id_number: contact_passenger.id_number,
        contact_phone: contact_passenger.phone,
        accept_terms: true,
        total_price: @outbound_flight.price + @return_flight.price,
        status: 'pending',
        data_version: @data_version  # ✅ Session-scoped
      )
      
      # 2. 创建亲子酒店订单
      nights = (@return_date - @departure_date).to_i
      base_price = @hotel_room.price * nights * 1
      hotel_booking = HotelBooking.create!(
        hotel_id: @hotel.id,
        hotel_room_id: @hotel_room.id,
        user_id: user.id,
        check_in_date: @departure_date,
        check_out_date: @return_date,
        guest_name: contact_passenger.name,
        guest_phone: contact_passenger.phone,
        rooms_count: 1,
        adults_count: 2,
        children_count: 1,
        payment_method: '花呗',
        total_price: base_price,
        status: 'pending',
        data_version: @data_version  # ✅ Session-scoped
      )
      
      {
        action: 'create_round_trip_and_hotel',
        booking_id: booking.id,
        hotel_booking_id: hotel_booking.id
      }
    end

    private

    def execution_state_data
      {
        departure_date: @departure_date&.to_s,
        return_date: @return_date&.to_s,
        departure_city: @departure_city,
        destination_city: @destination_city,
        hotel_name: @hotel_name,
        room_type: @room_type,
        outbound_flight_id: @outbound_flight&.id,
        return_flight_id: @return_flight&.id,
        hotel_id: @hotel&.id,
        expected_contact_names: @expected_contact_names,
        expected_contact_phones: @expected_contact_phones
      }
    end

    def restore_from_state(state)
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @return_date = Date.parse(state['return_date']) if state['return_date']
      @departure_city = state['departure_city']
      @destination_city = state['destination_city']
      @hotel_name = state['hotel_name']
      @room_type = state['room_type']
      @expected_contact_names = state['expected_contact_names']
      @expected_contact_phones = state['expected_contact_phones']
      @outbound_flight = Flight.find_by(id: state['outbound_flight_id']) if state['outbound_flight_id']
      @return_flight = Flight.find_by(id: state['return_flight_id']) if state['return_flight_id']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
    end
  end
end
