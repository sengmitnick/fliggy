# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例304: 给刘强和陈静预订杭州养生度假酒店
#
# 任务描述:
#   刘强和陈静想预订杭州的养生度假，需要温泉、SPA服务和高端养生酒店
#
# 评分标准:
#   - 创建了酒店预订 (25%)
#   - 酒店城市正确（杭州） (10%)
#   - 选择高评分养生酒店 (25%)
#   - 入住日期正确 (10%)
#   - 住客信息正确（刘强） (10%)
#   - 住宿天数≥3晚 (5%)
#   - 房间数和人数正确 (15%)
module V301V350
  class V304BookWellnessResortTourValidator < BaseValidator
    self.validator_id = 'v304_book_wellness_resort_tour_validator'
    self.task_id = 'd4804253-c7b6-42bc-a79b-2035d534f476'
    self.title = '给刘强和陈静预订杭州养生度假酒店（8天后，≥3晚，含温泉SPA）'
    self.description = '刘强和陈静想订杭州的养生度假，要温泉、SPA服务和高端养生酒店'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @check_in_date = Date.current + 8.days
      @check_out_date = @check_in_date + 4.days  # 4晚
      @visit_date = @check_in_date + 1.day
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 6000
        user.update!(balance: 9000)
      end
      
      # Pre-query passenger info - couple
      @liuqiang = user.passengers.find_by!(name: '刘强', data_version: 0)
      @chenjing = user.passengers.find_by!(name: '陈静', data_version: 0)
      @expected_guest_name = @liuqiang.name  # Primary guest
      @expected_guest_phone = @liuqiang.phone
      
      {
        task: "请为刘强和陈静预订#{@city}的养生度假，#{@check_in_date.strftime('%Y年%-m月%-d日')}入住，住#{(@check_out_date - @check_in_date).to_i}晚，需要高端养生酒店",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        passengers: '刘强、陈静',
        hint: "选择高评分的养生度假酒店（评分≥4.5或价格≥600），2成人入住，联系人使用demo_user的出行人刘强"
      }
    end
    
    def verify
      add_assertion "创建了酒店预订", weight: 25 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到酒店预订"
      end
      
      return unless @hotel_booking
      
      add_assertion "酒店城市正确（#{@city}）", weight: 10 do
        expect(@hotel_booking.hotel.city).to eq(@city),
          "酒店城市错误。期望: #{@city}，实际: #{@hotel_booking.hotel.city}"
      end
      
      add_assertion "选择高评分养生酒店", weight: 25 do
        hotel = @hotel_booking.hotel
        # 养生酒店通常评分高、价格适中
        is_wellness_hotel = hotel.rating >= 4.5 || hotel.price >= 600
        expect(is_wellness_hotel).to be(true),
          "未选择高评分养生酒店。当前酒店: #{hotel.name}, 评分: #{hotel.rating}, 价格: ¥#{hotel.price}"
      end
      
      add_assertion "入住日期正确", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（8天后），实际: #{@hotel_booking.check_in_date}"
      end
      
      add_assertion "住客信息正确（刘强）", weight: 10 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "住客姓名错误。期望: #{@expected_guest_name}（刘强），实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_guest_phone),
          "联系电话错误。期望: #{@expected_guest_phone}，实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "住宿天数≥3晚", weight: 5 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to be >= 3,
          "住宿天数不足。期望≥3晚，实际: #{actual_nights}晚"
      end
      
      add_assertion "房间数和人数正确（1间房，2成人，0儿童）", weight: 15 do
        expect(@hotel_booking.rooms_count).to eq(1),
          "房间数错误。期望: 1间房，实际: #{@hotel_booking.rooms_count}间房"
        expect(@hotel_booking.adults_count).to eq(2),
          "成人数错误。期望: 2成人，实际: #{@hotel_booking.adults_count}成人"
        expect(@hotel_booking.children_count).to eq(0),
          "儿童数错误。期望: 0儿童，实际: #{@hotel_booking.children_count}儿童"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择高评分养生酒店
      hotel = Hotel
        .where(city: @city, data_version: 0)
        .where("rating >= ? OR price >= ?", 4.5, 600)
        .order(rating: :desc, price: :desc)
        .first!
      
      # Use existing passenger from demo_user
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 2,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @liuqiang.name,
        guest_phone: @liuqiang.phone,
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
        visit_date: @visit_date&.to_s,
        expected_guest_name: @expected_guest_name,
        expected_guest_phone: @expected_guest_phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @visit_date = Date.parse(data['visit_date']) if data['visit_date']
      @expected_guest_name = data['expected_guest_name']
      @expected_guest_phone = data['expected_guest_phone']
    end
  end
end
