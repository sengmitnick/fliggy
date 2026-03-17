# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例237: 张三明天要去广州出差，需要预订提供早餐的酒店住2晚
#
# 任务描述:
#   张三明天需要去广州出差，为了方便早上出行，需要预订提供早餐服务的酒店，入住2晚。
#   Agent需要在广州市筛选出提供早餐的酒店（通过facilities或name包含"早餐"），
#   创建1个酒店订单，确保入住日期为明天，住宿2晚。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、电话作为入住人信息）
#   2. 搜索广州市酒店
#   3. 筛选提供早餐的酒店（facilities或name包含"早餐"）
#   4. 按评分降序排序，优先选择评分最高的酒店
#   5. 确认入住日期（明天）和退房日期（3天后）
#   6. 创建酒店订单（入住日期=明天，住2晚）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解早餐服务预订场景，明确筛选条件（facilities或name包含"早餐"）
#   2. 需要准确计算入住日期（明天）和退房日期（入住日期+2天）
#   3. 需要在早餐酒店中选择最优选项（评分最高）
#   4. 需要使用张三的个人信息作为入住人信息
#   5. 需要确保订单状态有效（pending/paid/completed）
#   ❌ 不能选择不提供早餐的酒店，必须严格满足早餐要求
#
# 评分标准（5项，总计100分）：
#   1. 创建了酒店订单（25分）
#   2. 酒店提供早餐（35分）- 核心业务逻辑
#   3. 入住日期和时长正确（明天入住，住2晚）（20分）
#   4. 入住人信息正确（张三的姓名、电话）（15分）
#   5. 订单状态有效（5分）
#
# 使用方法:
#   rake validator:simulate_single[v237_book_hotel_with_breakfast_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V237BookHotelWithBreakfastValidator < BaseValidator
    self.validator_id = 'v237_book_hotel_with_breakfast_validator'
    self.task_id = '3ff3f4ff-4f4f-4f6f-6f7f-5f8a9b0c1d2f'
    self.title = '张三明天要去广州出差，需要预订提供早餐的酒店住2晚'
    self.description = '张三明天要去广州出差，需要预订提供早餐的酒店住2晚'
    self.timeout_seconds = 300
    
    def prepare
      @city = '广州'
      @check_in_date = Date.current + 1.day
      @check_out_date = @check_in_date + 2.days
      @nights = 2
      
      # 预查询受益人信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_name = @passenger.name
      @expected_phone = @passenger.phone
      
      # 查找提供早餐的酒店（通过facilities或name包含"早餐"）
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("facilities LIKE ? OR name LIKE ?", "%早餐%", "%早餐%")
        .order(rating: :desc)
        .to_a
      
      raise "未找到#{@city}提供早餐的酒店" if @available_hotels.empty?
      
      {
        task: "请为张三预订#{@check_in_date.strftime('%Y年%m月%d日')}（明天）在#{@city}提供早餐的酒店，入住#{@nights}晚。张三明天去出差，需要早餐方便早上出行。",
        requirements: {
          beneficiary: '张三',
          city: @city,
          breakfast: '必须提供早餐',
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: @nights,
          purpose: '出差，需要早餐'
        },
        hint: "在#{@city}筛选提供早餐的酒店（facilities或name包含'早餐'），优先选择评分最高的酒店。",
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
      
      add_assertion "酒店提供早餐（核心要求）", weight: 35 do
        hotel = @hotel_booking.hotel
        has_breakfast = hotel.facilities&.include?('早餐') || hotel.name&.include?('早餐')
        
        expect(has_breakfast).to eq(true),
          "酒店不提供早餐。酒店: #{hotel.name}, 设施: #{hotel.facilities}"
      end
      
      add_assertion "入住日期和时长正确（#{@check_in_date.strftime('%m月%d日')}入住，住#{@nights}晚）", weight: 20 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（明天）, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}（3天后）, 实际: #{@hotel_booking.check_out_date}"
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
      
      # 选择评分最高的提供早餐的酒店
      hotel = @available_hotels.first
      raise "未找到提供早餐的酒店" if hotel.nil?
      
      # 筛选过夜房间（排除钟点房）
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').order(price: :asc).first
      raise "未找到#{hotel.name}的可用房间" if room.nil?
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @expected_guest_name,
        guest_phone: @expected_phone,
        rooms_count: 1,
        total_price: room.price * @nights,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: @nights,
        expected_guest_name: @expected_guest_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @nights = data['nights']
      @expected_guest_name = data['expected_guest_name']
      @expected_phone = data['expected_phone']
      
      # 重新加载乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(name: @expected_guest_name, data_version: 0)
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("facilities LIKE ? OR name LIKE ?", "%早餐%", "%早餐%")
        .order(rating: :desc)
        .to_a
    end
  end
end
