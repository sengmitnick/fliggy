# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例20: 预订明天深圳酒店（1间房1成人，入住2晚）
# 
# 任务描述:
#   Agent 需要在系统中搜索深圳的酒店，
#   预订明天入住、大后天退房（共2晚），
#   预订1间房、1位成人、0位儿童
# 
# 复杂度分析:
#   1. 需要搜索"深圳"城市的酒店（具体城市）
#   2. 需要选择"明天"入住日期（理解相对日期）
#   3. 需要正确计算2晚的离店日期（明天+2天=大后天）
#   4. 需要设置正确的房间数（1间）和人数（1成人0儿童）
#   ❌ 重点验证多晚入住的日期计算和人数设置
# 
# 评分标准:
#   - 订单已创建 (25分)
#   - 城市正确（深圳） (15分)
#   - 入住日期正确（明天）(15分)
#   - 离店日期正确（大后天，共2晚）(25分)
#   - 房间数和人数正确（1间房，1成人，0儿童）(20分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v020_book_hotel_shenzhen_two_nights_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V020BookHotelShenzhenTwoNightsValidator < BaseValidator
    self.validator_id = 'v020_book_hotel_shenzhen_two_nights_validator'
    self.task_id = 'cebea439-0ffc-4798-9edb-e5cef8d09100'
    self.title = '给张三订明天入住深圳的酒店（住2晚）'
    self.description = '搜索深圳的酒店，预订明天入住、大后天退房（共2晚），预订1间房、1位成人、0位儿童'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      @city = '深圳'
      @check_in_date = Date.current + 1.day  # 明天
      @nights = 2
      @check_out_date = @check_in_date + @nights.days  # 大后天
    
      # 查找可用酒店数量
      available_hotels = Hotel.where(city: @city, data_version: 0)
    
      # 返回给 Agent 的任务信息
      {
        task: "请预订明天入住#{@city}的酒店（入住2晚）",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        date_description: "入住：明天（#{@check_in_date.strftime('%Y年%m月%d日')}），离店：大后天（#{@check_out_date.strftime('%Y年%m月%d日')}），共2晚",
        nights: @nights,
        hint: "系统中有多家酒店可选，选择任意一家即可，重点是正确计算2晚的离店日期",
        available_hotels_count: available_hotels.count
      }
    end
  
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 必须有订单创建（查询时过滤核心实体：城市）
      add_assertion "创建了酒店订单", weight: 20 do
        all_hotel_bookings = HotelBooking
          .joins(:hotel)
          .where(
            hotels: {
              city: @city,
              data_version: 0
            },
            data_version: @data_version
          )
          .order(created_at: :desc)
          .to_a
        expect(all_hotel_bookings).not_to be_empty, "未找到任何HotelBooking记录"
        @hotel_booking = all_hotel_bookings.first
      end
    
      return unless @hotel_booking
    
      # 断言2: 城市正确
      add_assertion "城市正确（深圳）", weight: 10 do
        expect(@hotel_booking.hotel.city).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@hotel_booking.hotel.city}"
      end
    
      # 断言3: 入住日期正确
      add_assertion "入住日期正确（明天）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
      end
    
      # 断言4: 离店日期正确（核心评分项）
      add_assertion "离店日期正确（大后天，共2晚）", weight: 30 do
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "离店日期错误。期望: #{@check_out_date} (入住2晚), 实际: #{@hotel_booking.check_out_date}"
      
        # 额外验证：计算实际入住晚数
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to eq(@nights),
          "入住晚数错误。期望: #{@nights}晚, 实际: #{actual_nights}晚"
      end
    
      # 断言5: 房间数和人数正确
      add_assertion "房间数和人数正确（1间房，1成人，0儿童）", weight: 10 do
        expect(@hotel_booking.rooms_count).to eq(1),
          "房间数错误。期望: 1间, 实际: #{@hotel_booking.rooms_count}间"
        expect(@hotel_booking.adults_count).to eq(1),
          "成人数错误。期望: 1人, 实际: #{@hotel_booking.adults_count}人"
        expect(@hotel_booking.children_count).to eq(0),
          "儿童数错误。期望: 0人, 实际: #{@hotel_booking.children_count}人"
      end
    
      # 断言6: 入住人信息正确（张三 13800138000）
      add_assertion "入住人信息正确（张三 13800138000）", weight: 10 do
        expect(@hotel_booking.guest_name).to eq('张三'),
          "入住人姓名错误。期望: 张三（demo_user数据）, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq('13800138000'),
          "联系电话错误。期望: 13800138000（demo_user数据）, 实际: #{@hotel_booking.guest_phone}"
      end
    
      # 断言7: 总价和状态合理
      add_assertion "总价和状态合理", weight: 10 do
        expect(@hotel_booking.status).not_to be_nil
        expect(@hotel_booking.total_price).to be > 0
      end
    end
  
    private
  
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights
      }
    end
  
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights']
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 随机选择一家深圳的酒店
      target_hotel = Hotel.where(city: @city, data_version: 0).sample
    
      target_hotel_room = HotelRoom.where(hotel_id: target_hotel.id, data_version: 0)
                                   .where(room_category: 'overnight')
                                   .order(:price)
                                   .first
    
      raise "未找到可用房型" unless target_hotel_room
    
      # 获取demo_user的乘机人信息（酒店入住需要身份证号）
      passenger = user.passengers.find_by!(name: '张三', data_version: 0)
    
      hotel_booking = HotelBooking.create!(
        hotel_id: target_hotel.id,
        hotel_room_id: target_hotel_room.id,
        user_id: user.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        total_price: target_hotel_room.price * @nights,
        payment_method: '花呗',
        status: 'pending',
        guest_name: passenger.name,
        guest_phone: passenger.phone,
        data_version: @data_version
      )
    
      {
        action: 'create_hotel_booking',
        booking_id: hotel_booking.id,
        hotel_name: target_hotel.name,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        user_email: user.email
      }
    end
    end
end
