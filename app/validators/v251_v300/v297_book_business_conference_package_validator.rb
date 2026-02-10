# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例297: 给李四预订北京商务出行套餐（机票+酒店）
#
# 任务描述:
#   李四需要商务出行去北京，预订商务舱机票和商务酒店，住3晚
#
# 评分标准:
#   - 创建机票订单 (25%)
#   - 创建酒店预订 (25%)
#   - 选择商务舱或高星酒店 (15%)
#   - 入住日期与航班日期匹配 (10%)
#   - 入住人信息正确（李四）(15%)
#   - 住宿天数≥2晚 (5%)
#   - 订单状态正确 (5%)
module V251V300
  class V297BookBusinessConferencePackageValidator < BaseValidator
    self.validator_id = 'v297_book_business_conference_package_validator'
    self.task_id = 'e83b5fa7-c5d9-41e8-a0cd-f1435c06ce7b'
    self.title = '给李四预订北京商务出行套餐（5天后，商务舱机票+酒店）'
    self.description = '李四要去北京商务出行，订商务舱机票和商务型酒店，住3晚'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '上海'
      @arrival_city = '北京'
      @departure_date = Date.current + 5.days
      @check_in_date = @departure_date
      @check_out_date = @check_in_date + 3.days  # 3晚
      @nights = (@check_out_date - @check_in_date).to_i
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 5000
        user.update!(balance: 8000)
      end
      
      # Pre-query passenger info
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_contact_name = @lisi.name
      @expected_contact_phone = @lisi.phone
      
      {
        task: "请预订#{@departure_date.strftime('%Y年%-m月%-d日')}从#{@departure_city}到#{@arrival_city}的商务出行套餐，需要商务舱机票和商务型酒店，住#{@nights}晚",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        departure_date: @departure_date.to_s,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        hint: "选择商务舱机票和商务型酒店"
      }
    end
    
    def verify
      add_assertion "创建了机票订单", weight: 25 do
        @flight_booking = Booking
          .joins(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@flight_booking).not_to be_nil, "未找到#{@departure_city}到#{@arrival_city}的机票订单"
      end
      
      add_assertion "创建了酒店预订", weight: 25 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@arrival_city}的酒店预订"
      end
      
      return unless @flight_booking && @hotel_booking
      
      add_assertion "选择商务舱或高星酒店", weight: 15 do
        flight_offer = FlightOffer.find_by(id: @flight_booking.flight_offer_id)
        hotel = @hotel_booking.hotel
        
        is_business_class = flight_offer&.seat_class == 'business'
        is_high_end_hotel = hotel.price >= 400 || hotel.rating >= 4.5
        
        expect(is_business_class || is_high_end_hotel).to be(true),
          "未选择商务舱或高星酒店。机票舱位: #{flight_offer&.seat_class}, 酒店价格: ¥#{hotel.price}, 评分: #{hotel.rating}"
      end
      
      add_assertion "入住日期与航班日期匹配", weight: 10 do
        flight_date = @flight_booking.flight.departure_time.to_date
        expect(@hotel_booking.check_in_date).to eq(flight_date),
          "入住日期与航班日期不匹配。航班日期: #{flight_date}, 入住日期: #{@hotel_booking.check_in_date}"
      end
      
      add_assertion "入住人信息正确（李四）", weight: 15 do
        expect(@hotel_booking.guest_name).to eq(@expected_contact_name),
          "入住人姓名错误。期望: #{@expected_contact_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_contact_phone),
          "入住人电话错误。期望: #{@expected_contact_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "住宿天数≥2晚", weight: 5 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to be >= 2,
          "住宿天数不足。期望≥2晚，实际: #{actual_nights}晚"
      end
      
      add_assertion "订单状态正确", weight: 5 do
        valid_statuses = ['pending', 'paid', 'confirmed']
        expect(valid_statuses).to include(@flight_booking.status),
          "机票订单状态错误: #{@flight_booking.status}"
        expect(valid_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 1. 预订机票（优先商务舱，如无则经济舱）
      flight_offer = FlightOffer
        .joins(:flight)
        .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
        .merge(Flight.by_date(@departure_date))
        .where(data_version: 0)
        .order(Arel.sql("CASE WHEN flight_offers.seat_class = 'business' THEN 0 ELSE 1 END"), price: :asc)
        .first!
      
      Booking.create!(
        user_id: user.id,
        flight_id: flight_offer.flight_id,
        flight_offer_id: flight_offer.id,
        passenger_name: @lisi.name,
        passenger_id_number: @lisi.id_number,
        contact_phone: @lisi.phone,
        total_price: flight_offer.price,
        accept_terms: true,
        status: 'pending',
        data_version: @data_version
      )
      
      # 2. 预订商务型酒店
      hotel = Hotel
        .where(city: @arrival_city, data_version: 0)
        .where("price >= ? OR rating >= ?", 400, 4.5)
        .order(rating: :desc)
        .first!
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @lisi.name,
        guest_phone: @lisi.phone,
        payment_method: '花呗',
        total_price: hotel.price * @nights,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        departure_date: @departure_date&.to_s,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        nights: @nights,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @departure_date = Date.parse(data['departure_date']) if data['departure_date']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @nights = data['nights']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
    end
  end
end
