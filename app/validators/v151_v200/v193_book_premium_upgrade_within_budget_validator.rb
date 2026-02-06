# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例193: 预算内升级最高等级
#
# 任务描述:
#   预订经济舱+标准房，预算内升级最高等级
#
# 评分标准:
#   - 创建了航班订单 (20%)
#   - 创建了酒店订单 (20%)
#   - 在预算内升级到最高可能等级 (40%)
#   - 出发/到达城市正确 (10%)
#   - 日期合理 (10%)
module V151V200
  class V193BookPremiumUpgradeWithinBudgetValidator < BaseValidator
    self.validator_id = 'v193_book_premium_upgrade_within_budget_validator'
    self.task_id = '8cf29355-6c7f-458c-855e-c12a75be9643'
    self.title = '预算内升级最高等级'
    self.description = '预订经济舱+标准房，预算内升级最高等级'
    self.timeout_seconds = 300
    
    def prepare
      @departure_city = '北京'
      @arrival_city = '上海'
      @travel_date = Date.tomorrow + 2.days
      @max_budget = 2000
      
      # 查找所有舱位的航班
      @available_flights = Flight
        .where(departure_city: @departure_city, destination_city: @arrival_city, data_version: 0)
        .select { |f| f.departure_time.to_date == @travel_date }
        .to_a
      
      expect(@available_flights).not_to be_empty,
        "数据包缺少#{@departure_city}→#{@arrival_city}的航班（#{@travel_date}）"
      
      # 查找所有星级的酒店
      @available_hotels = Hotel.where(city: @arrival_city, data_version: 0).to_a
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      
      # 计算预算内最高等级
      @best_upgrade = find_best_upgrade_within_budget
      
      {
        task: "请预订#{@travel_date.strftime('%m月%d日')}从#{@departure_city}到#{@arrival_city}的航班+酒店，预算#{@max_budget}元，尽可能升级到最高等级",
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        max_budget: @max_budget,
        hint: "预算内尽量选择商务舱或头等舱、高星级酒店"
      }
    end
    
    def verify
      # 断言1: 创建了航班订单 (20%)
      add_assertion "创建了航班订单", weight: 20 do
        @flight_booking = Booking
          .joins(:flight)
          .includes(:flight)
          .where(flights: { departure_city: @departure_city, destination_city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@flight_booking).not_to be_nil, "未找到航班订单"
      end
      
      return if @flight_booking.nil?
      
      # 断言2: 创建了酒店订单 (20%)
      add_assertion "创建了酒店订单", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言3: 在预算内升级到最高可能等级 (40%)
      add_assertion "在预算内升级到最高可能等级", weight: 40 do
        flight = @flight_booking.flight
        hotel = @hotel_booking.hotel
        
        actual_total = @flight_booking.total_price + @hotel_booking.total_price
        expect(actual_total).to be <= @max_budget,
          "超出预算。期望: ≤#{@max_budget}元, 实际: #{actual_total}元"
        
        # 检查是否选择了较高等级
        seat_class_score = { 'economy' => 1, 'business' => 2, 'first' => 3 }
        actual_score = (seat_class_score[flight.seat_class] || 1) + (hotel.star_level || 3)
        expected_score = @best_upgrade[:score]
        
        expect(actual_score).to be >= (expected_score * 0.8).to_i,
          "等级升级不够。期望分数: ≥#{(expected_score * 0.8).to_i}，实际分数: #{actual_score}（舱位#{flight.seat_class}+#{hotel.star_level}星）"
      end
      
      # 断言4: 出发/到达城市正确 (10%)
      add_assertion "出发/到达城市正确", weight: 10 do
        flight = @flight_booking.flight
        expect(flight.departure_city).to eq(@departure_city)
        expect(flight.destination_city).to eq(@arrival_city)
      end
      
      # 断言5: 日期合理 (10%)
      add_assertion "日期合理", weight: 10 do
        arrival_date = @flight_booking.flight.arrival_time.to_date
        checkin_date = @hotel_booking.check_in_date
        expect([arrival_date, arrival_date + 1.day]).to include(checkin_date)
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 使用预先计算的最佳升级组合
      best_flight = @best_upgrade[:flight]
      best_hotel = @best_upgrade[:hotel]
      
      # 创建航班订单
      Booking.create!(
        user: user,
        flight_id: best_flight.id,
        passenger_name: user.name,
        passenger_id_number: '110101199001011234',
        contact_phone: '13800138000',
        total_price: best_flight.price,
        accept_terms: true,
        status: 'paid',
        data_version: @data_version
      )
      
      # 创建酒店订单
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = best_hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
      unless room
        room = HotelRoom.create!(
          hotel_id: best_hotel.id,
          room_type: '标准双人间',
          bed_type: 'double',
          price: best_hotel.price,
          original_price: best_hotel.original_price,
          area: 25.0,
          max_guests: 2,
          has_window: true,
          available_rooms: 10,
          room_category: 'standard',
          data_version: 0
        )
      end
      
      arrival_date = best_flight.arrival_time.to_date
      HotelBooking.create!(
        user: user,
        hotel_id: best_hotel.id,
        hotel_room_id: room.id,
        check_in_date: arrival_date,
        check_out_date: arrival_date + 1.day,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
    
    private
    
    def find_best_upgrade_within_budget
      seat_class_score = { 'economy' => 1, 'business' => 2, 'first' => 3 }
      best_combo = nil
      best_score = 0
      
      @available_flights.each do |flight|
        @available_hotels.each do |hotel|
          total = flight.price + hotel.price
          next if total > @max_budget
          
          score = (seat_class_score[flight.seat_class] || 1) + (hotel.star_level || 3)
          if score > best_score
            best_score = score
            best_combo = { flight: flight, hotel: hotel, score: score }
          end
        end
      end
      
      best_combo || { flight: @available_flights.first, hotel: @available_hotels.first, score: 4 }
    end
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        travel_date: @travel_date&.to_s,
        max_budget: @max_budget,
        best_upgrade_score: @best_upgrade[:score]
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @max_budget = data['max_budget']
    end
  end
end
