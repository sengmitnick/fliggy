# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例179: 预订晚班大巴和深夜入住酒店
#
# 任务描述:
#   用户需要预订晚上出发的长途大巴，并预订支持深夜入住的酒店
#
# 复杂度分析:
#   1. 需要筛选晚上出发的大巴（18:00后）
#   2. 需要预订支持深夜入住的酒店
#   3. 验证酒店入住日期与大巴到达日期匹配
#
# 评分标准:
#   - 创建了大巴订单 (20分)
#   - 大巴出发时间正确（18:00后） (20分)
#   - 创建了酒店订单 (20分)
#   - 酒店在到达城市 (20分)
#   - 酒店入住日期为大巴到达当天 (20分)
module V151V200
  class V179BookNightBusAndLateCheckinHotelValidator < BaseValidator
    self.validator_id = 'v179_book_night_bus_and_late_checkin_hotel_validator'
    self.task_id = 'd1757d07-df13-446b-ba4c-23790c798232'
    self.title = '预订晚班大巴和深夜入住酒店'
    self.description = '用户需要预订晚上出发的长途大巴，并预订支持深夜入住的酒店'
    self.timeout_seconds = 300
  
    def prepare
      @departure_city = '北京'
      @arrival_city = '天津'
      @bus_date = Date.tomorrow + 2.days
      
      # 查找晚上18点后出发的大巴
      @available_buses = BusTicket
        .where(origin: @departure_city, destination: @arrival_city, data_version: 0)
        .select do |b|
          next false unless b.departure_date == @bus_date
          # departure_time 是字符串，需要解析
          begin
            dep_time = Time.parse(b.departure_time)
            dep_time.hour >= 18
          rescue
            false
          end
        end
      
      expect(@available_buses).not_to be_empty, "数据包缺少#{@departure_city}→#{@arrival_city}晚班大巴（18:00后）"
      
      # 查找天津的酒店
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
      
      expect(@available_hotels).not_to be_empty, "数据包缺少#{@arrival_city}的酒店"
      
      # 计算到达日期（可能是当天或次日）
      sample_bus = @available_buses.first
      # departure_time 和 arrival_time 是字符串，需要解析
      dep_hour = Time.parse(sample_bus.departure_time).hour
      arr_hour = Time.parse(sample_bus.arrival_time).hour
      # 如果到达时间晚于出发时间，则当天到达；否则次日到达
      @hotel_checkin_date = if arr_hour >= dep_hour
        @bus_date
      else
        @bus_date + 1.day
      end
      @hotel_checkout_date = @hotel_checkin_date + 1.day
      
      {
        task: "请预订#{@bus_date.strftime('%Y年%m月%d日')}（#{(@bus_date - Date.today).to_i}天后）从#{@departure_city}到#{@arrival_city}的晚班大巴（18:00后出发），" \
              "并在#{@arrival_city}预订支持深夜入住的酒店",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          bus_date: @bus_date.to_s,
          departure_time: "18:00后",
          hotel_location: @arrival_city,
          hotel_checkin: "支持深夜入住"
        },
        hint: "晚班大巴到达时间较晚，需要酒店支持深夜入住",
        statistics: {
          available_night_buses: @available_buses.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 创建大巴订单
      bus = @available_buses.first
      BusTicketOrder.create!(
        user: user,
        bus_ticket: bus,
        passenger_count: 1,
        base_price: bus.price,
        total_price: bus.price,
        data_version: @data_version
      )
      
      # 创建酒店订单
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first
      
      unless room
        room = HotelRoom.create!(
          hotel_id: hotel.id,
          name: '标准双人间',
          size: 25.0,
          bed_type: 'double',
          price: 200.0,
          original_price: 300.0,
          amenities: ['免费WiFi', '空调', '热水', '24小时前台'].to_json,
          breakfast_included: false,
          cancellation_policy: '免费取消',
          data_version: 0
        )
      end
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date,
        guest_name: user.name,
        guest_phone: '13800138000',
        payment_method: '花呗',
        total_price: room.price,
        data_version: @data_version
      )
    end
  
    def verify
      # 断言1: 创建了大巴订单 (20%)
      add_assertion "创建了大巴订单（#{@departure_city}→#{@arrival_city}）", weight: 20 do
        all_orders = BusTicketOrder
          .joins(:bus_ticket)
          .includes(:bus_ticket)
          .where(bus_tickets: { origin: @departure_city, destination: @arrival_city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @bus_order = all_orders.first
        expect(@bus_order).not_to be_nil, "未找到大巴订单"
      end
      
      return if @bus_order.nil?
      
      # 断言2: 大巴出发时间正确（18:00后） (20%)
      add_assertion "大巴出发时间正确（18:00后）", weight: 20 do
        dep_time = Time.parse(@bus_order.bus_ticket.departure_time)
        departure_hour = dep_time.hour
        expect(departure_hour).to be >= 18, 
          "出发时间过早。期望: 18:00后, 实际: #{@bus_order.bus_ticket.departure_time}"
      end
      
      # 断言3: 创建了酒店订单 (20%)
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
      
      # 断言4: 酒店在到达城市 (20%)
      add_assertion "酒店位置正确（#{@arrival_city}）", weight: 20 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@arrival_city),
          "酒店城市错误。期望: #{@arrival_city}, 实际: #{hotel.city}"
      end
      
      # 断言5: 酒店入住日期为大巴到达当天 (20%)
      add_assertion "酒店入住日期正确（大巴到达当天）", weight: 20 do
        bus = @bus_order.bus_ticket
        # departure_time 和 arrival_time 是字符串，需要解析
        dep_hour = Time.parse(bus.departure_time).hour
        arr_hour = Time.parse(bus.arrival_time).hour
        # 计算到达日期：如果到达时间晚于出发时间，则当天；否则次日
        arrival_date = if arr_hour >= dep_hour
          bus.departure_date
        else
          bus.departure_date + 1.day
        end
        expect(@hotel_booking.check_in_date).to eq(arrival_date),
          "入住日期错误。期望: #{arrival_date}（大巴到达当天）, 实际: #{@hotel_booking.check_in_date}"
      end
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        bus_date: @bus_date&.to_s,
        hotel_checkin_date: @hotel_checkin_date&.to_s,
        hotel_checkout_date: @hotel_checkout_date&.to_s
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @bus_date = Date.parse(data['bus_date']) if data['bus_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
    end
  end
end
