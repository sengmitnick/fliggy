# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例242: 张三后天要去上海出差，注重住宿品质，需要预订评分至少4.5星的高品质酒店住1晚
#
# 任务描述:
#   张三后天需要去上海出差，注重住宿品质，要求预订评分至少4.5星的高品质酒店，入住1晚。
#   Agent需要在上海市筛选出评分≥4.5星的酒店，创建1个酒店订单，确保入住日期为后天，住宿1晚。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、电话作为入住人信息）
#   2. 搜索上海市酒店
#   3. 筛选评分≥4.5星的高品质酒店
#   4. 按评分降序、价格升序排序，优先选择评分最高且价格合理的酒店
#   5. 确认入住日期（后天=Date.current+2.days）和退房日期（入住日期+1天）
#   6. 创建酒店订单（入住日期=后天，住1晚）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解高品质酒店预订场景，明确评分阈值≥4.5星
#   2. 需要准确计算入住日期（后天=Date.current+2.days）和退房日期（入住日期+1天）
#   3. 需要在评分筛选后选择最优酒店（评分最高且价格合理）
#   4. 需要使用张三的个人信息作为入住人信息
#   5. 需要确保订单状态有效（pending/paid/completed）
#   ❌ 不能选择评分低于4.5星的酒店，必须严格满足评分要求
#
# 评分标准（6项，总计100分）：
#   1. 创建了酒店订单（20分）
#   2. 城市正确（上海）（10分）
#   3. 酒店评分≥4.5分（35分）- 核心业务逻辑
#   4. 入住日期和时长正确（后天入住，住1晚）（15分）
#   5. 入住人信息正确（张三的姓名、电话）（10分）
#   6. 订单状态有效（10分）
#
# 使用方法:
#   rake validator:simulate_single[v242_book_high_rated_hotel_above_4_5_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
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
      
      # 预查询受益人信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_name = @passenger.name
      @expected_guest_phone = @passenger.phone
      
      # 查找评分≥4.5星的高品质酒店
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where('rating >= ?', @min_rating)
        .order(rating: :desc, price: :asc)
        .to_a
      
      raise "未找到#{@city}评分≥#{@min_rating}星的酒店" if @available_hotels.empty?
      
      {
        task: "请为张三预订#{@check_in_date.strftime('%Y年%m月%d日')}（后天）在#{@city}的高品质酒店，入住1晚。要求酒店评分≥#{@min_rating}星，张三注重住宿品质。",
        requirements: {
          beneficiary: '张三',
          city: @city,
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: 1,
          min_rating: "≥#{@min_rating}星",
          purpose: '注重住宿品质'
        },
        hint: "在#{@city}筛选评分≥#{@min_rating}星的酒店，优先选择评分最高且价格合理的酒店。",
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
      add_assertion "创建了酒店订单", weight: 20 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
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
      
      add_assertion "酒店评分≥#{@min_rating}星（核心要求）", weight: 35 do
        rating = @booking.hotel.rating
        expect(rating).to be >= @min_rating,
          "酒店评分不符合要求。要求: ≥#{@min_rating}星（高品质）, 实际: #{rating}星（#{@booking.hotel.name}）"
      end
      
      add_assertion "入住日期和时长正确（#{@check_in_date.strftime('%m月%d日')}入住，住1晚）", weight: 15 do
        expect(@booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（后天）, 实际: #{@booking.check_in_date}"
        expect(@booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}, 实际: #{@booking.check_out_date}"
      end
      
      add_assertion "入住人信息正确（张三）", weight: 10 do
        expect(@booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}, 实际: #{@booking.guest_name}"
        expect(@booking.guest_phone).to eq(@expected_guest_phone),
          "联系电话错误。期望: #{@expected_guest_phone}, 实际: #{@booking.guest_phone}"
      end
      
      add_assertion "订单状态有效", weight: 10 do
        expect(@booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态无效。实际: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择评分最高且价格合理的酒店（注重品质）
      hotel = @available_hotels.first
      # CRITICAL: 必须过滤掉钟点房，只考虑整晚房价
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
      
      raise "未找到#{hotel.name}的可用房间" if room.nil?
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @expected_guest_name,
        guest_phone: @expected_guest_phone,
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
        min_rating: @min_rating,
        expected_guest_name: @expected_guest_name,
        expected_guest_phone: @expected_guest_phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @min_rating = data['min_rating']
      @expected_guest_name = data['expected_guest_name']
      @expected_guest_phone = data['expected_guest_phone']
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where('rating >= ?', @min_rating)
        .order(rating: :desc, price: :asc)
        .to_a
    end
  end
end
