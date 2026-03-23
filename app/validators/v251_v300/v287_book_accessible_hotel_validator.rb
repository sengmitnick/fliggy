# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例287: 给张三预订健身养生酒店（上海，3天后入住，住2晚）
# 
# 任务描述:
#   张三计划到上海旅行，需要预订配备健身养生设施的酒店。
#   Agent 需要搜索符合条件的酒店，完成1人的2晚预订。
# 
# 业务流程（6个关键步骤）：
#   1. 搜索上海地区的酒店
#   2. 筛选配备健身养生设施的酒店（facilities字段包含关键词）
#   3. 选择符合条件的酒店（价格最高的高端酒店设施更完善）
#   4. 设置入住日期（3天后）和退房日期（住2晚）
#   5. 设置客房和入住人数（房间数量1间、成1人、儿童0人）
#   6. 填写联系人信息（张三）并提交订单
# 
# 复杂度分析（6个关键点）：
#   1. 需要理解城市筛选：上海地区的酒店
#   2. 需要理解设施匹配：健身房、游泳池、水疗、桑拿、按摩、养生、美容等关键词
#   3. 需要理解数据源：Hotel.facilities 字段（文本描述）需要正则匹配
#   4. 需要理解入住日期计算：check_in_date=3天后，check_out_date=入住日期+2天
#   5. 需要理解客房信息设置：rooms_count=1、adults_count=1、children_count=0
#   6. 需要理解联系人信息填写：使用乘客信息中的张三
#   ❌ 不能随机选择：必须精确选择配备健身养生设施的酒店、正确计算入住日期
# 
# 评分标准（5项，总计100分）：
#   - 创建酒店预订（30%）
#   - 酒店配备健身养生设施（25%）
#   - 入住人信息正确（张三）（20%）
#   - 入住日期正确（3天后，住2晚）（15%）
#   - 订单状态正确（pending/paid）（10%）
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v287_book_accessible_hotel_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V251V300
  class V287BookAccessibleHotelValidator < BaseValidator
    self.validator_id = 'v287_book_accessible_hotel_validator'
    self.task_id = 'd72a4ed6-b4c8-40f7-b9cc-c0424c05be6a'
    self.title = '给张三预订健身养生酒店（上海，3天后入住，住2晚）'
    self.description = '预订配备健身养生设施的酒店（上海，3天后入住）'
    self.timeout_seconds = 300
    
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @city = '上海'
      @check_in_date = Date.current + 3.days  # 3天后入住
      @check_out_date = @check_in_date + 2.days  # 住2晚
      
      # 预查询乘客信息（张三）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @expected_guest_name = @zhangsan.name
      @expected_guest_phone = @zhangsan.phone
      
      # 确保用户余额充足
      if user.balance < 2000
        user.update!(balance: 3000)
      end
      
      # 返回给 Agent 的任务信息
      {
        task: "请给张三预订#{@city}的健身养生酒店，需要配备健身房、游泳池等养生设施。#{@check_in_date.strftime('%Y年%-m月%-d日')}（3天后）入住，住#{(@check_out_date - @check_in_date).to_i}晚。重要：酒店必须配备健身养生设施（健身房、游泳池、水疗、桑拿等）。",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: (@check_out_date - @check_in_date).to_i,
        guest_name: @expected_guest_name,
        facilities_required: '健身房、游泳池、水疗、桑拿、按摩、养生、美容',
        hint: "选择配备健身养生设施的酒店。查看酒店详情中的设施信息，必须包含健身房、游泳池等养生设施。入住人信息填写张三的姓名和电话。"
      }
    end
    
    def verify
      # 断言1: 创建酒店预订（30分）
      # 作用: 查询本次会话的酒店预订记录，确保预订成功
      # 查询逻辑: 
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 通过 joins(:hotel) 关联查询，筛选上海的酒店
      #   - 按创建时间倒序，获取最新的预订
      add_assertion "创建了酒店预订", weight: 30 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店预订"
      end
      
      return unless @hotel_booking  # 保护后续断言
      
      # 断言2: 酒店配备健身养生设施（25分）
      # 作用: 验证酒店是否配备健身养生相关设施
      # 验证逻辑:
      #   - 检查 hotel.facilities 字段是否非空
      #   - 使用正则匹配关键词: 健身|游泳|水疗|桑拿|按摩|养生|美容
      #   - 不区分大小写（/i 标志）
      add_assertion "酒店配备健身养生设施", weight: 25 do
        hotel = @hotel_booking.hotel
        expect(hotel.facilities).to be_present, "酒店未配置设施信息"
        
        # 检查是否有健身养生相关设施
        has_fitness_features = hotel.facilities.to_s.match?(/健身|游泳|水疗|桑拿|按摩|养生|美容/i)
        expect(has_fitness_features).to be(true), 
          "酒店未配备健身养生设施。当前设施: #{hotel.facilities}"
      end
      
      # 断言3: 入住人信息正确（张三）（20分）
      # 作用: 验证入住人姓名和电话是否正确
      add_assertion "入住人信息正确（#{@expected_guest_name}）", weight: 20 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}（张三），实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_guest_phone),
          "入住人联系电话错误。期望: #{@expected_guest_phone}（张三手机号），实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言4: 入住日期正确（3天后，住2晚）（15分）
      # 作用: 验证入住日期和退房日期是否正确
      add_assertion "入住日期正确（#{@check_in_date}，住#{(@check_out_date - @check_in_date).to_i}晚）", weight: 15 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（3天后），实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}（入住后2天），实际: #{@hotel_booking.check_out_date}"
      end
      
      # 断言5: 订单状态正确（10分）
      # 作用: 验证订单状态是否合法
      add_assertion "订单状态正确（pending/paid）", weight: 10 do
        valid_statuses = ['pending', 'paid']
        expect(valid_statuses).to include(@hotel_booking.status),
          "酒店订单状态错误。期望: #{valid_statuses.join('/')}, 实际: #{@hotel_booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 查询配备健身养生设施的酒店
      # 注意: 使用 select 而非 where，因为 facilities 是文本字段，需要正则匹配
      hotels_with_fitness = Hotel
        .where(city: @city, data_version: 0)
        .select { |h| h.facilities.to_s.match?(/健身|游泳|水疗|桑拿|按摩|养生|美容/i) }
      
      # 选择价格最高的酒店（高端酒店设施更完善）
      hotel = hotels_with_fitness.max_by(&:price)
      raise "未找到配备健身养生设施的酒店" if hotel.nil?
      
      # 创建酒店预订
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 1,
        children_count: 0,
        hotel_id: hotel.id,
        check_in_date: @check_in_date,
        check_out_date: @check_out_date,
        guest_name: zhangsan.name,
        guest_phone: zhangsan.phone,
        payment_method: '花呗',
        total_price: hotel.price * (@check_out_date - @check_in_date).to_i,
        status: 'pending',
        data_version: @data_version
      )
    end
    
    private
    
    # 保存执行状态数据
    def execution_state_data
      {
        city: @city,
        check_in_date: @check_in_date&.to_s,
        check_out_date: @check_out_date&.to_s,
        expected_guest_name: @expected_guest_name,
        expected_guest_phone: @expected_guest_phone
      }
    end
    
    # 从状态恢复实例变量
    def restore_from_state(data)
      @city = data['city']
      @check_in_date = Date.parse(data['check_in_date']) if data['check_in_date']
      @check_out_date = Date.parse(data['check_out_date']) if data['check_out_date']
      @expected_guest_name = data['expected_guest_name']
      @expected_guest_phone = data['expected_guest_phone']
    end
  end
end
