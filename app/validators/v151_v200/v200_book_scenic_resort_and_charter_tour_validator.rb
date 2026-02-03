# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例200: 预订景区内酒店+包车游览
#
# 任务描述:
#   预订景区内酒店+包车游览服务
#
# 评分标准:
#   - 创建了酒店订单 (30%)
#   - 创建了包车订单 (30%)
#   - 酒店类型正确（景区/度假村） (20%)
#   - 包车时间合理（游览期间） (15%)
#   - 价格合理 (5%)
module V151V200
  class V200BookScenicResortAndCharterTourValidator < BaseValidator
    self.validator_id = 'v200_book_scenic_resort_and_charter_tour_validator'
    self.task_id = '1c8e72f9-d895-4e13-9e5d-912749a6b8c5'
    self.title = '预订景区内酒店+包车游览'
    self.description = '预订景区内酒店+包车游览服务'
    self.timeout_seconds = 300
    
    def prepare
      @city = '上海'
      @check_in_date = Date.tomorrow + 3.days
      @rental_days = 1
      
      # 查找酒店（不限制景区型）
      @available_hotels = Hotel
        .where(city: @city, data_version: 0)
        .order(price: :desc)
        .to_a
      
      expect(@available_hotels).not_to be_empty,
        "数据包缺少#{@city}的酒店"
      
      # 查找包车/租车服务
      @available_cars = Car
        .where(is_available: true, data_version: 0)
        .limit(10)
        .to_a
      
      expect(@available_cars).not_to be_empty,
        "数据包缺少包车/租车服务"
      
      {
        task: "请预订#{@check_in_date.strftime('%m月%d日')}#{@city}景区内的酒店，并预订包车游览服务（#{@rental_days}天）",
        city: @city,
        check_in_date: @check_in_date.strftime('%Y-%m-%d'),
        rental_days: @rental_days,
        hint: "选择景区内的度假酒店，提供包车游览服务"
      }
    end
    
    def verify
      # 断言1: 创建了酒店订单 (30%)
      add_assertion "创建了酒店订单", weight: 30 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单（#{@city}）"
      end
      
      # 断言2: 创建了包车订单 (30%)
      add_assertion "创建了包车订单", weight: 30 do
        @car_order = CarOrder
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@car_order).not_to be_nil, "未找到包车订单"
      end
      
      return if @hotel_booking.nil? || @car_order.nil?
      
      # 断言3: 酒店类型正确（景区/度假村） (20%)
      add_assertion "酒店类型正确（景区/度假村）", weight: 20 do
        hotel = @hotel_booking.hotel
        # 高星级酒店认为是度假型
        is_scenic = hotel.star_level.to_i >= 4
        
        expect(is_scenic).to be(true),
          "酒店不是景区型。酒店: #{hotel.name}（星级: #{hotel.star_level}）"
      end
      
      # 断言4: 包车时间合理（游览期间） (15%)
      add_assertion "包车时间合理（游览期间）", weight: 15 do
        checkin_date = @hotel_booking.check_in_date
        checkout_date = @hotel_booking.check_out_date
        pickup_date = @car_order.pickup_datetime.to_date
        return_date = @car_order.return_datetime.to_date
        
        # 取车日期应在入住期间
        expect(pickup_date).to be >= checkin_date
        expect(pickup_date).to be <= checkout_date
        
        # 还车日期应在入住期间或退房当天
        expect(return_date).to be <= checkout_date
      end
      
      # 断言5: 价格合理 (5%)
      add_assertion "价格合理", weight: 5 do
        rental_days = (@car_order.return_datetime.to_date - @car_order.pickup_datetime.to_date).to_i
        car = @car_order.car
        expected_price = car.price_per_day * rental_days
        
        # 允许10%误差（可能有优惠或服务费）
        expect(@car_order.total_price).to be >= expected_price * 0.9
        expect(@car_order.total_price).to be <= expected_price * 1.1
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建酒店订单（选择价格较高的酒店，表示度假型）
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      unless room
        room = HotelRoom.create!(
          hotel_id: hotel.id,
          room_type: '度假大床房',
          bed_type: 'king',
          price: hotel.price,
          original_price: hotel.original_price,
          area: 35.0,
          max_guests: 2,
          has_window: true,
          available_rooms: 10,
          room_category: 'deluxe',
          data_version: 0
        )
      end
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @check_in_date,
        check_out_date: @check_in_date + 2.days,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: room.price * 2,
        data_version: @data_version
      )
      
      # 创建包车订单
      car = @available_cars.min_by(&:price_per_day)
      pickup_datetime = @check_in_date.to_time + 9.hours  # 入住当天早上9点
      return_datetime = pickup_datetime + @rental_days.days
      
      CarOrder.create!(
        user: user,
        car_id: car.id,
        driver_name: user.name,
        driver_id_number: '110101199001011234',
        contact_phone: '13800138000',
        pickup_datetime: pickup_datetime,
        return_datetime: return_datetime,
        pickup_location: hotel.address || "#{@city}景区",
        status: 'confirmed',
        total_price: car.price_per_day * @rental_days,
        data_version: @data_version
      )
    end
    
    private
    
    def is_scenic_hotel?(hotel)
      return true if hotel.hotel_type&.include?('景区')
      return true if hotel.hotel_type&.include?('度假')
      return true if hotel.hotel_type&.include?('山庄')
      return true if hotel.hotel_type&.include?('民宿')
      return true if hotel.name&.include?('景区')
      return true if hotel.name&.include?('度假')
      return true if hotel.name&.include?('山庄')
      return true if hotel.features&.include?('景区')
      return true if hotel.features&.include?('度假')
      false
    end
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date&.to_s,
        rental_days: @rental_days
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @rental_days = data['rental_days']
    end
  end
end
