# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例301: 李四6天后要去深圳健身训练，需要预订配备专业健身房和游泳池的酒店住4晚
# 
# 任务描述:
#   李四是健身爱好者，计划6天后到深圳进行为期4晚的健身训练。
#   Agent 需要搜索配备专业健身房和游泳池的酒店，完成1人的4晚预订。
# 
# 业务流程（6个关键步骤）：
#   1. 搜索深圳地区的酒店
#   2. 筛选配备专业健身房和游泳池的酒店（facilities字段包含关键词）
#   3. 选择符合条件的酒店（评分最高的酒店设施更专业）
#   4. 设置入住日期（6天后）和退房日期（住4晚）
#   5. 设置客房和入住人数（房间数量1间、成人1人、儿童0人）
#   6. 填写联系人信息（李四）并提交订单
# 
# 复杂度分析（6个关键点）：
#   1. 需要理解城市筛选：深圳地区的酒店
#   2. 需要理解设施匹配：专业健身房、游泳池、运动设施等关键词
#   3. 需要理解数据源：Hotel.facilities 字段（文本描述）需要正则匹配
#   4. 需要理解入住日期计算：check_in_date=6天后，check_out_date=入住日期+4天
#   5. 需要理解客房信息设置：rooms_count=1、adults_count=1、children_count=0
#   6. 需要理解联系人信息填写：使用乘客信息中的李四
#   ❌ 不能随机选择：必须精确选择配备专业健身设施的酒店、正确计算入住日期
# 
# 评分标准（7项，总计100分）：
#   1. 创建了酒店预订（20分）
#   2. 酒店城市正确（深圳）（15分）
#   3. 选择配备专业健身房的酒店（35分）- facilities字段包含健身/游泳/运动关键词（核心业务逻辑）
#   4. 入住日期正确（6天后入住，住4晚）（10分）
#   5. 住客信息正确（李四的姓名、电话）（10分）
#   6. 住宿天数≥3晚（5分）- 实际要求4晚
#   7. 房间数和人数正确（1间房，1成人，0儿童）（5分）
# 
# 使用方法:
#   rake validator:simulate_single[v301_book_sports_fitness_tour_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
module V301V350
  class V301BookSportsFitnessTourValidator < BaseValidator
    self.validator_id = 'v301_book_sports_fitness_tour_validator'
    self.task_id = 'c0e90a56-cd9b-4ef3-8486-8bc3e076e331'
    self.title = '李四6天后要去深圳健身训练，需要预订配备专业健身房和游泳池的酒店住4晚'
    self.description = '李四要去深圳健身训练，需要配备专业健身房和游泳池的酒店'
    self.timeout_seconds = 300
    
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @city = '深圳'
      @check_in_date = Date.current + 6.days  # 6天后入住
      @check_out_date = @check_in_date + 4.days  # 住4晚
      
      # 预查询乘客信息（李四）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @expected_guest_name = @lisi.name
      @expected_guest_phone = @lisi.phone
      
      # 确保用户余额充足
      if user.balance < 5000
        user.update!(balance: 7000)
      end
      
      # 返回给 Agent 的任务信息
      {
        task: "李四6天后要去深圳进行健身训练，需要预订配备专业健身房和游泳池的酒店。#{@check_in_date.strftime('%Y年%-m月%-d日')}（6天后）入住，住#{(@check_out_date - @check_in_date).to_i}晚。重要：酒店必须配备专业健身房、游泳池等运动设施，适合健身训练。",
        requirements: {
          beneficiary: '李四',
          city: @city,
          facilities_required: '专业健身房、游泳池、运动设施',
          check_in_date: @check_in_date.to_s,
          check_out_date: @check_out_date.to_s,
          nights: (@check_out_date - @check_in_date).to_i,
          purpose: '健身训练'
        },
        hint: "在#{@city}筛选配备专业健身房和游泳池的酒店。查看酒店详情中的设施信息，必须包含健身房、游泳池等运动设施。入住人信息填写李四的姓名和电话。"
      }
    end
    
    def verify
      # 断言1: 创建了酒店预订（20分）
      # 作用: 查询本次会话的酒店预订记录，确保预订成功
      # 查询逻辑: 
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 通过 joins(:hotel) 关联查询，筛选深圳的酒店
      #   - 按创建时间倒序，获取最新的预订
      add_assertion "创建了酒店预订", weight: 20 do
        @hotel_booking = HotelBooking
          .joins(:hotel)
          .where(hotels: { city: @city })  # 核心实体过滤
          .where(data_version: @data_version)  # 会话隔离（必须）
          .order(created_at: :desc)
          .first
        expect(@hotel_booking).not_to be_nil, "未找到#{@city}的酒店预订"
      end
      
      return unless @hotel_booking  # 保护后续断言
      
      # 断言2: 酒店城市正确（深圳）（15分）
      # 作用: 验证酒店所在城市是否正确
      add_assertion "酒店城市正确（#{@city}）", weight: 15 do
        expect(@hotel_booking.hotel.city).to eq(@city),
          "酒店城市错误。期望: #{@city}，实际: #{@hotel_booking.hotel.city}"
      end
      
      # 断言3: 选择配备专业健身房的酒店（35分）- 核心业务逻辑
      # 作用: 验证酒店是否配备专业健身房、游泳池等运动设施
      # 验证逻辑:
      #   - 检查 hotel.facilities 字段是否非空
      #   - 使用正则匹配关键词: 健身|游泳池|泳池|运动
      #   - 不区分大小写（/i 标志）
      add_assertion "选择配备专业健身房的酒店（核心要求）", weight: 35 do
        hotel = @hotel_booking.hotel
        expect(hotel.facilities).to be_present, "酒店未配置设施信息"
        
        # 检查是否有专业健身运动相关设施
        has_fitness = hotel.facilities.to_s.match?(/健身|游泳池|泳池|运动/i)
        expect(has_fitness).to be(true), 
          "酒店未配备专业健身运动设施。当前酒店: #{hotel.name}，设施: #{hotel.facilities}"
      end
      
      # 断言4: 入住日期正确（6天后入住，住4晚）（10分）
      # 作用: 验证入住日期和退房日期是否正确
      add_assertion "入住日期正确（#{@check_in_date}，住#{(@check_out_date - @check_in_date).to_i}晚）", weight: 10 do
        expect(@hotel_booking.check_in_date).to eq(@check_in_date),
          "入住日期错误。期望: #{@check_in_date}（6天后），实际: #{@hotel_booking.check_in_date}"
        expect(@hotel_booking.check_out_date).to eq(@check_out_date),
          "退房日期错误。期望: #{@check_out_date}（入住后4天），实际: #{@hotel_booking.check_out_date}"
      end
      
      # 断言5: 住客信息正确（李四的姓名、电话）（10分）
      # 作用: 验证入住人姓名和电话是否正确
      add_assertion "住客信息正确（#{@expected_guest_name}）", weight: 10 do
        expect(@hotel_booking.guest_name).to eq(@expected_guest_name),
          "住客姓名错误。期望: #{@expected_guest_name}（李四），实际: #{@hotel_booking.guest_name}"
        expect(@hotel_booking.guest_phone).to eq(@expected_guest_phone),
          "联系电话错误。期望: #{@expected_guest_phone}（李四手机号），实际: #{@hotel_booking.guest_phone}"
      end
      
      # 断言6: 住宿天数≥3晚（5分）
      # 作用: 验证住宿天数是否满足最低要求（实际要求4晚）
      add_assertion "住宿天数≥3晚", weight: 5 do
        actual_nights = (@hotel_booking.check_out_date - @hotel_booking.check_in_date).to_i
        expect(actual_nights).to be >= 3,
          "住宿天数不足。期望≥3晚，实际: #{actual_nights}晚"
      end
      
      # 断言7: 房间数和人数正确（1间房，1成人，0儿童）（5分）
      # 作用: 验证房间数量和入住人数是否正确
      add_assertion "房间数和人数正确（1间房，1成人，0儿童）", weight: 5 do
        expect(@hotel_booking.rooms_count).to eq(1),
          "房间数错误。期望: 1间房，实际: #{@hotel_booking.rooms_count}间房"
        expect(@hotel_booking.adults_count).to eq(1),
          "成人数错误。期望: 1成人，实际: #{@hotel_booking.adults_count}成人"
        expect(@hotel_booking.children_count).to eq(0),
          "儿童数错误。期望: 0儿童，实际: #{@hotel_booking.children_count}儿童"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      
      # 查询配备专业健身运动设施的酒店
      # 注意: 使用 select 而非 where，因为 facilities 是文本字段，需要正则匹配
      hotels_with_fitness = Hotel
        .where(city: @city, data_version: 0)
        .select { |h| h.facilities.to_s.match?(/健身|游泳池|泳池|运动/i) }
      
      # 选择评分最高的酒店（高评分酒店设施更专业）
      hotel = hotels_with_fitness.max_by(&:rating)
      raise "未找到配备专业健身运动设施的酒店" if hotel.nil?
      
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
        guest_name: lisi.name,
        guest_phone: lisi.phone,
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
