# frozen_string_literal: true

require_relative '../base_validator'

# V281: 给张三、王芳和小明（9岁）预订7天后三亚亲子跟团游套餐（2大1小）
#
# 任务描述:
#   张三一家（张三、王芳和9岁小明）计划7天后去三亚旅游，需要预订亲子跟团游套餐。
#   要求选择三亚目的地的跟团游产品，产品需包含亲子元素（标题或标签含"亲子"关键词）。
#   人数配置为2大1小（张三、王芳为成人，小明为儿童），联系人选择成人之一。
#   Agent 需要在符合条件的产品中，选择合适的亲子跟团游套餐，并填写完整的游客信息和联系人信息完成预订。
#
# 业务流程（7个关键步骤）：
#   1. 搜索三亚目的地的跟团游产品
#   2. 筛选产品标题或标签包含"亲子"关键词的产品
#   3. 选择合适的套餐（包含成人价格和儿童价格）
#   4. 配置人数（2成人+1儿童：张三、王芳、小明）
#   5. 填写出行日期（7天后）
#   6. 填写游客信息（3人：张三、王芳、小明，含姓名、身份证号、年龄等）
#   7. 填写联系人信息（成人之一：张三或王芳）并提交订单
#
# 复杂度分析（6个关键点）：
#   1. 需要理解产品筛选：三亚目的地，产品标题或标签包含"亲子"关键词
#   2. 需要理解人数配置：2大1小配置（成人和儿童价格不同）
#   3. 需要理解出行日期计算：7天后（Date.current + 7.days）
#   4. 需要理解游客信息：创建3条 BookingTraveler 记录（张三、王芳为成人，小明为儿童）
#   5. 需要理解联系人选择：必须从成人中选择（张三或王芳），电话号码需匹配
#   6. 需要理解订单关联：订单需正确关联产品、套餐、游客信息
#   ❌ 不能随机选择：必须精确匹配目的地、亲子关键词、人数配置、出行日期
#
# 评分标准（7项，总计100分）：
#   - 创建了跟团游预订（三亚目的地）（20分）
#   - 人数配置正确（2大1小：张三、王芳、小明）（15分）
#   - 出行日期正确（7天后）（10分）
#   - 游客信息正确（张三、王芳、小明）（15分）
#   - 联系人信息正确（张三或王芳，成人）（10分）
#   - 行程适合亲子家庭（标题或标签包含"亲子"关键词）（15分）
#   - 订单状态正确（pending或confirmed）（15分）
module V251V300
  class V281BookFamilyPackageValidator < BaseValidator
    self.validator_id = 'v281_book_family_package_validator'
    self.task_id = '97f3e67d-07f1-4e31-b1bc-0f6b87f0d09f'
    self.title = '给张三、王芳和小明（9岁）预订7天后三亚亲子跟团游套餐（2大1小）'
    self.description = '给张三、王芳和小明（9岁）预订7天后三亚亲子跟团游套餐（2大1小）'
    self.timeout_seconds = 300
    
    def prepare
      @adult_count = 2
      @child_count = 1
      @keyword = '亲子'
      @destination_name = '三亚'
      @travel_date = Date.current + 7.days
      
      # 查找包含亲子元素的跟团游产品（必须存在）
      @product = TourGroupProduct.where('tags LIKE ?', "%#{@keyword}%")
                                 .where(data_version: 0)
                                 .first!
      
      # 预查询套餐（必须存在于数据包）
      @package = @product.tour_packages.where(data_version: 0).first!
      
      # 预查询乘客信息
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      
      # 有效联系人电话映射（成人可作为联系人）
      @valid_contact_phones = {
        '张三' => @zhangsan.phone,
        '王芳' => @wangfang.phone
      }
      
      @expected_traveler_names = [@zhangsan.name, @wangfang.name, @xiaoming.name]
      
      # 确保用户有足够余额
      total_price = @package.price * @adult_count + @package.child_price * @child_count
      if user.balance < total_price
        user.update!(balance: total_price + 1000)
      end
      
      {
        task: "请给张三、王芳和小明（9岁）预订#{@travel_date.strftime('%Y年%m月%d日')}的#{@destination_name}适合亲子游的跟团游套餐「#{@product.title}」，包含适合儿童的活动和设施",
        adult_count: @adult_count,
        child_count: @child_count,
        destination: @destination_name,
        travel_date: @travel_date.strftime('%Y-%m-%d'),
        product_title: @product.title,
        hint: "1. 在跟团游搜索页选择三亚目的地\n2. 浏览并选择包含'亲子'关键词的产品\n3. 选择合适的套餐\n4. 配置人数（2成人+1儿童）\n5. 填写出行日期（7天后）\n6. 填写游客信息（张三、王芳、小明）并提交订单",
        product_available: @product.present?,
        package_available: @package.present?
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 20 do
        @booking = TourGroupBooking
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        expect(@booking).not_to be_nil, "未找到跟团游预订"
      end
      
      return unless @booking
      
      add_assertion "人数配置正确（#{@adult_count}大#{@child_count}小）", weight: 15 do
        expect(@booking.adult_count).to eq(@adult_count),
          "成人数量错误。期望: #{@adult_count}（张三、王芳）, 实际: #{@booking.adult_count}"
        expect(@booking.child_count).to eq(@child_count),
          "儿童数量错误。期望: #{@child_count}（小明）, 实际: #{@booking.child_count}"
      end
      
      add_assertion "出行日期正确（7天后#{@travel_date.strftime('%Y-%m-%d')}）", weight: 10 do
        expect(@booking.travel_date).to be_present,
          "缺少出行日期"
        
        expect(@booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date.strftime('%Y-%m-%d')}（7天后），实际: #{@booking.travel_date}"
      end
      
      add_assertion "游客信息正确（张三、王芳、小明）", weight: 15 do
        travelers = @booking.booking_travelers
        expect(travelers).not_to be_empty,
          "游客信息缺失，未找到任何 booking_travelers 记录"
        
        actual_names = travelers.map(&:traveler_name).compact.sort
        expect(actual_names).to match_array(@expected_traveler_names.sort),
          "游客信息错误。期望: #{@expected_traveler_names.sort.join('、')}, 实际: #{actual_names.join('、')}"
      end
      
      add_assertion "联系人信息正确（张三或王芳）", weight: 10 do
        valid_contacts = ['张三', '王芳']
        expect(valid_contacts).to include(@booking.contact_name),
          "联系人姓名错误。期望: 张三或王芳（成人），实际: #{@booking.contact_name}"
        
        expected_phone = @valid_contact_phones[@booking.contact_name]
        expect(@booking.contact_phone).to eq(expected_phone),
          "联系人电话与姓名不匹配。联系人: #{@booking.contact_name}, 期望电话: #{expected_phone}, 实际电话: #{@booking.contact_phone}"
      end
      
      add_assertion "行程适合亲子家庭", weight: 15 do
        product = @booking.tour_group_product
        expect(product).not_to be_nil, "订单没有关联产品"
        has_family_tag = product.tags.to_s.include?(@keyword) || product.title.to_s.include?(@keyword)
        expect(has_family_tag).to be(true),
          "产品不适合亲子游。期望包含关键词: #{@keyword}, 实际标题: #{product.title}, 标签: #{product.tags}"
      end
      
      add_assertion "订单状态正确", weight: 15 do
        expect(@booking.status).to eq('pending').or(eq('confirmed')),
          "订单状态错误。期望: pending/confirmed, 实际: #{@booking.status}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 使用 prepare 中查询的数据（不创建 data_version: 0）
      zhangsan = user.passengers.find_by!(name: '张三', data_version: 0)
      wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      xiaoming = user.passengers.find_by!(name: '小明', data_version: 0)
      
      # 随机选择联系人（从成人中选择）
      contact_names = ['张三', '王芳']
      selected_contact_name = contact_names.sample
      contact_passenger = selected_contact_name == '张三' ? zhangsan : wangfang
      
      booking = TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: @product.id,
        tour_package_id: @package.id,
        adult_count: @adult_count,
        child_count: @child_count,
        contact_name: contact_passenger.name,
        contact_phone: contact_passenger.phone,
        travel_date: @travel_date,
        total_price: @package.price * @adult_count + @package.child_price * @child_count,
        status: 'confirmed',
        data_version: @data_version
      )
      
      # 创建游客信息
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: zhangsan.name,
        id_number: zhangsan.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: wangfang.name,
        id_number: wangfang.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: xiaoming.name,
        id_number: xiaoming.id_number,
        traveler_type: 'child',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        adult_count: @adult_count,
        child_count: @child_count,
        keyword: @keyword,
        destination_name: @destination_name,
        travel_date: @travel_date&.to_s,
        product_id: @product&.id,
        package_id: @package&.id,
        valid_contact_phones: @valid_contact_phones,
        expected_traveler_names: @expected_traveler_names
      }
    end
    
    def restore_from_state(data)
      @adult_count = data['adult_count']
      @child_count = data['child_count']
      @keyword = data['keyword']
      @destination_name = data['destination_name']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @product = TourGroupProduct.find(data['product_id']) if data['product_id']
      @package = TourPackage.find(data['package_id']) if data['package_id']
      @valid_contact_phones = data['valid_contact_phones']
      @expected_traveler_names = data['expected_traveler_names']
    end
  end
end
