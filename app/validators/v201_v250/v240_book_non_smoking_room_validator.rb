# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例240: 帮张三订明天在杭州的酒店，要无烟房，住1晚
#
# 任务描述:
#   张三明天需要在杭州入住酒店，注重健康环境，要求预订提供无烟客房设施的酒店，住1晚。
#   Agent需要在杭州市筛选出提供无烟客房的酒店，创建1个酒店订单，确保入住日期为明天，住宿1晚。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、电话作为入住人信息）
#   2. 搜索杭州市酒店
#   3. 筛选提供无烟客房设施的酒店（facilities包含'无烟'或'non-smoking'）
#   4. 按评分降序排序，优先选择高评分酒店
#   5. 确认入住日期（明天）和退房日期（后天）
#   6. 创建酒店订单（入住日期=明天，住1晚）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解无烟房预订场景，明确设施筛选条件（facilities包含'无烟'/'non-smoking'）
#   2. 需要准确计算入住日期（明天=Date.current+1.day）和退房日期（入住日期+1天）
#   3. 需要在符合条件的酒店中优先选择高评分酒店（排序策略）
#   4. 需要使用张三的个人信息作为入住人信息
#   5. 需要确保订单状态有效（pending/paid/completed）
#   ❌ 不能选择不提供无烟客房的酒店，必须严格检查facilities字段
#
# 评分标准（5项，总计100分）：
#   1. 创建了酒店订单（25分）
#   2. 酒店提供无烟客房设施（40分）- 核心业务逻辑
#   3. 入住人信息正确（张三的姓名、电话）（15分）
#   4. 入住日期和时长正确（明天入住，住1晚）（15分）
#   5. 订单状态有效（5分）
#
# 使用方法:
#   rake validator:simulate_single[v240_book_non_smoking_room_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V240BookNonSmokingRoomValidator < BaseValidator
    self.validator_id = 'v240_book_non_smoking_room_validator'
    self.task_id = '6ff627ff-7f7f-7f9f-9f0f-8f1a2b3c4d5f'
    self.title = '帮张三订明天在杭州的酒店，要无烟房，住1晚'
    self.description = '帮张三订明天在杭州的酒店，要无烟房，住1晚'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @check_in_date = Date.current + 1.day
      @check_out_date = @check_in_date + 1.day
      
      # 预查询受益人信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_name = @zhangsan.name
      @expected_guest_phone = @zhangsan.phone
      
      # 查找提供无烟客房设施的酒店（facilities字段包含'无烟'或'non-smoking'）
      @available_hotels = Hotel
        .where(city: @city, data_version: 0)
        .where("facilities LIKE ? OR facilities LIKE ?", "%无烟%", "%non-smoking%")
        .order(rating: :desc)
        .to_a
      
      raise "未找到#{@city}提供无烟客房的酒店" if @available_hotels.empty?
      
      {
        task: "请为张三预订#{@check_in_date.strftime('%Y年%m月%d日')}（明天）在#{@city}的无烟房，入住1晚。张三注重健康环境。",
        requirements: {
          beneficiary: '张三',
          city: @city,
          room_type: '无烟房',
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: 1,
          purpose: '注重健康环境'
        },
        hint: "在#{@city}筛选提供无烟客房的酒店（facilities包含'无烟'或'non-smoking'），优先选择高评分酒店。",
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
          .includes(:hotel, :hotel_room)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        @hotel_booking = all_bookings.first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      add_assertion "酒店提供无烟客房设施（核心要求）", weight: 40 do
        hotel = @hotel_booking.hotel
        is_non_smoking = hotel.facilities&.include?('无烟') ||
                         hotel.facilities&.downcase&.include?('non-smoking')
        
        expect(is_non_smoking).to eq(true),
          "酒店未提供无烟客房设施。要求: 无烟客房, 实际设施: #{hotel.facilities}（#{hotel.name}）"
      end
      
      add_assertion "入住人信息正确（张三）", weight: 15 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_guest_phone),
          "入住人电话错误。期望: #{@expected_guest_phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      add_assertion "入住日期和时长正确（#{@check_in_date.strftime('%m月%d日')}入住，住1晚）", weight: 15 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（明天）, 实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}（后天）, 实际: #{@hotel_booking.check_out_date}"
      end
      
      add_assertion "订单状态有效", weight: 5 do
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态无效。实际: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择评分最高的提供无烟客房的酒店（优先高评分）
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
      
      @available_hotels = Hotel
        .where(city: @city, data_version: 0)
        .where("facilities LIKE ? OR facilities LIKE ?", "%无烟%", "%non-smoking%")
        .order(rating: :desc)
        .to_a
    end
  end
end
