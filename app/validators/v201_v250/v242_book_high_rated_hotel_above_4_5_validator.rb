# frozen_string_literal: true

require_relative '../base_validator'

# V242: 预订高评分酒店（评分≥4.5）
#
# 任务描述:
#   用户需要预订评分≥4.5分的酒店
#
# 评分标准:
#   - 创建了酒店订单 (20%)
#   - 城市正确（上海） (10%)
#   - 酒店评分≥4.5分 (35%)
#   - 入住日期正确（后天） (15%)
#   - 入住人信息正确 (10%)
#   - 订单状态有效 (10%)
module V201V250
  class V242BookHighRatedHotelAbove45Validator < BaseValidator
    self.validator_id = 'v242_book_high_rated_hotel_above_4_5_validator'
    self.task_id = 'b78a026e-5d5b-4128-a9bb-f78820f0bb2c'
    self.title = '张三后天要去上海出差，注重住宿品质，需要预订评分至少4.5星的高品质酒店住1晚'
    self.description = '张三后天要去上海出差，注重住宿品质，需要预订评分至少4.5星的高品质酒店住1晚'
    self.timeout_seconds = 300
    
    def prepare
      @city = '上海'
      @check_in_date = Date.current + 2.days
      @check_out_date = @check_in_date + 1.day
      @min_rating = 4.5
      
      # 查询demo_user乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_name = user.name
      @expected_guest_phone = @passenger.phone
      
      # 查找高评分酒店
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where('rating >= ?', @min_rating)
        .order(rating: :desc, price: :asc)
      
      raise "未找到符合条件的高评分酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@check_in_date.strftime('%Y年%m月%d日')}（后天）在#{@city}的酒店（住1晚），要求酒店评分≥#{@min_rating}分，选择高评分、服务质量好的酒店。",
        requirements: {
          city: @city,
          check_in_date: @check_in_date,
          nights: 1,
          min_rating: @min_rating
        },
        hint: "优先选择评分≥#{@min_rating}分的酒店，评分越高说明服务质量越好。"
      }
    end
    
    def verify
      add_assertion "创建了酒店订单", weight: 20 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到酒店订单"
        @booking = all_bookings.first
      end
      
      return if @booking.nil?
      
      add_assertion "城市正确（#{@city}）", weight: 10 do
        expect(@booking.hotel.city).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@booking.hotel.city}"
      end
      
      add_assertion "酒店评分≥#{@min_rating}分", weight: 35 do
        rating = @booking.hotel.rating
        expect(rating).to be >= @min_rating,
          "酒店评分不符合要求。期望: ≥#{@min_rating}分, 实际: #{rating}分, 酒店名称: #{@booking.hotel.name}"
      end
      
      add_assertion "入住日期正确（#{@check_in_date}，后天）", weight: 15 do
        expect(@booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（后天）, 实际: #{@booking.check_in_date}"
        expect(@booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@booking.check_out_date}"
      end
      
      add_assertion "入住人信息正确", weight: 10 do
        expect(@booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}, 实际: #{@booking.guest_name}"
        expect(@booking.guest_phone).to eq(@expected_guest_phone),
          "联系电话错误。期望: #{@expected_guest_phone}, 实际: #{@booking.guest_phone}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择评分最高且价格合理的酒店
      hotel = @available_hotels.first
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: user.name,
        guest_phone: passenger.phone,
        payment_method: '花呗',
        total_price: room.price,
        status: 'paid',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        min_rating: @min_rating
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @min_rating = data['min_rating']
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where('rating >= ?', @min_rating)
        .order(rating: :desc, price: :asc)
    end
  end
end
