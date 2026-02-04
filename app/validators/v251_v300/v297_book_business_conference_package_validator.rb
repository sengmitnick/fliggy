# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例297: 预订商务会议套餐
#
# 任务描述:
#   用户预订商务会议套餐(会议室+住宿+餐饮)
#
# 评分标准:
#   - 创建酒店预订 (40%)
#   - 选择商务型酒店(含会议设施) (25%)
#   - 入住日期与会议时间匹配 (15%)
#   - 住宿天数≥2晚(多日会议) (10%)
#   - 订单状态正确 (10%)
module V251V300
  class V297BookBusinessConferencePackageValidator < BaseValidator
    self.validator_id = 'v297_book_business_conference_package_validator'
    self.task_id = 'e83b5fa7-c5d9-41e8-a0cd-f1435c06ce7b'
    self.title = '预订商务会议套餐'
    self.description = '用户预订商务会议套餐(会议室+住宿+餐饮)'
    self.timeout_seconds = 300
    
    def prepare
      @city = '北京'
      @check_in_date = Date.today + 5.days
      @check_out_date = @check_in_date + 3.days  # 3晚
      @nights = (@check_out_date - @check_in_date).to_i
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      if user.balance < 5000
        user.update!(balance: 8000)
      end
      
      {
        task: "请预订#{@city}的商务会议套餐，需要在#{@check_in_date.strftime('%Y年%-m月%-d日')}入住，住#{@nights}晚，需要配备会议室和商务设施的酒店，用于举办企业会议",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        hint: "选择商务型酒店，注意会议设施"
      }
    end
    
    def verify
      add_assertion "创建了酒店预订", weight: 40 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店预订"
      end
      
      return unless @hotel_booking
      
      add_assertion "选择商务型酒店(含会议设施)", weight: 25 do
        hotel = @hotel_booking.hotel
        # 商务型酒店通常评分高、价格适中、位置好
        is_business_hotel = hotel.price >= 400 || hotel.rating >= 4.5
        expect(is_business_hotel).to be(true),
          "未选择商务型酒店。当前酒店: #{hotel.name}, 价格: ¥#{hotel.price}, 评分: #{hotel.rating}"
      end
      
      add_assertion "入住日期与会议时间匹配", weight: 15 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
      end
      
      add_assertion "住宿天数≥2晚(多日会议)", weight: 10 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to be >= 2,
          "住宿天数不足。期望≥2晚，实际: #{actual_nights}晚"
      end
      
      add_assertion "订单状态正确", weight: 10 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@hotel_booking.status),
          "订单状态错误: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择商务型酒店(价格较高或评分高)
      hotel = Hotel
        .where(city: @city, data_version: 0)
        .where("price >= ? OR rating >= ?", 400, 4.5)
        .order(rating: :desc)
        .first!
      
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 2,  # 商务会议预订多间
        adults_count: 2,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name || '王经理',
        guest_phone: user.phone || '13800138000',
        payment_method: '花呗',
        total_price: hotel.price * @nights * 2,
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
        nights: @nights
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @nights = data['nights']
    end
  end
end
