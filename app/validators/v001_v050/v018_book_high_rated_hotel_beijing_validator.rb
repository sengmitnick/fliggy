# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例: 搜索北京的酒店，找到评分≥4.5分的酒店并完成后天入住1晚的预订
# 
# 任务描述:
#   Agent 需要在系统中搜索北京的酒店，
#   找到评分≥4.5分的酒店并成功创建入住1晚的订单
# 
# 复杂度分析:
#   1. 需要搜索"北京"城市的酒店
#   2. 需要选择"后天"日期（理解相对日期）
#   3. 需要筛选评分≥4.5的酒店
#   ❌ 不需要在多个高评分酒店中对比，只要满足评分即可
# 
# 评分标准:
#   - 订单已创建 (15分)
#   - 城市正确（北京） (15分)
#   - 入住日期正确（后天）(15分)
#   - 离店日期正确（大后天）(15分)
#   - 评分符合要求（≥4.5分）(40分)
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v018_book_high_rated_hotel_beijing_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V001V050
  class V018BookHighRatedHotelBeijingValidator < BaseValidator
    self.validator_id = 'v018_book_high_rated_hotel_beijing_validator'
    self.task_id = '34128065-50e8-4ab7-ba42-591180c6c91d'
    self.title = '给张三订后天入住北京的高评分酒店（选评分≥4.5，住1晚）'
    self.description = '搜索北京的酒店，找到评分≥4.5分的酒店并完成后天入住1晚的预订'
    self.timeout_seconds = 240
  
    # 准备阶段：设置任务参数
    def prepare
      @city = '北京'
      @min_rating = 4.5
      @check_in_date = Date.current + 2.days  # 后天
      @nights = 1
      @check_out_date = @check_in_date + @nights.days
    
      # 查找符合条件的酒店
      qualified_hotels = Hotel.where(city: @city, data_version: 0)
                              .where('rating >= ?', @min_rating)
    
      # 返回给 Agent 的任务信息
      {
        task: "给张三订后天入住北京的高评分酒店（选评分≥4.5，住1晚）",
        city: @city,
        min_rating: @min_rating,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        date_description: "入住：后天（#{@check_in_date.strftime('%Y年%m月%d日')}），离店：大后天（#{@check_out_date.strftime('%Y年%m月%d日')}）",
        nights: @nights,
        hint: "系统中有多家高评分酒店可选，选择评分≥#{@min_rating}分的酒店即可",
        qualified_hotels_count: qualified_hotels.count
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
      add_assertion "城市正确（北京）", weight: 10 do
        expect(@hotel_booking.hotel.city).to eq(@city),
          "城市错误。期望: #{@city}, 实际: #{@hotel_booking.hotel.city}"
      end
    
      # 断言3: 入住日期正确
      add_assertion "入住日期正确（后天）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}, 实际: #{@hotel_booking.check_in_date}"
      end
    
      # 断言4: 离店日期正确
      add_assertion "离店日期正确（大后天，入住#{@nights}晚）", weight: 10 do
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "离店日期错误。期望: #{@check_out_date}（入住+#{@nights}天）, 实际: #{@hotel_booking.check_out_date}"
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
    
      # 断言7: 评分符合要求（核心评分项）
      add_assertion "评分符合要求（≥#{@min_rating}分）", weight: 30 do
        hotel_rating = @hotel_booking.hotel.rating
        expect(hotel_rating >= @min_rating).to be_truthy,
          "评分不符合要求。最低要求: #{@min_rating}分, 实际: #{hotel_rating}分"
      end
    end
  
    private
  
    def execution_state_data
      {
        city: @city,
        min_rating: @min_rating,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights
      }
    end
  
    def restore_from_state(data)
      @city = data['city']
      @min_rating = data['min_rating']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights']
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 随机选择一家评分≥4.5的北京酒店
      target_hotel = Hotel.where(city: @city, data_version: 0)
                          .where('rating >= ?', @min_rating)
                          .sample
    
      # 选择一个房型
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
        hotel_rating: target_hotel.rating,
        check_in_date: @check_in_date.to_s,
        nights: @nights,
        user_email: user.email
      }
    end
    end
end
