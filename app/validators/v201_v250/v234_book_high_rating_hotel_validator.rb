# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例234: 张三3天后要去杭州出差，追求品质体验，需要预订评分≥4.5星的高评分酒店住1晚
#
# 任务描述:
#   张三3天后需要去杭州出差，注重住宿品质，要求预订评分≥4.5星的高评分酒店，入住1晚。
#   Agent需要在杭州市筛选出评分≥4.5星的酒店，创建1个酒店订单，确保入住日期为3天后，住宿1晚。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、电话作为入住人信息）
#   2. 搜索杭州市酒店
#   3. 筛选评分≥4.5星的高评分酒店
#   4. 按评分降序排序，优先选择评分最高的酒店
#   5. 确认入住日期（3天后）和退房日期（4天后）
#   6. 创建酒店订单（入住日期=3天后，住1晚）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解高评分酒店预订场景，明确评分阈值≥4.5星
#   2. 需要准确计算入住日期（3天后）和退房日期（入住日期+1天）
#   3. 需要在评分筛选后选择最优酒店（评分最高）
#   4. 需要使用张三的个人信息作为入住人信息
#   5. 需要确保订单状态有效（pending/paid/completed）
#   ❌ 不能选择评分低于4.5星的酒店，必须严格满足评分要求
#
# 评分标准（5项，总计100分）：
#   1. 创建了酒店订单（25分）
#   2. 酒店评分≥4.5星（35分）- 核心业务逻辑
#   3. 入住日期和时长正确（3天后入住，住1晚）（20分）
#   4. 入住人信息正确（张三的姓名、电话）（15分）
#   5. 订单状态有效（5分）
#
# 使用方法:
#   rake validator:simulate_single[v234_book_high_rating_hotel_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V234BookHighRatingHotelValidator < BaseValidator
    self.validator_id = 'v234_book_high_rating_hotel_validator'
    self.task_id = '0ff0c1ff-1f1f-1f3f-3f4f-2f5a6b7c8d9f'
    self.title = '张三3天后要去杭州出差，追求品质体验，需要预订评分≥4.5星的高评分酒店住1晚'
    self.description = '张三3天后要去杭州出差，追求品质体验，需要预订评分≥4.5星的高评分酒店住1晚'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @min_rating = 4.5
      @check_in_date = Date.current + 3.days
      @check_out_date = @check_in_date + 1.day
      
      # 预查询受益人信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(is_self: true, data_version: 0)
      @expected_guest_name = @passenger.name
      @expected_phone = @passenger.phone
      
      # 查找符合评分要求的酒店
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("rating >= ?", @min_rating)
        .order(rating: :desc)
        .to_a
      
      raise "未找到#{@city}评分≥#{@min_rating}星的酒店" if @available_hotels.empty?
      
      {
        task: "请为张三预订#{@check_in_date.strftime('%Y年%m月%d日')}（3天后）在#{@city}的高评分酒店（评分≥#{@min_rating}星），入住1晚。张三追求品质体验。",
        requirements: {
          beneficiary: '张三',
          city: @city,
          min_rating: "≥#{@min_rating}星",
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: 1,
          purpose: '追求品质体验'
        },
        hint: "在#{@city}筛选评分≥#{@min_rating}星的酒店，优先选择评分最高的酒店。",
        statistics: {
          available_hotels: @available_hotels.count,
          rating_range: {
            min: @available_hotels.minimum(:rating),
            max: @available_hotels.maximum(:rating)
          },
          top_hotel: @available_hotels.first&.name
        }
      }
    end
    
    def verify
      add_assertion "创建了酒店订单", weight: 25 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "酒店评分≥#{@min_rating}星（核心要求）", weight: 35 do
        hotel = @hotel_booking.hotel
        expect(hotel.rating).to be >= @min_rating,
          "酒店评分不符合要求。要求: ≥#{@min_rating}星, 实际: #{hotel.rating}星（#{hotel.name}）"
      end
      
      add_assertion "入住日期和时长正确（#{@check_in_date.strftime('%m月%d日')}入住，住1晚）", weight: 20 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（3天后）, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}（4天后）, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "入住人信息正确（张三）", weight: 15 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_phone),
          "入住人电话错误。期望: #{@expected_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态无效。实际: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择评分最高的酒店（追求品质）
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :desc).first
      
      raise "未找到#{hotel.name}的可用房间" if room.nil?
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @expected_guest_name,
        guest_phone: @expected_phone,
        room_count: 1,
        total_price: room.price,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        min_rating: @min_rating,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        expected_guest_name: @expected_guest_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @min_rating = data['min_rating']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @expected_guest_name = data['expected_guest_name']
      @expected_phone = data['expected_phone']
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("rating >= ?", @min_rating)
        .order(rating: :desc)
        .to_a
    end
  end
end
