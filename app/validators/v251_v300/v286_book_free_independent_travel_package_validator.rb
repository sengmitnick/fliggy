# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例286: 给李四预订北京自由行3日游（张三+李四+王芳，7天后出发）
# 
# 任务描述:
#   李四、张三、王芳三人计划从深圳到北京进行3天2晚的自由行旅游。
#   Agent 需要预订自由出行类型的旅游产品（TourGroupProduct，tour_category='free_travel'），
#   但由于数据包中只有1日游产品，需要先扩展数据包以支持多日自由行。
# 
# 产品类型说明:
#   - TourGroupProduct 模型包含多种 tour_category 类型：
#     * free_travel: 自由行（自由出行，非跟团） ← 本用例使用
#     * group_tour: 跟团游（与陆生人拼团）
#     * private_group: 私家团（独立成团，不与陆生人拼团）
#   - 自由行 vs 跟团游 vs 私家团：
#     * 自由行：提供打包产品（机+酒），用户自由安排行程，无导游
#     * 跟团游：固定行程，导游带队，与其他游客拼团
#     * 私家团：固定行程，专属导游，独立成团不拼团
#   - 本验证用例使用 travel_type='自由出行'（free_travel 类别）
# 
# 业务流程（6个关键步骤）：
#   1. 搜索北京目的地的旅游产品（TourGroupProduct）
#   2. 筛选自由行类型产品（travel_type='自由出行'）
#   3. 筛选3日游产品（duration=3，2晚3天）
#   4. 设置出行人数（成人3人：张三、李四、王芳）
#   5. 选择出行日期（travel_date，7天后出发）
#   6. 填写联系人信息（李四）并提交订单
# 
# 复杂度分析（7个关键点）：
#   1. 需要理解旅游类型：travel_type='自由出行'（自由行，非跟团游、非独立成团）
#   2. 需要理解目的地筛选：北京地区的旅游产品
#   3. 需要理解行程时长：3日游（duration=3，2晚3天）
#   4. 需要理解人数设置：成人3人（张三、李四、王芳）、儿童0人
#   5. 需要理解联系人：李四作为联系人
#   6. 需要理解出行人列表：需要创建3个BookingTraveler记录（张三、李四、王芳）
#   7. 需要理解价格计算：总价 = 套餐价格 × 成人数量
#   ❌ 不能随机选择：必须精确选择北京+自由出行+3天的产品
# 
# 评分标准（8项，总计100分）：
#   - 创建旅游预订（20分）
#   - 目的地正确（北京）（15分）
#   - 旅游类型正确（自由出行）（20分）
#   - 行程天数正确（3天2晚）（10分）
#   - 联系人信息正确（李四）（10分）
#   - 成人数量正确（3人）（10分）
#   - 出行人信息正确（张三、李四、王芳）（15分）
# 
# 使用方法:
#   # 准备阶段
#   POST /api/tasks/v286_book_free_independent_travel_package_validator/start
#   
#   # Agent 通过界面操作完成预订...
#   
#   # 验证结果
#   POST /api/verify/:execution_id/result
module V251V300
  class V286BookFreeIndependentTravelPackageValidator < BaseValidator
    self.validator_id = 'v286_book_free_independent_travel_package_validator'
    self.task_id = '894541d3-6504-42a4-b182-14e38d262387'
    self.title = '给李四预订北京自由行3日游（张三+李四+王芳，7天后出发，3成人）'
    self.description = '预订北京自由行3日游（7天后出发，3成人：张三、李四、王芳）'
    self.timeout_seconds = 300
    
    # 准备阶段：设置任务参数
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @destination = '北京'
      @duration = 3  # 3天2晚
      @adult_count = 3  # 张三、李四、王芳
      @child_count = 0
      @travel_type = '自由出行'
      @travel_date = Date.current + 7.days  # 7天后出发
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 联系人：李四
      @expected_contact_name = @lisi.name
      @expected_contact_phone = @lisi.phone
      
      # 出行人列表（张三、李四、王芳）
      @expected_traveler_names = [@zhangsan.name, @lisi.name, @wangfang.name].sort
      
      # 查找符合条件的自由行产品（注意：查询基线数据 data_version=0）
      # 由于数据包中只有1日游的free_travel产品，这里需要先扩展数据包
      @product = TourGroupProduct
        .where(travel_type: @travel_type, duration: @duration, data_version: 0)
        .where("destination LIKE ?", "%#{@destination}%")
        .order(price: :asc)
        .first
      
      # 如果找不到产品，说明数据包需要扩展
      unless @product
        raise "数据包中缺少#{@destination}的#{@duration}日自由行产品，请先扩展tour_groups.rb数据包"
      end
      
      # 预查询套餐
      @package = @product.tour_packages.where(data_version: 0).order(price: :asc).first!
      
      # 确保用户余额充足
      total_price = @package.price * @adult_count
      if user.balance < total_price
        user.update!(balance: total_price + 2000)
      end
      
      # 返回给 Agent 的任务信息
      {
        task: "请给李四预订#{@destination}自由行#{@duration}日游，#{@adult_count}个成人（张三、李四、王芳），#{@travel_date.strftime('%Y年%-m月%-d日')}（7天后）出发。重要：必须选择自由出行类型的产品（非跟团游、非独立成团），成人数量必须是#{@adult_count}人。",
        destination: @destination,
        travel_type: @travel_type,
        travel_type_description: '自由出行（非跟团游、非独立成团）',
        duration: @duration,
        adult_count: @adult_count,
        child_count: @child_count,
        travel_date: @travel_date.to_s,
        contact_person: @expected_contact_name,
        travelers: '张三、李四、王芳',
        hint: "选择#{@destination}目的地、自由出行类型、#{@duration}天的产品。成人数量必须是#{@adult_count}人（张三、李四、王芳），联系人为李四。需要创建3个出行人记录（张三、李四、王芳）。"
      }
    end
    
    # 验证阶段：检查订单是否符合要求
    def verify
      # 断言1: 创建旅游预订（20分）
      add_assertion "创建了旅游预订", weight: 20 do
        all_bookings = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { travel_type: @travel_type })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .to_a
        
        expect(all_bookings).not_to be_empty, "未找到任何自由行订单"
        
        @bookings = all_bookings.select do |b|
          b.tour_group_product.destination&.include?(@destination)
        end
        
        expect(@bookings).not_to be_empty, "未找到#{@destination}的自由行订单"
        @booking = @bookings.first
      end
      
      return unless @booking
      
      # 断言2: 目的地正确（北京）（15分）
      add_assertion "目的地正确（#{@destination}）", weight: 15 do
        product = @booking.tour_group_product
        expect(product).not_to be_nil, "订单没有关联产品"
        expect(product.destination).to include(@destination),
          "目的地错误。期望包含: #{@destination}，实际: #{product.destination}"
      end
      
      # 断言3: 旅游类型正确（自由出行）（20分）
      add_assertion "旅游类型正确（#{@travel_type}）", weight: 20 do
        product = @booking.tour_group_product
        expect(product.travel_type).to eq(@travel_type),
          "旅游类型错误。期望: #{@travel_type}（自由行），实际: #{product.travel_type}"
      end
      
      # 断言4: 行程天数正确（3天2晚）（10分）
      add_assertion "行程天数正确（#{@duration}天）", weight: 10 do
        product = @booking.tour_group_product
        expect(product.duration).to eq(@duration),
          "行程天数错误。期望: #{@duration}天（2晚3天），实际: #{product.duration}天"
      end
      
      # 断言5: 联系人信息正确（李四）（10分）
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 10 do
        expect(@booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}（李四），实际: #{@booking.contact_name}"
        expect(@booking.contact_phone).to eq(@expected_contact_phone),
          "联系人电话错误。期望: #{@expected_contact_phone}（李四手机号），实际: #{@booking.contact_phone}"
      end
      
      # 断言6: 成人数量正确（3人）（10分）
      add_assertion "成人数量正确（#{@adult_count}人：张三、李四、王芳）", weight: 10 do
        expect(@booking.adult_count).to eq(@adult_count),
          "成人数量错误。期望: #{@adult_count}人（张三、李四、王芳），实际: #{@booking.adult_count}人"
        
        actual_child_count = @booking.child_count || 0
        expect(actual_child_count).to eq(@child_count),
          "儿童数量错误。期望: #{@child_count}人，实际: #{actual_child_count}人"
      end
      
      # 断言7: 出行人信息正确（张三、李四、王芳）（15分）
      add_assertion "出行人信息正确（张三、李四、王芳）", weight: 15 do
        travelers = @booking.booking_travelers.where(data_version: @data_version).to_a
        
        expect(travelers.size).to eq(3),
          "出行人数量不正确。期望: 3个出行人（张三、李四、王芳），实际: #{travelers.size}个出行人"
        
        traveler_names = travelers.map(&:traveler_name).sort
        
        expect(traveler_names).to eq(@expected_traveler_names),
          "出行人名单不正确。期望: #{@expected_traveler_names.join('、')}，实际: #{traveler_names.join('、')}"
        
        # 验证张三的身份证号
        zhangsan = travelers.find { |t| t.traveler_name == '张三' }
        expect(zhangsan).not_to be_nil, "未找到出行人张三"
        expect(zhangsan.id_number).to eq(@zhangsan.id_number),
          "张三身份证号错误。期望: #{@zhangsan.id_number}，实际: #{zhangsan.id_number}"
        
        # 验证李四的身份证号
        lisi = travelers.find { |t| t.traveler_name == '李四' }
        expect(lisi).not_to be_nil, "未找到出行人李四"
        expect(lisi.id_number).to eq(@lisi.id_number),
          "李四身份证号错误。期望: #{@lisi.id_number}，实际: #{lisi.id_number}"
        
        # 验证王芳的身份证号
        wangfang = travelers.find { |t| t.traveler_name == '王芳' }
        expect(wangfang).not_to be_nil, "未找到出行人王芳"
        expect(wangfang.id_number).to eq(@wangfang.id_number),
          "王芳身份证号错误。期望: #{@wangfang.id_number}，实际: #{wangfang.id_number}"
      end
    end
    
    # 模拟 AI Agent 操作：预订北京自由行3日游
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 查找符合条件的自由行产品
      target_product = TourGroupProduct
        .where(travel_type: @travel_type, duration: @duration, data_version: 0)
        .where("destination LIKE ?", "%#{@destination}%")
        .order(price: :asc)
        .first
      
      raise "未找到符合条件的自由行产品" unless target_product
      
      # 选择套餐（最便宜的）
      target_package = target_product.tour_packages.order(price: :asc).first
      raise "产品没有可用套餐" unless target_package
      
      # 计算总价
      total_price = target_package.price * @adult_count + target_package.child_price * @child_count
      
      # 创建订单
      booking = TourGroupBooking.create!(
        tour_group_product_id: target_product.id,
        tour_package_id: target_package.id,
        user_id: user.id,
        travel_date: @travel_date,
        adult_count: @adult_count,
        child_count: @child_count,
        contact_name: @lisi.name,
        contact_phone: @lisi.phone,
        insurance_type: 'none',
        total_price: total_price,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 创建出行人记录（张三、李四、王芳）
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: @zhangsan.name,
        id_number: @zhangsan.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: @lisi.name,
        id_number: @lisi.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: @wangfang.name,
        id_number: @wangfang.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
    end
    
    private
    
    # 保存执行状态数据
    def execution_state_data
      {
        destination: @destination,
        duration: @duration,
        adult_count: @adult_count,
        child_count: @child_count,
        travel_type: @travel_type,
        travel_date: @travel_date&.to_s,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone,
        expected_traveler_names: @expected_traveler_names
      }
    end
    
    # 从状态恢复实例变量
    def restore_from_state(data)
      @destination = data['destination']
      @duration = data['duration']
      @adult_count = data['adult_count']
      @child_count = data['child_count'] || 0
      @travel_type = data['travel_type']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      @expected_traveler_names = data['expected_traveler_names']
      
      # 重新查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
    end
  end
end
