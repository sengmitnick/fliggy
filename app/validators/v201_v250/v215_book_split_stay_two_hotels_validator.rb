# frozen_string_literal: true

require_relative '../base_validator'

# V215: 预订分住两家酒店（5天分段）
#
# 任务描述:
#   用户需要预订北京5天行程，分住2家酒店（前2晚A酒店+后3晚B酒店）
#
# 评分标准:
#   - 创建了2个酒店订单 (25%)
#   - 两家酒店均位于北京 (10%)
#   - 第一家酒店住2晚 (15%)
#   - 第二家酒店住3晚 (15%)
#   - 两家酒店时间衔接正确（第一家退房日=第二家入住日） (15%)
#   - 订单状态有效 (20%)
module V201V250
  class V215BookSplitStayTwoHotelsValidator < BaseValidator
    self.validator_id = 'v215_book_split_stay_two_hotels_validator'
    self.task_id = '4ff576f9-5f5f-4f8f-ff8f-9f1a2b3c4d5f'
    self.title = '预订分住两家酒店（5天分段）'
    self.description = '用户需要预订北京5天行程，分住2家酒店（前2晚A酒店+后3晚B酒店）'
    self.timeout_seconds = 300
    
    def prepare
      @city = '北京'
      @start_date = Date.current + 1.day
      @first_hotel_nights = 2
      @second_hotel_nights = 3
      @switch_date = @start_date + @first_hotel_nights.days
      @end_date = @start_date + (@first_hotel_nights + @second_hotel_nights).days
      
      # 查找北京的酒店
      @available_hotels = Hotel.where(
        city: @city,
        data_version: 0
      ).to_a
      
      raise "未找到北京的酒店" if @available_hotels.empty?
      raise "酒店数量不足（需要至少2家）" if @available_hotels.size < 2
      
      {
        task: "请预订#{@city}5天行程，#{@start_date.strftime('%Y年%m月%d日')}（明天）入住，分住2家不同酒店：前2晚住一家，后3晚住另一家。",
        requirements: {
          city: @city,
          start_date: @start_date,
          first_hotel_nights: @first_hotel_nights,
          second_hotel_nights: @second_hotel_nights,
          switch_date: @switch_date,
          end_date: @end_date,
          purpose: '分段住宿体验不同酒店'
        },
        hint: "预订两家不同酒店，第一家住2晚，第二家住3晚，时间要衔接好。"
      }
    end
    
    def verify
      add_assertion "创建了2个酒店订单", weight: 25 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(check_in_date: :asc)
          .to_a
        
        expect(all_bookings.size).to be >= 2, "订单数量不足。期望至少2个酒店订单，实际: #{all_bookings.size}个"
        
        @first_booking = all_bookings[0]
        @second_booking = all_bookings[1]
      end
      
      return if @first_booking.nil? || @second_booking.nil?
      
      add_assertion "两家酒店均位于#{@city}", weight: 10 do
        expect(@first_booking.hotel.city).to eq(@city),
          "第一家酒店城市错误。期望: #{@city}, 实际: #{@first_booking.hotel.city}"
        expect(@second_booking.hotel.city).to eq(@city),
          "第二家酒店城市错误。期望: #{@city}, 实际: #{@second_booking.hotel.city}"
      end
      
      add_assertion "第一家酒店住#{@first_hotel_nights}晚", weight: 15 do
        actual_nights = (@first_booking.check_out_date - @first_booking.check_in_date).to_i
        expect(actual_nights).to eq(@first_hotel_nights),
          "第一家酒店住宿天数错误。期望: #{@first_hotel_nights}晚, 实际: #{actual_nights}晚"
      end
      
      add_assertion "第二家酒店住#{@second_hotel_nights}晚", weight: 15 do
        actual_nights = (@second_booking.check_out_date - @second_booking.check_in_date).to_i
        expect(actual_nights).to eq(@second_hotel_nights),
          "第二家酒店住宿天数错误。期望: #{@second_hotel_nights}晚, 实际: #{actual_nights}晚"
      end
      
      add_assertion "两家酒店时间衔接正确", weight: 15 do
        expect(@second_booking.check_in_date).to eq(@first_booking.check_out_date),
          "酒店时间衔接错误。第一家退房日: #{@first_booking.check_out_date}, 第二家入住日: #{@second_booking.check_in_date}"
      end
      
      add_assertion "订单状态有效", weight: 20 do
        expect(@first_booking.status).to be_in(['pending', 'paid', 'completed'])
        expect(@second_booking.status).to be_in(['pending', 'paid', 'completed'])
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择两家不同的酒店（过滤nil价格）
      valid_hotels = @available_hotels.select { |h| h.price_per_night.present? }
      raise "未找到足够的有效价格酒店" if valid_hotels.size < 2
      
      sorted_hotels = valid_hotels.sort_by(&:price_per_night)
      first_hotel = sorted_hotels[0]
      second_hotel = sorted_hotels[1]
      
      first_room = first_hotel.hotel_rooms.where(data_version: 0).where.not(price: nil).order(price: :asc).first
      second_room = second_hotel.hotel_rooms.where(data_version: 0).where.not(price: nil).order(price: :asc).first
      
      raise "未找到第一家酒店房间" unless first_room
      raise "未找到第二家酒店房间" unless second_room
      
      # 创建第一家酒店订单（2晚）
      HotelBooking.create!(
        user: user,
        hotel: first_hotel,
        hotel_room_id: first_room.id,
        check_in_date: @start_date,
        check_out_date: @switch_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        room_count: 1,
        total_price: first_room.price * @first_hotel_nights,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
      
      # 创建第二家酒店订单（3晚）
      HotelBooking.create!(
        user: user,
        hotel: second_hotel,
        hotel_room_id: second_room.id,
        check_in_date: @switch_date,
        check_out_date: @end_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        room_count: 1,
        total_price: second_room.price * @second_hotel_nights,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        start_date: @start_date.to_s,
        first_hotel_nights: @first_hotel_nights,
        second_hotel_nights: @second_hotel_nights,
        switch_date: @switch_date.to_s,
        end_date: @end_date.to_s
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @start_date = Date.parse(data['start_date'])
      @first_hotel_nights = data['first_hotel_nights']
      @second_hotel_nights = data['second_hotel_nights']
      @switch_date = Date.parse(data['switch_date'])
      @end_date = Date.parse(data['end_date'])
      
      @available_hotels = Hotel.where(
        city: @city,
        data_version: 0
      ).to_a
    end
  end
end
