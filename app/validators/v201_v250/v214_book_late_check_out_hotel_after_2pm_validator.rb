# frozen_string_literal: true

require_relative '../base_validator'

# V214: 预订酒店延迟退房（14:00后）
#
# 任务描述:
#   用户需要预订深圳酒店2晚，配合晚班航班要求14:00后延迟退房
#
# 评分标准:
#   - 创建了酒店订单 (25%)
#   - 酒店位于深圳 (15%)
#   - 入住天数为2晚 (15%)
#   - 退房日期合理（入住日+2天） (25%)
#   - 订单状态有效 (20%)
module V201V250
  class V214BookLateCheckOutHotelAfter2pmValidator < BaseValidator
    self.validator_id = 'v214_book_late_check_out_hotel_after_2pm_validator'
    self.task_id = '3fe465f8-4f4f-4f7f-ff7f-8f0a1b2c3d4f'
    self.title = '预订酒店延迟退房（14:00后）'
    self.description = '用户需要预订深圳酒店2晚，配合晚班航班要求14:00后延迟退房'
    self.timeout_seconds = 300
    
    def prepare
      @city = '深圳'
      @check_in_date = Date.today + 1.day
      @nights = 2
      @check_out_date = @check_in_date + @nights.days
      
      # 查找深圳的酒店
      @available_hotels = Hotel.where(
        city: @city,
        data_version: 0
      ).to_a
      
      raise "未找到深圳的酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@city}酒店#{@nights}晚，入住日期#{@check_in_date.strftime('%Y年%m月%d日')}（明天），配合晚班航班需要14:00后延迟退房。",
        requirements: {
          city: @city,
          check_in_date: @check_in_date,
          nights: @nights,
          check_out_date: @check_out_date,
          purpose: '延迟退房配合晚班航班'
        },
        hint: "预订酒店2晚，退房日期应为入住日+2天。"
      }
    end
    
    def verify
      add_assertion "创建了酒店订单", weight: 25 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "酒店位于#{@city}", weight: 15 do
        expect(@hotel_booking.hotel.city).to eq(@city),
          "酒店城市错误。期望: #{@city}, 实际: #{@hotel_booking.hotel.city}"
      end
      
      add_assertion "入住天数为#{@nights}晚", weight: 15 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "入住天数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
      
      add_assertion "退房日期合理（入住日+#{@nights}天）", weight: 25 do
        expected_check_out = @hotel_booking.check_in_date + @nights.days
        expect(@hotel_booking.check_out_date).to eq(expected_check_out),
          "退房日期错误。期望: #{expected_check_out}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择价格合理的酒店（过滤nil价格）
      valid_hotels = @available_hotels.select { |h| h.price_per_night.present? }
      raise "未找到有效价格的酒店" if valid_hotels.empty?
      
      hotel = valid_hotels.min_by(&:price_per_night)
      room = hotel.hotel_rooms.where(data_version: 0).where.not(price: nil).order(price: :asc).first
      raise "未找到酒店房间" unless room
      
      # 创建酒店订单（2晚）
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        room_count: 1,
        total_price: room.price * @nights,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date.to_s,
        nights: @nights,
        check_out_date: @check_out_date.to_s
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @nights = data['nights']
      @check_out_date = Date.parse(data['check_out_date'])
      
      @available_hotels = Hotel.where(
        city: @city,
        data_version: 0
      ).to_a
    end
  end
end
