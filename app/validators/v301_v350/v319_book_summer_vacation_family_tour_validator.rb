# frozen_string_literal: true

module V301V350
  class V319BookSummerVacationFamilyTourValidator < BaseValidator
    self.validator_id = 'v319_book_summer_vacation_family_tour_validator'
    self.task_id = "41296cec-e182-44c9-ac20-c2180e92c487"
    self.title = "预订15天后北京到三亚往返机票+三亚亚龙湾亲子度假酒店亲子家庭房（5晚，1间房，2大1小）"
    self.description = "用户需要预订15天后北京到三亚的往返机票，以及三亚亚龙湾亲子度假酒店亲子家庭房（入住5晚，2成人+1儿童，酒店入住日期与航班衔接）"
    self.timeout_seconds = 180

    def prepare
      # 15天后出发，5晚行程
      @departure_date = Date.today + 15.days
      @return_date = Date.today + 20.days
      @departure_city = "北京"
      @destination_city = "三亚"
      
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
      
      # 创建目的地
      city = City.find_by!(name: @destination_city, data_version: 0)
      destination = Destination.find_by!(
        name: @destination_city,
        data_version: 0
      )

      # 创建亲子酒店
      @hotel = Hotel.find_by!(
        name: "三亚亚龙湾亲子度假酒店",
        city: @destination_city,
        data_version: 0
      )

      @hotel_room = @hotel.hotel_rooms.find_by!(
        room_type: "亲子家庭房",
        data_version: 0
      )

      # 创建亲子活动景点
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
        task: "请预订#{@departure_date.strftime('%Y年%m月%d日')}（15天后）从北京到三亚的往返机票，以及三亚亚龙湾亲子度假酒店亲子家庭房（入住#{@departure_date.strftime('%m月%d日')}至#{@return_date.strftime('%m月%d日')}，共5晚，2成人+1儿童）。",
        requirements: {
          departure_city: '北京',
          destination_city: '三亚',
          departure_date: @departure_date,
          return_date: @return_date,
          nights: 5,
          hotel_name: '三亚亚龙湾亲子度假酒店',
          room_type: '亲子家庭房',
          adults: 2,
          children: 1
        },
        hint: "建议选择包含儿童设施的酒店，机票和酒店日期要衔接。"
      }
    end

    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = Passenger.find_by!(user: user, name: '张三', data_version: 0)
      
      # 2. 创建往返机票订单
      booking = Booking.create!(
        user_id: user.id,
        flight_id: @outbound_flight.id,
        return_flight_id: @return_flight.id,
        trip_type: 'round_trip',
        return_date: @return_date,
        passenger_name: passenger.name,
        passenger_id_number: passenger.id_number,
        contact_phone: passenger.phone,
        accept_terms: true,
        total_price: @outbound_flight.price + @return_flight.price,
        status: 'pending',
        data_version: @data_version
      )
      
      # 3. 创建亲子酒店订单
      nights = (@return_date - @departure_date).to_i
      base_price = @hotel_room.price * nights * 1
      hotel_booking = HotelBooking.create!(
        hotel_id: @hotel.id,
        hotel_room_id: @hotel_room.id,
        user_id: user.id,
        check_in_date: @departure_date,
        check_out_date: @return_date,
        guest_name: passenger.name,
        guest_phone: passenger.phone,
        rooms_count: 1,
        adults_count: 2,
        children_count: 1,
        payment_method: '花呗',
        total_price: base_price,
        status: 'pending',
        data_version: @data_version
      )
      
      {
        action: 'create_round_trip_and_hotel',
        booking_id: booking.id,
        hotel_booking_id: hotel_booking.id
      }
    end

    def verify
      add_assertion "创建了往返机票订单", weight: 20 do
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
        
        @flight_bookings = all_bookings.select { |b| 
          b.flight.departure_time.to_date == @departure_date &&
          b.return_flight.present?
        }
        
        expect(@flight_bookings.size).to be >= 1, "未找到符合条件的往返机票"
      end

      add_assertion "创建了亲子酒店订单", weight: 20 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where(hotels: { city: @destination_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_hotel_bookings).not_to be_empty, "未找到酒店订单"
        
        @hotel_bookings = all_hotel_bookings.select { |b| 
          b.check_in_date == @departure_date && 
          b.check_out_date == @return_date
        }
        
        expect(@hotel_bookings.size).to be >= 1, "未找到符合日期的酒店订单"
      end

      return if (@flight_bookings.nil? || @flight_bookings.empty?) && 
                (@hotel_bookings.nil? || @hotel_bookings.empty?)

      add_assertion "航班日期正确（15天后：#{@departure_date}出发）", weight: 15 do
        @flight_bookings&.each do |booking|
          actual_date = booking.flight.departure_time.to_date
          expect(actual_date).to eq(@departure_date),
            "出发日期错误。期望: #{@departure_date}（15天后），实际: #{actual_date}"
        end
      end

      add_assertion "返程日期正确（#{@return_date}）", weight: 10 do
        @flight_bookings&.each do |booking|
          if booking.return_flight
            actual_return = booking.return_flight.departure_time.to_date
            expect(actual_return).to eq(@return_date),
              "返程日期错误。期望: #{@return_date}, 实际: #{actual_return}"
          end
        end
      end

      add_assertion "酒店入住日期与航班衔接", weight: 10 do
        @hotel_bookings&.each do |booking|
          expect(booking.check_in_date).to eq(@departure_date),
            "入住日期应与出发日期一致"
          expect(booking.check_out_date).to eq(@return_date),
            "退房日期应与返程日期一致"
        end
      end
      
      add_assertion "房间数和人数正确（1间房，2成人，1儿童）", weight: 10 do
        @hotel_bookings&.each do |booking|
          expect(booking.rooms_count).to eq(1),
            "房间数错误。期望: 1间房，实际: #{booking.rooms_count}间房"
          expect(booking.adults_count).to eq(2),
            "成人数错误。期望: 2成人，实际: #{booking.adults_count}成人"
          expect(booking.children_count).to eq(1),
            "儿童数错误。期望: 1儿童，实际: #{booking.children_count}儿童"
        end
      end
      
      add_assertion "联系人信息正确（刘强/陈静/小明）", weight: 10 do
        expected_phones = [@liuqiang.phone, @chenjing.phone, @xiaoming.phone]
        expected_names = [@liuqiang.name, @chenjing.name, @xiaoming.name]
        
        @flight_bookings&.each do |booking|
          expect(booking.contact_phone).to be_in(expected_phones),
            "机票联系电话错误。期望: #{expected_phones.join('/')}，实际: #{booking.contact_phone}"
          expect(booking.passenger_name).to be_in(expected_names),
            "乘客姓名错误。期望: #{expected_names.join('/')}，实际: #{booking.passenger_name}"
        end
        
        @hotel_bookings&.each do |booking|
          expect(booking.guest_phone).to be_in(expected_phones),
            "酒店联系电话错误。期望: #{expected_phones.join('/')}，实际: #{booking.guest_phone}"
          expect(booking.guest_name).to be_in(expected_names),
            "住客姓名错误。期望: #{expected_names.join('/')}，实际: #{booking.guest_name}"
        end
      end

      add_assertion "选择了适合家庭的酒店或活动", weight: 5 do
        family_keywords = ['亲子', '家庭', '儿童']
        has_family_service = false
        
        @hotel_bookings&.each do |booking|
          hotel_name = booking.hotel.name
          room_type = booking.hotel_room&.room_type || ""
          facilities = booking.hotel.facilities || ""
          
          if family_keywords.any? { |kw| hotel_name.include?(kw) || room_type.include?(kw) || facilities.include?(kw) }
            has_family_service = true
          end
        end
        
        expect(has_family_service).to be(true), "未选择适合亲子游的酒店"
      end
    end

    def execution_state_data
      {
        departure_date: @departure_date&.to_s,
        return_date: @return_date&.to_s,
        departure_city: @departure_city,
        destination_city: @destination_city,
        outbound_flight_id: @outbound_flight&.id,
        return_flight_id: @return_flight&.id,
        hotel_id: @hotel&.id,
        liuqiang_name: @liuqiang&.name,
        liuqiang_phone: @liuqiang&.phone,
        chenjing_name: @chenjing&.name,
        chenjing_phone: @chenjing&.phone,
        xiaoming_name: @xiaoming&.name,
        xiaoming_phone: @xiaoming&.phone
      }
    end

    def restore_from_state(state)
      @departure_date = Date.parse(state['departure_date']) if state['departure_date']
      @return_date = Date.parse(state['return_date']) if state['return_date']
      @departure_city = state['departure_city']
      @destination_city = state['destination_city']
      @outbound_flight = Flight.find_by(id: state['outbound_flight_id']) if state['outbound_flight_id']
      @return_flight = Flight.find_by(id: state['return_flight_id']) if state['return_flight_id']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
      
      if state['liuqiang_name']
        @liuqiang = OpenStruct.new(name: state['liuqiang_name'], phone: state['liuqiang_phone'])
      end
      if state['chenjing_name']
        @chenjing = OpenStruct.new(name: state['chenjing_name'], phone: state['chenjing_phone'])
      end
      if state['xiaoming_name']
        @xiaoming = OpenStruct.new(name: state['xiaoming_name'], phone: state['xiaoming_phone'])
      end
    end
  end
end
