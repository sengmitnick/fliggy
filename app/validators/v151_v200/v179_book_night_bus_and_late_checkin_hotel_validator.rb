# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例179: 给李四预订明天晚上18:00后的北京到天津长途大巴，并预订酒店深夜入住（入住日期选明天，住1晚）
#
# 任务描述:
#   李四明天需要从北京坐长途大巴到天津，选择晚上出发的班次（18:00后，例如19:00出发23:00到达）。
#   因为晚班大巴深夜到达（23:00左右甚至凌晨01:00），办理酒店入住时入住日期应选择大巴出发日（明天），不管到几点都按当晚计费。
#   需要创建2个订单：
#   1. 大巴订单（明天北京→天津，18:00后出发）
#   2. 酒店订单（入住日期=明天，即大巴出发日，住1晚）
#
# 业务流程:
#   1. 搜索并预订明天晚上18:00后出发的北京到天津长途大巴（例如19:00出发23:00到达，或19:00出发01:00到达）
#   2. 预订天津的酒店
#   3. 入住日期：明天（大巴出发日）—— 酒店深夜入住规则：不管多晚到达（23:00或凌晨01:00），入住日期都选前一天
#   4. 退房日期：后天（入住日期+1天，住1晚）
#   5. 乘客和入住人均为李四
#
# 复杂度分析:
#   1. 需要搜索并预订晚上18:00后出发的长途大巴（排除白天班次）
#   2. 需要理解酒店"深夜入住"的日期规则：不管多晚到达（23:00或凌晨01:00），入住日期都应该选择大巴出发日（前一天），而不是到达的日历日期
#   3. 需要协调两个订单的日期关系（酒店入住日=大巴出发日=明天）
#   ❌ 不能一次性提供：需要先查询晚班大巴→确定大巴出发日期→预订大巴→预订酒店（入住日期=大巴出发日）
#
# 评分标准（总分100分）:
#   1. 创建了大巴订单（明天北京→天津） (20分)
#   2. 大巴出发时间正确（18:00后） (15分)
#   3. 大巴出发日期正确（明天） (10分)
#   4. 创建了酒店订单 (18分)
#   5. 酒店位置正确（天津） (12分)
#   6. 酒店入住日期正确（大巴出发日=明天） (18分)
#   7. 预订的是整晚房间（非钟点房） (2分)
#   8. 大巴乘客信息正确（李四） (3分)
#   9. 酒店入住人信息正确（李四） (2分)
#
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v179_book_night_bus_and_late_checkin_hotel_validator/start
#   
#   # Agent 通过界面操作完成任务...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V151V200
  class V179BookNightBusAndLateCheckinHotelValidator < BaseValidator
    self.validator_id = 'v179_book_night_bus_and_late_checkin_hotel_validator'
    self.task_id = 'd1757d07-df13-446b-ba4c-23790c798232'
    self.title = '给李四预订明天北京到天津的晚班大巴，并预订深夜入住酒店'
    self.description = '帮李四订明天晚上从北京到天津的长途大巴（18:00后出发），并预订支持深夜入住的酒店'
    self.timeout_seconds = 300
  
    def prepare
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_passenger_name = @passenger.name
      @expected_phone = @passenger.phone
      
      @departure_city = '北京'
      @arrival_city = '天津'
      @bus_date = Date.current + 1.day  # 明天
      
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
      
      # 深夜入住规则：入住日期=大巴出发日期（不管到达时间是23:00还是凌晨01:00）
      @hotel_checkin_date = @bus_date
      @hotel_checkout_date = @hotel_checkin_date + 1.day
      
      {
        task: "请为#{@passenger.name}预订#{@bus_date.strftime('%Y年%m月%d日')}（#{(@bus_date - Date.current).to_i}天后）从#{@departure_city}到#{@arrival_city}的晚班大巴（18:00后出发），" \
              "并在#{@arrival_city}预订酒店，入住日期选#{@bus_date.strftime('%Y年%m月%d日')}（大巴出发日）",
        requirements: {
          departure_city: @departure_city,
          arrival_city: @arrival_city,
          bus_date: @bus_date.to_s,
          departure_time: "18:00后",
          hotel_location: @arrival_city,
          hotel_checkin_date: @hotel_checkin_date.to_s
        },
        hint: "晚班大巴深夜到达，酒店入住日期应选择大巴出发日（不管到几点都按当晚计费）",
        statistics: {
          available_night_buses: @available_buses.count,
          available_hotels: @available_hotels.count
        }
      }
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      passenger = user.passengers.find_by!(name: '李四', data_version: 0)
      
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
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel_id: hotel.id,
        hotel_room_id: room.id,
        check_in_date: @hotel_checkin_date,
        check_out_date: @hotel_checkout_date,
        guest_name: @passenger.name,
        guest_phone: passenger.phone,
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
      
      # 断言2: 大巴出发时间正确（18:00后） (15%)
      add_assertion "大巴出发时间正确（18:00后）", weight: 15 do
        dep_time = Time.parse(@bus_order.bus_ticket.departure_time)
        departure_hour = dep_time.hour
        expect(departure_hour).to be >= 18, 
          "出发时间过早。期望: 18:00后, 实际: #{@bus_order.bus_ticket.departure_time}"
      end
      
      # 断言3: 大巴出发日期正确（明天） (10%)
      add_assertion "大巴出发日期正确（明天 #{@bus_date}）", weight: 10 do
        expect(@bus_order.bus_ticket.departure_date).to eq(@bus_date),
          "出发日期错误。期望: #{@bus_date}（明天）, 实际: #{@bus_order.bus_ticket.departure_date}"
      end
      
      # 断言4: 创建了酒店订单 (18%)
      add_assertion "创建了酒店订单", weight: 18 do
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
      
      # 断言5: 酒店在到达城市 (12%)
      add_assertion "酒店位置正确（#{@arrival_city}）", weight: 12 do
        hotel = @hotel_booking.hotel
        expect(hotel.city).to include(@arrival_city),
          "酒店城市错误。期望: #{@arrival_city}, 实际: #{hotel.city}"
      end
      
      # 断言6: 酒店入住日期为大巴出发日（深夜入住规则） (18%)
      add_assertion "酒店入住日期正确（大巴出发日=#{@bus_date}）", weight: 18 do
        expect(@hotel_booking.check_in_date).to eq(@bus_date),
          "入住日期错误。期望: #{@bus_date}（大巴出发日，深夜入住按当晚计费）, 实际: #{@hotel_booking.check_in_date}"
        
        # 验证退房日期
        expect(@hotel_booking.check_out_date).to eq(@hotel_checkout_date),
          "退房日期错误。期望: #{@hotel_checkout_date}, 实际: #{@hotel_booking.check_out_date}"
      end
      
      # 断言7: 预订的是整晚房间（非钟点房） (2%)
      add_assertion "预订的是整晚房间（非钟点房）", weight: 2 do
        room = @hotel_booking.hotel_room
        expect(room).not_to be_nil, "未找到酒店房间信息"
        expect(room.room_category).to eq('overnight'),
          "房间类型错误。期望: 整晚房(overnight), 实际: #{room.room_category}"
      end
    
      # 断言8: 大巴乘客信息正确（李四） (3%)
      add_assertion "大巴乘客信息正确（#{@expected_passenger_name}）", weight: 3 do
        # BusTicketOrder 没有 passenger_name 字段，只能验证通过关联数据
        # 这里我们假设大巴订单是给正确的用户创建的
        expect(@bus_order.user).not_to be_nil,
          "大巴订单缺少用户信息"
        expect(@bus_order.passenger_count).to be >= 1,
          "大巴乘客数量错误。期望: 至少1人, 实际: #{@bus_order.passenger_count}"
      end
    
      # 断言9: 酒店入住人信息正确（李四） (2%)
      add_assertion "酒店入住人信息正确（#{@expected_passenger_name}）", weight: 2 do
        expect(@hotel_booking.guest_name).to eq(@expected_passenger_name),
          "酒店入住人姓名错误。期望: #{@expected_passenger_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "酒店联系电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
    end
    
    private
    
    def execution_state_data
      {
        departure_city: @departure_city,
        arrival_city: @arrival_city,
        bus_date: @bus_date&.to_s,
        hotel_checkin_date: @hotel_checkin_date&.to_s,
        hotel_checkout_date: @hotel_checkout_date&.to_s,
        expected_passenger_name: @expected_passenger_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @departure_city = data['departure_city']
      @arrival_city = data['arrival_city']
      @bus_date = Date.parse(data['bus_date']) if data['bus_date']
      @hotel_checkin_date = Date.parse(data['hotel_checkin_date']) if data['hotel_checkin_date']
      @hotel_checkout_date = Date.parse(data['hotel_checkout_date']) if data['hotel_checkout_date']
      @expected_passenger_name = data['expected_passenger_name']
      @expected_phone = data['expected_phone']
      
      # 重新查询乘客信息（用于simulate阶段）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_passenger_name, data_version: 0)
      
      # 重新查询可用大巴和酒店（用于simulate阶段）
      @available_buses = BusTicket
        .where(origin: @departure_city, destination: @arrival_city, data_version: 0)
        .select do |b|
          next false unless b.departure_date == @bus_date
          begin
            dep_time = Time.parse(b.departure_time)
            dep_time.hour >= 18
          rescue
            false
          end
        end
      
      @available_hotels = Hotel
        .where("city LIKE ?", "%#{@arrival_city}%")
        .where(data_version: 0)
        .limit(20)
        .to_a
    end
  end
end
