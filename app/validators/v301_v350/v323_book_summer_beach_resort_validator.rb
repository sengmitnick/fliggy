# frozen_string_literal: true

module V301V350
  class V323BookSummerBeachResortValidator < BaseValidator
    self.validator_id = 323
    self.task_id = "g7h8i9j0-1k2l-3m4n-5o6p-7q8r9s0t1u2v"
    self.title = "夏季避暑游（海滨/高山避暑）"
    self.description = "用户需要预订夏季（7-8月）青岛海滨避暑，包含海滨酒店+海滩活动"
    self.timeout_seconds = 180

    def prepare
      # 夏季避暑：7月20日
      current_year = Date.today.year
      @check_in_date = Date.new(current_year, 7, 20)
      if @check_in_date < Date.today
        @check_in_date = Date.new(current_year + 1, 7, 20)
      end
      @check_out_date = @check_in_date + 3.days
      @visit_date = @check_in_date + 1.day
      @city_name = "青岛"
      @beach_name = "金沙滩海水浴场"
      
      # 创建城市
      city = City.find_by!(name: @city_name, data_version: 0)
      destination = Destination.find_by!(
        name: @city_name,
        data_version: 0
      )

      # 创建海滩景点
      @attraction = Attraction.find_by!(
        name: @beach_name,
        city: city,
        data_version: 0
      )

      # 创建海滩活动
      @beach_activity = @attraction.attraction_activities.find_by!(
        name: "海上摩托艇体验",
        data_version: 0
      )

      # 创建海景酒店
      @hotel = Hotel.find_by!(
        name: "青岛金沙滩海景度假酒店",
        city: city,
        destination: destination,
        data_version: 0
      )

      @hotel_room = @hotel.hotel_rooms.find_by!(
        room_type: "海景大床房",
        data_version: 0
      )

      {
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        visit_date: @visit_date.to_s,
        city_name: @city_name,
        beach_name: @beach_name,
        task_info: "用户预订夏季海滨避暑游"
      }
    end

    def simulate
      # 1. 查找测试用户
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 2. 创建海滨酒店订单
      hotel_booking = HotelBooking.create!(
        hotel_id: @hotel.id,
        hotel_room_id: @hotel_room.id,
        user_id: user.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: '张三',
        guest_phone: '13800138000',
        rooms_count: 1,
        adults_count: 2,
        children_count: 0,
        payment_method: '花呗',
        status: 'pending',
        data_version: @data_version
      )
      hotel_booking.calculate_total_price
      hotel_booking.save!
      
      {
        action: 'create_beach_resort_hotel',
        hotel_booking_id: hotel_booking.id
      }
    end

    def verify
      add_assertion "创建了海滨酒店订单", weight: 35 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :room)
          .where(hotels: { city_id: City.find_by(name: @city_name, data_version: 0)&.id })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_hotel_bookings).not_to be_empty, "未找到酒店订单"
        
        @hotel_bookings = all_hotel_bookings.select { |b| 
          b.check_in_date == @check_in_date
        }
        
        expect(@hotel_bookings.size).to be >= 1, "未找到符合日期的酒店订单"
      end

      return if @hotel_bookings.nil? || @hotel_bookings.empty?

      add_assertion "酒店位置正确（#{@city_name}海滨）", weight: 15 do
        @hotel_bookings.each do |booking|
          expect(booking.hotel.city.name).to eq(@city_name),
            "酒店城市错误。期望: #{@city_name}, 实际: #{booking.hotel.city.name}"
        end
      end

      add_assertion "入住日期正确（夏季避暑：#{@check_in_date}）", weight: 15 do
        @hotel_bookings.each do |booking|
          actual_date = booking.check_in_date
          # 允许7-8月的任何日期
          expected_month = @check_in_date.month
          actual_month = actual_date.month
          
          if expected_month.in?([7, 8])
            expect(actual_month).to be_in([7, 8]),
              "入住日期应在夏季避暑季（7-8月）。实际: #{actual_date}"
          else
            expect(actual_date).to eq(@check_in_date),
              "入住日期错误。期望: #{@check_in_date}（夏季避暑），实际: #{actual_date}"
          end
        end
      end

      add_assertion "选择了海滨避暑酒店", weight: 20 do
        beach_keywords = ['海景', '海滨', '沙滩', '海边', '度假']
        has_beach_hotel = false
        
        @hotel_bookings.each do |booking|
          hotel_name = booking.hotel.name
          hotel_desc = booking.hotel.description || ""
          hotel_amenities = booking.hotel.amenities || ""
          room_type = booking.room&.room_type || ""
          
          combined_text = "#{hotel_name} #{hotel_desc} #{hotel_amenities} #{room_type}"
          
          if beach_keywords.any? { |kw| combined_text.include?(kw) }
            has_beach_hotel = true
          end
        end
        
        expect(has_beach_hotel).to be(true), "未选择海滨避暑主题酒店"
      end

      add_assertion "入住时长合理（2-4晚）", weight: 15 do
        @hotel_bookings.each do |booking|
          nights = (booking.check_out_date - booking.check_in_date).to_i
          expect(nights).to be_between(2, 4),
            "避暑游入住时长不合理。期望: 2-4晚，实际: #{nights}晚"
        end
      end
    end

    def execution_state_data
      {
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        visit_date: @visit_date&.to_s,
        city_name: @city_name,
        beach_name: @beach_name,
        hotel_id: @hotel&.id,
        attraction_id: @attraction&.id
      }
    end

    def restore_from_state(state)
      @check_in_date = Date.parse(state['check_in_date']) if state['check_in_date']
      @check_out_date = Date.parse(state['check_out_date']) if state['check_out_date']
      @visit_date = Date.parse(state['visit_date']) if state['visit_date']
      @city_name = state['city_name']
      @beach_name = state['beach_name']
      @hotel = Hotel.find_by(id: state['hotel_id']) if state['hotel_id']
      @attraction = Attraction.find_by(id: state['attraction_id']) if state['attraction_id']
    end
  end
end
