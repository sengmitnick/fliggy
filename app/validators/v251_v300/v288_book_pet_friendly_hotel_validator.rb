# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例288: 给张三预订宠物友好酒店（杭州，4天后入住，住3晚，携带宠物狗）
# 
# 任务描述:
#   张三计划带宠物狗到杭州旅行，需要预订允许携带宠物的酒店。
#   Agent 需要搜索标注"宠物友好"特性的酒店，完成2人的3晚预订。
# 
# 业务流程（6个关键步骤）：
#   1. 搜索杭州地区的酒店
#   2. 筛选标注"宠物友好"的酒店（features字段包含关键词）
#   3. 选择符合条件的酒店（任意一家即可）
#   4. 设置入住日期（4天后）和退房日期（住3晚）
#   5. 设置客房和入住人数（房间数量1间、成人2人、儿童0人）
#   6. 填写联系人信息（张三）并提交订单
# 
# 复杂度分析（6个关键点）：
#   1. 需要理解城市筛选：杭州地区的酒店
#   2. 需要理解特性匹配：宠物友好（允许携带宠物入住）
#   3. 需要理解数据源：Hotel.features 字段（标签/特性列表）需要正则匹配
#   4. 需要理解入住日期计算：check_in_date=4天后，check_out_date=入住日期+3天
#   5. 需要理解客房信息设置：rooms_count=1、adults_count=2、children_count=0
#   6. 需要理解联系人信息填写：使用乘客信息中的张三
#   ❌ 不能随机选择：必须精确选择标注"宠物友好"的酒店、正确计算入住日期
# 
# 评分标准（4项，总计100分）：
#   - 创建酒店预订（35%）
#   - 酒店标注"宠物友好"特性（30%）
#   - 入住人信息正确（张三）（20%）
#   - 入住日期正确（4天后，住3晚）（15%）
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v288_book_pet_friendly_hotel_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V251V300
  class V288BookPetFriendlyHotelValidator < BaseValidator
    self.validator_id = 'v288_book_pet_friendly_hotel_validator'
    self.task_id = 'c98da49b-44d4-45bb-848a-ddedf749cf01'
    self.title = '给张三预订宠物友好酒店（杭州，4天后入住，住3晚，携带宠物狗）'
    self.description = '预订允许携带宠物的酒店（杭州，4天后入住，携带宠物狗）'
    self.timeout_seconds = 300
    
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @city = '杭州'
      @check_in_date = Date.current + 4.days  # 4天后入住
      @check_out_date = @check_in_date + 3.days  # 住3晚
      
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
        task: "请给张三预订#{@city}的宠物友好酒店，我要带宠物狗一起旅行，#{@check_in_date.strftime('%Y年%-m月%-d日')}（4天后）入住，住#{(@check_out_date - @check_in_date).to_i}晚。重要：酒店必须标注'宠物友好'特性，允许携带宠物入住。",
        city: @city,
        check_in_date: @check_in_date.to_s,
        check_out_date: @check_out_date.to_s,
        nights: (@check_out_date - @check_in_date).to_i,
        guest_name: @expected_guest_name,
        pet_type: '宠物狗',
        features_required: '宠物友好',
        hint: "选择允许携带宠物的酒店（宠物友好）。查看酒店详情中的特性标签，必须包含'宠物友好'标识。入住人信息填写张三的姓名和电话。"
      }
    end
    
    def verify
      # 断言1: 创建酒店预订（35分）
      # 作用: 查询本次会话的酒店预订记录，确保预订成功
      # 查询逻辑: 
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 通过 joins(:hotel) 关联查询，筛选杭州的酒店
      #   - 按创建时间倒序，获取最新的预订
      add_assertion "创建了酒店预订", weight: 35 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店预订"
      end
      
      return unless @hotel_booking  # 保护后续断言
      
      # 断言2: 酒店标注"宠物友好"特性（30分）
      # 作用: 验证酒店是否允许携带宠物入住
      # 验证逻辑:
      #   - 检查 hotel.features 字段是否非空
      #   - 使用正则匹配关键词: 宠物友好
      #   - 不区分大小写（/i 标志）
      # 重要性: 携带宠物旅行必须选择宠物友好酒店
      add_assertion "酒店标注'宠物友好'特性", weight: 30 do
        hotel = @hotel_booking.hotel
        expect(hotel.features).to be_present, "酒店未配置特性标签信息"
        
        # 检查是否标注"宠物友好"
        has_pet_friendly = hotel.features.to_s.match?(/宠物友好/i)
        expect(has_pet_friendly).to be(true), 
          "酒店未标注'宠物友好'特性，不允许携带宠物。当前特性: #{hotel.features}"
      end
      
      # 断言3: 入住人信息正确（张三）（20分）
      # 作用: 验证入住人姓名和电话是否正确
      add_assertion "入住人信息正确（#{@expected_guest_name}）", weight: 20 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "入住人姓名错误。期望: #{@expected_guest_name}（张三），实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_guest_phone),
          "入住人联系电话错误。期望: #{@expected_guest_phone}（张三手机号），实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言4: 入住日期正确（4天后，住3晚）（15分）
      # 作用: 验证入住日期和退房日期是否正确
      add_assertion "入住日期正确（#{@check_in_date}，住#{(@check_out_date - @check_in_date).to_i}晚）", weight: 15 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（4天后），实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}（入住后3天），实际: #{@hotel_booking.check_out_date}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 查询宠物友好酒店
      # 注意: 使用 find 而非 where，因为 features 是文本字段，需要正则匹配
      hotel = Hotel
        .where(city: @city, data_version: 0)
        .find { |h| h.features.to_s.match?(/宠物友好/i) }
      
      raise "未找到#{@city}的宠物友好酒店" if hotel.nil?
      
      # 创建酒店预订
      HotelBooking.create!(
        hotel_room_id: hotel.hotel_rooms.first!.id,
        user_id: user.id,
        rooms_count: 1,
        adults_count: 2,  # 张三+1位同伴
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
