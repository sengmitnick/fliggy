# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例235: 张三后天要去成都出差，需要预订大床房住2晚
#
# 任务描述:
#   张三后天需要去成都出差，需要预订大床房，入住2晚。
#   Agent需要在成都市搜索有大床房的酒店，创建1个酒店订单，确保房型为大床房，入住日期为后天，住宿2晚。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、电话作为入住人信息）
#   2. 搜索成都市酒店
#   3. 筛选有大床房的酒店
#   4. 选择合适的大床房
#   5. 确认入住日期（后天）和退房日期（4天后）
#   6. 创建酒店订单（房型=大床房，入住日期=后天，住2晚）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解房型预订场景，明确房型要求为大床房
#   2. 需要准确计算入住日期（后天）和退房日期（入住日期+2天）
#   3. 需要使用LIKE查询匹配房型名称（room_type包含'大床房'）
#   4. 需要使用张三的个人信息作为入住人信息
#   5. 需要正确计算总价（房间价格 × 住宿天数）
#   ❌ 不能选择其他房型（如双床房、标准间），必须严格匹配大床房
#
# 评分标准（5项，总计100分）：
#   1. 创建了酒店订单（25分）
#   2. 房型符合要求（大床房）（35分）- 核心业务逻辑
#   3. 入住日期和时长正确（后天入住，住2晚）（20分）
#   4. 入住人信息正确（张三的姓名、电话）（15分）
#   5. 订单状态有效（5分）
#
# 使用方法:
#   rake validator:simulate_single[v235_book_specific_room_type_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V235BookSpecificRoomTypeValidator < BaseValidator
    self.validator_id = 'v235_book_specific_room_type_validator'
    self.task_id = '1ff1d2ff-2f2f-2f4f-4f5f-3f6a7b8c9d0f'
    self.title = '张三后天要去成都出差，需要预订大床房住2晚'
    self.description = '张三后天要去成都出差，需要预订大床房住2晚'
    self.timeout_seconds = 300
    
    def prepare
      @city = '成都'
      @room_type = '大床房'
      @check_in_date = Date.current + 2.days
      @check_out_date = @check_in_date + 2.days
      
      # 预查询受益人信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @passenger = user.passengers.find_by!(is_self: true, data_version: 0)
      @expected_guest_name = @passenger.name
      @expected_phone = @passenger.phone
      
      # 查找有指定房型的酒店
      @available_rooms = HotelRoom.joins(:hotel)
        .where(hotels: { city: @city, data_version: 0 })
        .where("hotel_rooms.room_type LIKE ?", "%#{@room_type}%")
        .where(hotel_rooms: { data_version: 0, room_category: 'overnight' })
        .includes(:hotel)
        .order('hotels.rating DESC, hotel_rooms.price ASC')
        .to_a
      
      raise "未找到#{@city}有#{@room_type}的酒店" if @available_rooms.empty?
      
      {
        task: "请为张三预订#{@check_in_date.strftime('%Y年%m月%d日')}（后天）在#{@city}的#{@room_type}，入住2晚。张三需要大床房。",
        requirements: {
          beneficiary: '张三',
          city: @city,
          room_type: @room_type,
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: 2,
          purpose: '指定房型'
        },
        hint: "在#{@city}搜索有#{@room_type}的酒店，优先选择评分高、价格合理的房间。",
        statistics: {
          available_rooms: @available_rooms.count,
          available_hotels: @available_rooms.map(&:hotel).uniq.count,
          price_range: {
            min: @available_rooms.minimum(:price),
            max: @available_rooms.maximum(:price)
          },
          top_hotel: @available_rooms.first&.hotel&.name
        }
      }
    end
    
    def verify
      add_assertion "创建了酒店订单", weight: 25 do
        all_bookings = HotelBooking
          .joins(:hotel)
          .includes(:hotel, :hotel_room)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "房型符合要求（#{@room_type}）（核心要求）", weight: 35 do
        room = @hotel_booking.hotel_room
        room_type_match = room.room_type.include?(@room_type)
        
        expect(room_type_match).to eq(true),
          "房型不符合要求。要求: #{@room_type}, 实际: #{room.room_type}（#{@hotel_booking.hotel.name}）"
      end
      
      add_assertion "入住日期和时长正确（#{@check_in_date.strftime('%m月%d日')}入住，住2晚）", weight: 20 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（后天）, 实际: #{@hotel_booking.check_in_date}"
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
      
      # 选择第一个符合房型要求的房间（优先评分高、价格低）
      room = @available_rooms.first
      hotel = room.hotel
      
      raise "未找到#{@city}有#{@room_type}的可用房间" if room.nil?
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @expected_guest_name,
        guest_phone: @expected_phone,
        room_count: 1,
        total_price: room.price * 2,
        status: 'paid',
        payment_method: '花呗',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        city: @city,
        room_type: @room_type,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        expected_guest_name: @expected_guest_name,
        expected_phone: @expected_phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @room_type = data['room_type']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @expected_guest_name = data['expected_guest_name']
      @expected_phone = data['expected_phone']
      
      @available_rooms = HotelRoom.joins(:hotel)
        .where(hotels: { city: @city, data_version: 0 })
        .where("hotel_rooms.room_type LIKE ?", "%#{@room_type}%")
        .where(hotel_rooms: { data_version: 0, room_category: 'overnight' })
        .includes(:hotel)
        .order('hotels.rating DESC, hotel_rooms.price ASC')
        .to_a
    end
  end
end
