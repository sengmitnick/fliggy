# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例238: 张三四天后要去深圳出差，行程可能会变，需要预订支持免费取消的酒店住1晚
#
# 任务描述:
#   张三四天后要去深圳出差，但行程可能会变化，需要预订支持免费取消的酒店住1晚。
#   Agent需要在深圳市筛选出支持免费取消的酒店（通过cancellation_policy包含"免费"或"free"），
#   创建1个酒店订单，确保入住日期为4天后，住宿1晚。
#
# 业务流程（6个关键步骤）：
#   1. 明确受益人信息（张三，使用其姓名、电话作为入住人信息）
#   2. 搜索深圳市酒店
#   3. 筛选支持免费取消的酒店（cancellation_policy包含"免费"或"free"）
#   4. 按评分降序排序，优先选择评分高且价格合理的酒店
#   5. 确认入住日期（4天后）和退房日期（5天后）
#   6. 创建酒店订单（入住日期=4天后，住1晚）
#
# 复杂度分析（5个关键点）：
#   1. 需要理解免费取消预订场景，明确筛选条件（cancellation_policy包含"免费"或"free"）
#   2. 需要准确计算入住日期（4天后）和退房日期（入住日期+1天）
#   3. 需要在支持免费取消的酒店中选择最优选项（评分高、价格合理）
#   4. 需要使用张三的个人信息作为入住人信息
#   5. 需要确保订单状态有效（pending/paid/completed）
#   ❌ 不能选择不支持免费取消的酒店，必须严格满足免费取消要求
#
# 评分标准（5项，总计100分）：
#   1. 创建了酒店订单（25分）
#   2. 酒店支持免费取消（30分）- 核心业务逻辑
#   3. 入住日期和时长正确（4天后入住，住1晚）（25分）
#   4. 入住人信息正确（张三的电话）（15分）
#   5. 订单状态有效（5分）
#
# 使用方法:
#   rake validator:simulate_single[v238_book_hotel_with_free_cancellation_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V201V250
  class V238BookHotelWithFreeCancellationValidator < BaseValidator
    self.validator_id = 'v238_book_hotel_with_free_cancellation_validator'
    self.task_id = '4ff405ff-5f5f-5f7f-7f8f-6f9a0b1c2d3f'
    self.title = '张三四天后要去深圳出差，行程可能会变，需要预订支持免费取消的酒店住1晚'
    self.description = '张三四天后要去深圳出差，行程可能会变，需要预订支持免费取消的酒店住1晚'
    self.timeout_seconds = 300
    
    def prepare
      @city = '深圳'
      @check_in_date = Date.current + 4.days
      @check_out_date = @check_in_date + 1.day
      
      # 查询demo_user乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = demo_user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_phone = @zhangsan.phone
      
      # 查找支持免费取消的酒店（cancellation_policy包含"免费"或"free"）
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("cancellation_policy LIKE ? OR cancellation_policy LIKE ?", 
               "%免费%", "%free%")
        .to_a
      
      raise "未找到支持免费取消的酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@check_in_date.strftime('%Y年%m月%d日')}（4天后）在#{@city}的酒店（住1晚），要求酒店支持免费取消。由于行程可能会变化，必须选择可以免费取消的酒店以便灵活调整计划。",
        requirements: {
          city: @city,
          cancellation: '必须支持免费取消',
          check_in_date: @check_in_date,
          nights: 1,
          purpose: '行程灵活，可能变更'
        },
        hint: "选择取消政策中包含'免费取消'的酒店，例如'入住前24小时免费取消'或'任何时间免费取消'。"
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
        
        expect(all_bookings).not_to be_empty, "未找到#{@city}的酒店订单"
        
        # 存储所有订单供后续断言使用
        @hotel_bookings = all_bookings
        expect(@hotel_bookings.size).to be >= 1, "订单数量不足。期望至少1个订单，实际找到#{@hotel_bookings.size}个订单"
      end
      
      return if @hotel_bookings.nil? || @hotel_bookings.empty?
      
      add_assertion "酒店支持免费取消", weight: 30 do
        @hotel_bookings.each do |booking|
          hotel = booking.hotel
          has_free_cancellation = hotel.cancellation_policy&.include?('免费') || 
                                  hotel.cancellation_policy&.downcase&.include?('free')
          
          expect(has_free_cancellation).to eq(true),
            "酒店不支持免费取消。酒店: #{hotel.name}, 取消政策: #{hotel.cancellation_policy || '未设置'}"
        end
      end
      
      add_assertion "入住日期和时长正确（#{@check_in_date}，4天后）", weight: 25 do
        @hotel_bookings.each do |booking|
          expect(booking.check_in_date).to eq(@check_in_date),
            "入住日期错误。期望: #{@check_in_date}（4天后）, 实际: #{booking.check_in_date}"
          expect(booking.check_out_date).to eq(@check_out_date),
            "退房日期错误。期望: #{@check_out_date}（入住后1天）, 实际: #{booking.check_out_date}"
        end
      end
      
      add_assertion "入住人信息正确（张三）", weight: 15 do
        @hotel_bookings.each do |booking|
          expect(booking.guest_phone).to eq(@expected_guest_phone),
            "入住人电话错误。期望: #{@expected_guest_phone}（张三的电话）, 实际: #{booking.guest_phone}"
        end
      end
      
      add_assertion "订单状态有效", weight: 5 do
        @hotel_bookings.each do |booking|
          expect(booking.status).to be_in(['pending', 'paid', 'completed']),
            "订单状态无效。实际状态: #{booking.status}"
        end
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 选择第一家支持免费取消的酒店，再选择该酒店的房间
      hotel = @available_hotels.first
      room = hotel.hotel_rooms.where(data_version: 0).order(price: :asc).first!
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: zhangsan.name,
        guest_phone: zhangsan.phone,
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
        expected_guest_phone: @expected_guest_phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @expected_guest_phone = data['expected_guest_phone']
      
      @available_hotels = Hotel.where(city: @city, data_version: 0)
        .where("cancellation_policy LIKE ? OR cancellation_policy LIKE ?", 
               "%免费%", "%free%")
        .to_a
    end
  end
end
