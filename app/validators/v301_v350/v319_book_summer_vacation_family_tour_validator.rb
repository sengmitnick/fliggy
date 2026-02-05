# frozen_string_literal: true

module V301V350
  class V319BookSummerVacationFamilyTourValidator < BaseValidator
    self.validator_id = 'v319_book_summer_vacation_family_tour_validator'
    self.task_id = "41296cec-e182-44c9-ac20-c2180e92c487"
    self.title = "暑期亲子游高峰期预订（7-8月）"
    self.description = "用户需要预订暑期（7月中旬）北京到三亚的亲子游套餐，包含机票+酒店+亲子活动"
    self.timeout_seconds = 180

    def prepare
      # 暑期时间：7月15日出发，7月20日返回
      current_year = Date.today.year
      @departure_date = Date.new(current_year, 7, 15)
      if @departure_date < Date.today
        @departure_date = Date.new(current_year + 1, 7, 15)
      end
      @return_date = @departure_date + 5.days
      @departure_city = "北京"
      @destination_city = "三亚"
      
      # 创建目的地
      city = City.find_by!(name: @destination_city, data_version: 0)
      destination = Destination.find_by!(
        name: @destination_city,
        data_version: 0
      )

      # 创建航班（不匹配精确时间，避免时区问题）
      @outbound_flight = Flight.where(
        flight_number: "CA1357",
        departure_city: @departure_city,
        destination_city: @destination_city,
        data_version: 0
      ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @departure_date)
       .first!

      @return_flight = Flight.where(
        flight_number: "CA1358",
        departure_city: @destination_city,
        destination_city: @departure_city,
        data_version: 0
      ).where("DATE(departure_time AT TIME ZONE 'UTC' AT TIME ZONE 'Asia/Shanghai') = ?", @return_date)
       .first!

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
        departure_date: @departure_date.to_s,
        return_date: @return_date.to_s,
        departure_city: @departure_city,
        destination_city: @destination_city,
        hotel_name: @hotel.name,
        task_info: "用户预订暑期亲子游套餐"
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
      add_assertion "创建了往返机票订单", weight: 25 do
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

      add_assertion "创建了亲子酒店订单", weight: 25 do
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

      add_assertion "航班日期正确（暑期：#{@departure_date}出发）", weight: 15 do
        @flight_bookings&.each do |booking|
          actual_date = booking.flight.departure_time.to_date
          expect(actual_date).to eq(@departure_date),
            "出发日期错误。期望: #{@departure_date}（暑期高峰），实际: #{actual_date}"
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

      add_assertion "酒店入住日期与航班衔接", weight: 15 do
        @hotel_bookings&.each do |booking|
          expect(booking.check_in_date).to eq(@departure_date),
            "入住日期应与出发日期一致"
          expect(booking.check_out_date).to eq(@return_date),
            "退房日期应与返程日期一致"
        end
      end

      add_assertion "选择了适合家庭的酒店或活动", weight: 10 do
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
        hotel_id: @hotel&.id
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
    end
  end
end
