# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例112: 给李四预订上海自由行一日游（张三和李四，5天后出发）
#
# 任务描述:
#   用户李四想预订上海自由行一日游，2成人（张三和李四），5天后出发，当天往返。
#   要求选择自由出行类型的一日游产品。
#   Agent 需要在符合条件的产品中选择合适的完成预订。
#
# 业务流程（5个关键步骤）：
#   1. 搜索上海目的地的自由行产品（travel_type='自由出行'）
#   2. 筛选一日游产品（duration=1）
#   3. 设置出行日期（5天后出发）、人数（2成人0儿童）
#   4. 填写联系人信息（李四）和游客信息（张三、李四）
#   5. 选择合适的套餐并提交订单
#
# 复杂度分析（5个关键点）：
#   1. 需要理解旅游类型：travel_type='自由出行'（自由行，非跟团游、非独立成团）
#   2. 需要理解行程时长：duration=1（一日游，当天往返）
#   3. 需要理解出行日期计算：5天后出发（Date.current + 5.days）
#   4. 需要理解联系人和游客信息：联系人李四，游客张三和李四（2人）
#   5. 需要正确填写游客身份信息：姓名 + 身份证号（使用Passenger表中的信息）
#   ❌ 不能随机选择：必须精确匹配旅游类型、行程天数、目的地、人数
#
# 评分标准（7项，总计100分）：
#   - 订单已创建（20分）
#   - 目的地正确（上海）（15分）
#   - 旅游类型正确（自由出行）（20分）
#   - 天数正确（1天一日游）（10分）
#   - 联系人信息正确（张三或李四）（10分）
#   - 人数正确（2成人0儿童）（10分）
#   - 游客信息正确（张三、李四）（15分）
module V101V150
  class V112FreeTravelPackageValidator < BaseValidator
    self.validator_id = 'v112_free_travel_package_validator'
    self.task_id = '2d8eeaf8-2fa3-41a1-be59-669915973d05'
    self.title = '给李四预订上海自由行一日游（张三和李四，5天后出发）'
    self.description = '预订上海自由行一日游（张三和李四，5天后出发）'
    self.timeout_seconds = 300
  
    def prepare
      @destination = '上海'
      @duration = 1
      @adult_count = 2
      @child_count = 0
      @travel_type = '自由出行'
      @travel_date = Date.current + 5.days  # 5天后出发
    
      # 预查询李四和张三的乘客信息（避免 simulate 中查询 data_version: 0）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      
      # 联系人可以是张三或李四
      @allowed_contacts = [
        { name: @zhangsan.name, phone: @zhangsan.phone },
        { name: @lisi.name, phone: @lisi.phone }
      ]
      @expected_traveler_names = [@zhangsan.name, @lisi.name].sort
    
      # 查找符合条件的自由行产品
      @qualified_products = TourGroupProduct.where(
        travel_type: @travel_type,
        duration: @duration,
        data_version: 0
      ).where("destination LIKE ?", "%#{@destination}%")
    
      # 找到价格适中的产品
      @target_product = @qualified_products.order(:price).first
    
      {
        task: "请预订#{@destination}自由行一日游，#{@adult_count}个成人（张三和李四），当天往返（#{@travel_date.strftime('%Y年%m月%d日')}出发）",
        requirements: {
          destination: @destination,
          travel_type: @travel_type,
          travel_type_description: '自由出行（非跟团游、非独立成团）',
          duration: @duration,
          adult_count: @adult_count,
          child_count: @child_count,
          travel_date: @travel_date.to_s,
          inclusions: '包含机票和酒店',
          travelers: '张三和李四'
        },
        hint: "系统中有多个#{@destination}一日游产品可选，请选择自由出行类型的一日游产品，2个成人（张三和李四）",
        statistics: {
          total_products: @qualified_products.count,
          price_range: {
            min: @qualified_products.minimum(:price),
            max: @qualified_products.maximum(:price)
          }
        }
      }
    end
  
    def verify
      # 断誀1: 订单已创建（权重20%）
      add_assertion "订单已创建", weight: 20 do
        all_bookings = TourGroupBooking.joins(:tour_group_product)
                                       .where(tour_group_products: { travel_type: @travel_type })
                                       .where(data_version: @data_version)
                                       .order(created_at: :desc)
                                       .to_a
      
        @bookings = all_bookings.select do |b|
          b.tour_group_product.destination&.include?(@destination)
        end
      
        expect(@bookings).not_to be_empty, "未找到任何#{@destination}自由行订单"
        @booking = @bookings.first
      end
    
      return if @bookings.nil? || @bookings.empty?
    
      # 断誀2: 目的地正确（权重15%）
      add_assertion "目的地正确（#{@destination}）", weight: 15 do
        expect(@booking.tour_group_product.destination).to include(@destination),
          "目的地错误。期望包含: #{@destination}，实际: #{@booking.tour_group_product.destination}"
      end
    
      # 断誀3: 旅游类型正确（权重20%）
      add_assertion "旅游类型正确（自由出行）", weight: 20 do
        expect(@booking.tour_group_product.travel_type).to eq(@travel_type),
          "旅游类型错误。期望: #{@travel_type}（自由行），实际: #{@booking.tour_group_product.travel_type}"
      end
    
      # 断誀4: 天数正确（权重10%）
      add_assertion "天数正确（#{@duration}天一日游）", weight: 10 do
        expect(@booking.tour_group_product.duration).to eq(@duration),
          "天数错误。期望: #{@duration}天（一日游），实际: #{@booking.tour_group_product.duration}天"
      end
    
      # 断誀5: 联系人信息正确（权重10%）
      add_assertion "联系人信息正确（张三或李四）", weight: 10 do
        contact_valid = @allowed_contacts.any? do |contact|
          @booking.contact_name == contact[:name] && @booking.contact_phone == contact[:phone]
        end
        
        expect(contact_valid).to be_truthy,
          "联系人信息错误。" \
          "期望: 张三（13800138000）或李四（13900139000），" \
          "实际: #{@booking.contact_name}（#{@booking.contact_phone}）"
      end
    
      # 断誀6: 人数正确（权重10%）
      add_assertion "人数正确（#{@adult_count}成人#{@child_count}儿童）", weight: 10 do
        expect(@booking.adult_count).to eq(@adult_count),
          "成人数量错误。期望: #{@adult_count}人，实际: #{@booking.adult_count}人"
        expect(@booking.child_count).to eq(@child_count),
          "儿童数量错误。期望: #{@child_count}人，实际: #{@booking.child_count}人"
      end
      
      # 断誀7: 游客信息正确（权重15%）
      add_assertion "游客信息正确（张三、李四）", weight: 15 do
        travelers = @booking.booking_travelers.where(data_version: @data_version).to_a
        
        expect(travelers.size).to eq(2),
          "游客数量不正确。期望: 2个游客, 实际: #{travelers.size}个游客"
        
        traveler_names = travelers.map(&:traveler_name).sort
        
        expect(traveler_names).to eq(@expected_traveler_names),
          "游客名单不正确。期望: #{@expected_traveler_names.join('、')}, 实际: #{traveler_names.join('、')}"
        
        # 验证张三的身份证号
        zhangsan = travelers.find { |t| t.traveler_name == '张三' }
        expect(zhangsan).not_to be_nil, "未找到游客张三"
        expect(zhangsan.id_number).to eq(@zhangsan.id_number),
          "张三身份证号错误。期望: #{@zhangsan.id_number}, 实际: #{zhangsan.id_number}"
        
        # 验证李四的身份证号
        lisi = travelers.find { |t| t.traveler_name == '李四' }
        expect(lisi).not_to be_nil, "未找到游客李四"
        expect(lisi.id_number).to eq(@lisi.id_number),
          "李四身份证号错误。期望: #{@lisi.id_number}, 实际: #{lisi.id_number}"
      end
    end
  
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
    
      # 查找符合条件的自由行产品
      target_product = TourGroupProduct.where(
        travel_type: @travel_type,
        duration: @duration,
        data_version: 0
      ).where("destination LIKE ?", "%#{@destination}%")
       .order(:price)
       .first
    
      raise "未找到符合条件的自由行产品" unless target_product
    
      # 选择套餐（最便宜的）
      target_package = target_product.tour_packages.order(:price).first
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
        status: 'pending',
        data_version: @data_version
      )
      
      # 创建出行人记录（张三和李四）
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
    end
  
    private
  
    def execution_state_data
      {
        destination: @destination,
        duration: @duration,
        adult_count: @adult_count,
        child_count: @child_count,
        travel_type: @travel_type,
        travel_date: @travel_date.to_s,
        allowed_contacts: @allowed_contacts,
        expected_traveler_names: @expected_traveler_names
      }
    end
  
    def restore_from_state(data)
      @destination = data['destination']
      @duration = data['duration']
      @adult_count = data['adult_count']
      @child_count = data['child_count']
      @travel_type = data['travel_type']
      @travel_date = Date.parse(data['travel_date'])
      @allowed_contacts = data['allowed_contacts'] || [
        { 'name' => '张三', 'phone' => '13800138000' },
        { 'name' => '李四', 'phone' => '13900139000' }
      ]
      # 转换为 symbol keys
      @allowed_contacts = @allowed_contacts.map { |c| { name: c['name'], phone: c['phone'] } }
      @expected_traveler_names = data['expected_traveler_names'] || ['张三', '李四'].sort
    
      # 重新查询乘客信息用于验证身份证号
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @lisi = user.passengers.find_by!(name: '李四', data_version: 0)
    
      @qualified_products = TourGroupProduct.where(
        travel_type: @travel_type,
        duration: @duration,
        data_version: 0
      ).where("destination LIKE ?", "%#{@destination}%")
    end
  end
end
