# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例301: 给李四预订深圳运动健身度假酒店
#
# 任务描述:
#   李四是健身爱好者，想预订深圳的运动健身度假，需要配备健身房、游泳池等运动设施
#
# 评分标准:
#   - 创建酒店预订(含健身设施) (35%) - 必须在深圳
#   - 选择配备健身房的酒店 (35%) - facilities字段包含健身/泳池/运动关键词
#   - 入住日期正确 (10%) - 必须是今天+6天
#   - 住客信息正确 (10%) - guest_name和guest_phone必须是李四
#   - 住宿天数≥3晚 (5%) - 实际要求4晚
#   - 房间数和人数正确 (5%) - 1间房，1成人，0儿童
module V301V350
  class V301BookSportsFitnessTourValidator < BaseValidator
    self.validator_id = 'v301_book_sports_fitness_tour_validator'
    self.task_id = 'c0e90a56-cd9b-4ef3-8486-8bc3e076e331'
    self.title = '给李四预订深圳运动健身度假酒店（6天后，4晚）'
    self.description = '李四是健身爱好者，想订深圳的运动健身度假，要健身房和游泳池'
    self.timeout_seconds = 300
    
    def prepare
      @city = '深圳'
      @check_in_date = Date.current + 6.days
      @check_out_date = @check_in_date + 4.days  # 4晚
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 5000
        user.update!(balance: 7000)
      end
      
      # Pre-query passenger info
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_guest_name = @lisi.name
      @expected_guest_phone = @lisi.phone
      
      {
        task: "请预订#{@city}的运动健身度假，#{@check_in_date.strftime('%Y年%-m月%-d日')}入住，住#{(@check_out_date - @check_in_date).to_i}晚，需要配备健身房和运动设施的酒店，适合健身爱好者",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        hint: "选择配备健身房和泳池的酒店"
      }
    end
    
    def verify
      add_assertion "创建了酒店预订(含健身设施)", weight: 35 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店预订"
      end
      
      return unless @hotel_booking
      
      add_assertion "选择配备健身房的酒店", weight: 35 do
        hotel = @hotel_booking.hotel
        # 健身设施：健身房、游泳池等
        has_fitness = hotel.facilities.to_s.match?(/健身|游泳池|泳池|运动/i)
        expect(has_fitness).to be(true),
          "酒店未配备健身设施。当前设施: #{hotel.facilities}"
      end
      
      add_assertion "入住日期正确", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
      end
      
      add_assertion "住客信息正确（李四）", weight: 10 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "住客姓名错误。期望: #{@expected_guest_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_guest_phone),
          "联系电话错误。期望: #{@expected_guest_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "住宿天数≥3晚", weight: 5 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to be >= 3,
          "住宿天数不足。期望≥3晚，实际: #{actual_nights}晚"
      end
      
      add_assertion "房间数和人数正确（1间房，1成人，0儿童）", weight: 5 do
        expect(@hotel_booking.rooms_count).to eq(1),
          "房间数错误。期望: 1间房，实际: #{@hotel_booking.rooms_count}间房"
        expect(@hotel_booking.adults_count).to eq(1),
          "成人数错误。期望: 1成人，实际: #{@hotel_booking.adults_count}成人"
        expect(@hotel_booking.children_count).to eq(0),
          "儿童数错误。期望: 0儿童，实际: #{@hotel_booking.children_count}儿童"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择配备健身设施的酒店
      hotel = Hotel
        .where(city: @city, data_version: 0)
        .order(rating: :desc)
        .first!
      
      # Use existing passenger from demo_user
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
        total_price: hotel.price * (@check_out_date - @check_in_date).to_i,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        expected_guest_name: @expected_guest_name,
        expected_guest_phone: @expected_guest_phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @expected_guest_name = data['expected_guest_name']
      @expected_guest_phone = data['expected_guest_phone']
    end
  end
end
