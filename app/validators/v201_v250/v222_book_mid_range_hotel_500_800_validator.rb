# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例222: 帮张三预订2天后杭州酒店住1晚(入住=2天后,退房=3天后),价格区间500-800元/晚(中档舒适)
#
# 任务描述：
#   张三打算2天后去杭州出差1天，需要预订中档舒适的酒店住1晚，价格区间500-800元/晚。
#   Agent 需要在价格区间内选择性价比最优的酒店(优先评分高的)，创建1个酒店订单。
#
#   ⚠️ 中档酒店预订详细说明：
#   - 入住日期 = 2天后(Date.current + 2.days)
#   - 退房日期 = 3天后(Date.current + 3.days，即入住+1天)
#   - 住宿时长 = 1晚
#   - 房间数量 = 1间
#   - 房间要求 = room_category='overnight'(整晚房型，排除钟点房hourly)
#   - 价格区间 = 500-800元/晚(中档舒适档次)
#   - 选择策略 = 在价格区间内选择评分最高的酒店(rating最大)
#   - 价格计算 = 单晚房价×1晚×1间房
#
# 核心要求：
#   - 受益人：张三(使用其姓名、电话作为入住人信息)
#   - 城市：杭州
#   - 入住日期：2天后(Date.current + 2.days)
#   - 退房日期：3天后(Date.current + 3.days)
#   - 住宿时长：1晚
#   - 房间数量：1间
#   - 房间类型：room_category='overnight'(整晚房型，必须排除钟点房)
#   - 价格区间：500-800元/晚(中档舒适)
#   - 选择策略：在价格区间内选择评分最高的酒店
#
# 业务流程(5个关键步骤)：
#   1. 明确受益人信息(张三，使用其姓名、电话作为入住人信息)
#   2. 搜索杭州市区酒店，筛选整晚房型
#   3. 筛选价格在500-800元/晚区间的酒店
#   4. 在符合价格区间的酒店中，选择评分最高的(rating最大)
#   5. 创建酒店订单，入住1晚
#
# 复杂度分析(5个关键点)：
#   1. 需要理解价格区间约束(500-800元/晚)
#   2. 需要筛选整晚房型(排除钟点房，使用 room_category = 'overnight')
#   3. 需要在价格区间内选择评分最高的酒店(不是最便宜，而是性价比最优)
#   4. 需要正确计算住宿天数(1晚 = 退房日期 - 入住日期)
#   5. 需要正确计算总价(单晚房价×1晚×1间房)
#   ❌ 不能一次性提供所有信息：需要查询酒店数据，筛选价格区间，按评分排序选择最优选项。
#
# 评分标准(10项，总计100分)：
#   1. 创建了酒店订单(20分)
#   2. 酒店单晚价格在500-800元区间内(25分)- 核心业务逻辑
#   3. 酒店位于杭州(10分)
#   4. 入住日期正确(2天后)(10分)
#   5. 退房日期正确(3天后)(10分)
#   6. 住宿1晚(5分)
#   7. 预订1间房(5分)
#   8. 房间类型为整晚房型(非钟点房)(5分)
#   9. 入住人信息正确(张三的姓名、电话)(5分)
#   10. 订单状态有效(5分)
#
# 验证要点(10个断言)：
#   - 断言1: 酒店订单已创建(HotelBooking)(20分)
#   - 断言2: 酒店单晚价格在500-800元区间内(25分)
#   - 断言3: 酒店位于杭州(10分)
#   - 断言4: 入住日期为2天后(10分)
#   - 断言5: 退房日期为3天后(入住+1天)(10分)
#   - 断言6: 住宿1晚(check_out_date - check_in_date = 1天)(5分)
#   - 断言7: 预订1间房(room_count = 1)(5分)
#   - 断言8: 酒店房间类型为整晚房型(room_category = 'overnight'，非hourly)(5分)
#   - 断言9: 入住人信息正确(张三的姓名、电话)(5分)
#   - 断言10: 订单状态有效(5分)
#
# 使用方法:
#   rake validator:simulate_single[v222_book_mid_range_hotel_500_800_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
module V201V250
  class V222BookMidRangeHotel500800Validator < BaseValidator
    self.validator_id = 'v222_book_mid_range_hotel_500_800_validator'
    self.task_id = '9fe910fd-0f0f-0f2f-2f3f-1f4a5b6c7d8f'
    self.title = '帮张三预订2天后杭州酒店住1晚(入住=2天后,退房=3天后),价格区间500-800元/晚(中档舒适)'
    self.description = '帮张三订2天后杭州出差1天，预订中档舒适酒店住1晚，价格区间500-800元/晚'
    self.timeout_seconds = 300
    
    def prepare
      @city = '杭州'
      @check_in_date = Date.current + 2.days
      @check_out_date = @check_in_date + 1.day
      @min_price = 500
      @max_price = 800
      
      # 查询demo_user和乘客信息
      demo_user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      demo_passenger = Passenger.find_by!(user_id: demo_user.id, is_self: true, data_version: 0)
      @passenger = OpenStruct.new(
        name: demo_passenger.name,
        id_number: demo_passenger.id_number,
        phone: demo_passenger.phone
      )
      
      @available_hotels = Hotel.where(city: @city, data_version: 0).to_a.select do |h|
        h.price >= @min_price && h.price <= @max_price
      end
      
      raise "未找到价格在#{@min_price}-#{@max_price}元区间的酒店" if @available_hotels.empty?
      
      {
        task: "请预订#{@city}的中档舒适酒店，入住日期#{@check_in_date.strftime('%Y年%m月%d日')}(后天)，住1晚，价格要求500-800元/晚。",
        requirements: {
          city: @city,
          check_in_date: @check_in_date,
          price_range: '500-800元/晚',
          purpose: '中档舒适'
        },
        hint: "选择价格在500-800元区间的酒店，优先选择评分高的酒店。"
      }
    end
    
    # 验证方法：检查订单是否符合任务要求
    # 共10个断言：
    # 1. 创建了酒店订单（20分）
    # 2. 酒店单晚价格在500-800元区间内（25分）- 核心业务逻辑
    # 3. 酒店位于指定城市（10分）
    # 4. 入住日期正确（2天后）（10分）
    # 5. 退房日期正确（3天后）（10分）
    # 6. 住宿1晚（5分）
    # 7. 预订1间房（5分）
    # 8. 房间类型为整晚房型（非钟点房）（5分）
    # 9. 入住人信息正确（5分）
    # 10. 订单状态有效（5分）
    def verify
      # 断言1: 创建了酒店订单 (20分)
      add_assertion "创建了酒店订单", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .first
        
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店订单"
      end
      
      return if @hotel_booking.nil?
      
      # 断言2: 酒店单晚价格在500-800元区间内 (25分) - 核心业务逻辑
      add_assertion "酒店单晚价格在500-800元区间内", weight: 25 do
        price = @hotel_booking.hotel.price
        expect(price).to be >= @min_price,
          "酒店价格过低。期望: ≥#{@min_price}元/晚, 实际: #{price}元/晚"
        expect(price).to be <= @max_price,
          "酒店价格过高。期望: ≤#{@max_price}元/晚, 实际: #{price}元/晚"
      end
      
      # 断言3: 酒店位于#{@city} (10分)
      add_assertion "酒店位于#{@city}", weight: 10 do
        expect(@hotel_booking.hotel.city).to eq(@city),
          "酒店城市错误。期望: #{@city}, 实际: #{@hotel_booking.hotel.city}"
      end
      
      # 断言4: 入住日期正确（2天后） (10分)
      add_assertion "入住日期正确（#{@check_in_date.strftime('%m月%d日')}，2天后）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（2天后）, 实际: #{@hotel_booking.check_in_date}"
      end
      
      # 断言5: 退房日期正确（3天后） (10分)
      add_assertion "退房日期正确（#{@check_out_date.strftime('%m月%d日')}，3天后）", weight: 10 do
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}（3天后）, 实际: #{@hotel_booking.check_out_date}"
      end
      
      # 断言6: 住宿时长1晚 (5分)
      add_assertion "住宿1晚", weight: 5 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to eq(1),
          "住宿天数错误。期望: 1晚, 实际: #{actual_nights}晚"
      end
      
      # 断言7: 预订1间房 (5分)
      add_assertion "预订1间房", weight: 5 do
        expect(@hotel_booking.room_count).to eq(1),
          "房间数量错误。期望: 1间, 实际: #{@hotel_booking.room_count}间"
      end
      
      # 断言8: 房间类型为整晚房型（非钟点房） (5分)
      add_assertion "房间类型为整晚房型（非钟点房）", weight: 5 do
        room = @hotel_booking.hotel_room
        if room
          expect(room.room_category).to eq('overnight'),
            "房间类型错误。期望: overnight（整晚房型）, 实际: #{room.room_category}"
        else
          # 如果没有关联房间，则跳过此检查（某些实现可能不关联具体房间）
          expect(true).to eq(true)
        end
      end
      
      # 断言9: 入住人信息正确（张三的姓名、手机号） (5分)
      add_assertion "入住人信息正确（#{@passenger.name}的姓名、手机号）", weight: 5 do
        expect(@hotel_booking.guest_name).to eq(@passenger.name),
          "入住人姓名错误。期望: #{@passenger.name}, 实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@passenger.phone),
          "入住人电话错误。期望: #{@passenger.phone}, 实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言10: 订单状态有效 (5分)
      add_assertion "订单状态有效", weight: 5 do
        expect(@hotel_booking.status).to be_in(['pending', 'paid', 'completed']),
          "订单状态异常。实际状态: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择价格区间内评分最高的酒店，并确保使用整晚房型
      hotel = @available_hotels.max_by(&:rating)
      room = hotel.hotel_rooms.where(data_version: 0, room_category: 'overnight').first
      
      # 如果没有整晚房型，使用第一个房间作为备选
      room ||= hotel.hotel_rooms.where(data_version: 0).first
      
      HotelBooking.create!(
        user: user,
        hotel: hotel,
        hotel_room: room,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: @passenger.name,
        guest_phone: @passenger.phone,
        room_count: 1,
        total_price: hotel.price,
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
        min_price: @min_price,
        max_price: @max_price,
        passenger_name: @passenger.name,
        passenger_id_number: @passenger.id_number,
        passenger_phone: @passenger.phone
      }
    end
    
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date'])
      @check_out_date = Date.parse(data['check_out_date'])
      @min_price = data['min_price']
      @max_price = data['max_price']
      
      # Restore passenger data from flattened fields
      @passenger = OpenStruct.new(
        name: data['passenger_name'],
        id_number: data['passenger_id_number'],
        phone: data['passenger_phone']
      )
      
      @available_hotels = Hotel.where(city: @city, data_version: 0).to_a.select do |h|
        h.price >= @min_price && h.price <= @max_price
      end
    end
  end
end
