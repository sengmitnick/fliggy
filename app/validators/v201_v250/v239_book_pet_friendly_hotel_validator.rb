# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例239: 帮张三订后天在成都的酒店，要允许携带宠物的，住2晚
#
# 任务描述:
#   张三后天需要去成都，计划携带宠物同行，需要预订允许携带宠物的酒店，入住2晚。
#   Agent需要在成都市筛选出允许携带宠物的酒店，创建1个酒店订单，确保入住日期为后天，住宿2晚。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、电话作为入住人信息）
#   2. 搜索成都市酒店
#   3. 筛选允许携带宠物的酒店（features数组包含"宠物友好"元素）
#   4. 选择合适的宠物友好酒店
#   5. 确认入住日期（后天）和退房日期（入住日期+2天）
#   6. 创建酒店订单（入住日期=后天，住2晚）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解宠物友好酒店预订场景，明确需要筛选features字段
#   2. 需要准确计算入住日期（后天=Date.current+2.days）和退房日期（入住日期+2天）
#   3. 需要在features数组中查找"宠物友好"元素
#   4. 需要使用张三的个人信息作为入住人信息
#   5. 需要确保订单状态有效（pending/paid/completed）
#   ❌ 不能选择不允许携带宠物的酒店，必须严格满足宠物友好要求
#
# 评分标准（5项，总计100分）：
#   1. 创建了酒店订单（25分）
#   2. 酒店允许携带宠物（35分）- 核心业务逻辑
#   3. 入住日期和时长正确（后天入住，住2晚）（20分）
#   4. 入住人信息正确（张三的姓名、电话）（15分）
#   5. 订单状态有效（5分）
#
# 使用方法:
#   rake validator:simulate_single[v239_book_pet_friendly_hotel_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V239BookPetFriendlyHotelValidator < BaseValidator
    self.validator_id = 'v239_book_pet_friendly_hotel_validator'
    self.task_id = '5ff516ff-6f6f-6f8f-8f9f-7f0a1b2c3d4f'
    self.title = '帮张三订后天在成都的酒店，要允许携带宠物的，住2晚'
    self.description = '帮张三订后天在成都的酒店，要允许携带宠物的，住2晚'
    self.timeout_seconds = 300
    
    def prepare
      @city = '成都'
      @check_in_date = Date.current + 2.days
      @check_out_date = @check_in_date + 2.days
      
      # 预查询受益人信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_name = @zhangsan.name
      @expected_guest_phone = @zhangsan.phone
      
      # 查找宠物友好酒店（features包含"宠物友好"）
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .select { |h| h.features&.include?('宠物友好') }
        .sort_by { |h| -h.rating }
      
      raise "未找到#{@city}允许携带宠物的酒店" if @available_hotels.empty?
      
      {
        task: "请为张三预订#{@check_in_date.strftime('%Y年%m月%d日')}（后天）在#{@city}允许携带宠物的酒店，入住2晚。张三需要携带宠物同行。",
        requirements: {
          beneficiary: '张三',
          city: @city,
          pet_friendly: '必须允许携带宠物',
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: 2,
          purpose: '携带宠物同行'
        },
        hint: "在#{@city}筛选允许携带宠物的酒店（features包含'宠物友好'）。",
        statistics: {
          available_hotels: @available_hotels.count,
          rating_range: {
            min: @available_hotels.map(&:rating).min,
            max: @available_hotels.map(&:rating).max
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
      
      add_assertion "酒店允许携带宠物（核心要求）", weight: 35 do
        hotel = @hotel_booking.hotel
        is_pet_friendly = hotel.features&.include?('宠物友好')
        
        expect(is_pet_friendly).to eq(true),
          "酒店不允许携带宠物。酒店: #{hotel.name}, 设施: #{hotel.features&.join(', ')}"
      end
      
      add_assertion "入住日期和时长正确（#{@check_in_date.strftime('%m月%d日')}入住，住2晚）", weight: 20 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（后天）, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}（后天+2天）, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "入住人信息正确（张三）", weight: 15 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_guest_phone),
          "入住人电话错误。期望: #{@expected_guest_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态无效。实际: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择评分最高的宠物友好酒店
      hotel = @available_hotels.first
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
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        expected_guest_name: @expected_guest_name,
        expected_guest_phone: @expected_guest_phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @expected_guest_name = data['expected_guest_name']
      @expected_guest_phone = data['expected_guest_phone']
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .select { |h| h.features&.include?('宠物友好') }
        .sort_by { |h| -h.rating }
    end
  end
end
