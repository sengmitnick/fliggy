# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例299: 给王芳预订7天后云南摄影主题游（5天4晚高评分跟团游[评分≥4.5]，1人）
#
# 任务描述:
#   王芳需要7天后去云南进行摄影主题旅游，要求选择5天4晚高评分（评分≥4.5）的跟团游产品。
#   Agent需要创建1人跟团游预订，优先选择评分最高的产品，
#   确保适合摄影创作需求。
#
# 业务流程（6个关键步骤）：
#   1. 明确出行人信息（王芳，使用其姓名、电话、身份证号）
#   2. 搜索7天后前往云南的高评分跟团游（评分≥4.5）
#   3. 优先选择评分最高的产品（适合摄影的自然风光）
#   4. 创建跟团游预订（成人1人，儿童0人）
#   5. 添加游客信息（王芳的姓名和身份证号）
#   6. 设置联系人信息（王芳的姓名和电话）
#
# 复杂度分析（6个关键点）：
#   1. 需要理解摄影主题游的特点，筛选高评分产品（评分≥4.5）
#   2. 需要按评分降序排序，选择最优质产品
#   3. 需要创建跟团游预订，并正确配置人数（1人）
#   4. 需要添加BookingTraveler记录，包含游客详细信息
#   5. 需要验证游客信息完整性（姓名和身份证号）
#   6. 需要使用真实存在的跟团游产品（data_version: 0）
#   ❌ 不能选择低评分产品（必须评分≥4.5）
#
# 评分标准（7项，总计100分）：
#   1. 创建了跟团游预订（25分）
#   2. 选择高评分跟团游（评分≥4.5）（20分）- 核心业务逻辑
#   3. 跟团游天数为5天（10分）
#   4. 游客信息正确（王芳）（15分）
#   5. 预订日期正确（7天后）（10分）
#   6. 联系人信息正确（王芳）（10分）
#   7. 预订人数正确(1人)（10分）
#
# 使用方法:
#   rake validator:simulate_single[v299]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
#
module V251V300
  class V299BookPhotographyThemeTourValidator < BaseValidator
    self.validator_id = 'v299_book_photography_theme_tour_validator'
    self.task_id = 'feeaef15-74e2-4fb2-a7fa-1b6c5bc2273f'
    self.title = '给王芳预订7天后云南摄影主题游（5天4晚高评分跟团游[评分≥4.5]，1人）'
    self.description = '王芳需要7天后去云南进行摄影主题旅游，选择5天4晚高评分跟团游（评分≥4.5），适合摄影创作'
    self.timeout_seconds = 300
    
    def prepare
      @destination = '云南'
      @travel_date = Date.today + 7.days
      @visit_date = Date.today + 8.days
      @expected_duration = 5  # 5天4晚
      
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # Pre-query passenger info
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_contact_name = @wangfang.name
      @expected_contact_phone = @wangfang.phone
      
      # 检查是否有摄影主题跟团游产品
      tour_count = TourGroupProduct.where(destination: @destination, data_version: 0).count
      raise "测试数据不足: #{@destination}地区没有跟团游产品，当前数量: #{tour_count}" if tour_count == 0
      
      {
        destination: @destination,
        travel_date: @travel_date,
        task_description: "预订#{@destination}摄影主题游，#{@travel_date.strftime('%Y年%m月%d日')}出发"
      }
    end
    
    def verify
      add_assertion "创建了跟团游预订", weight: 25 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })
          .where(data_version: @data_version)
          .order(created_at: :desc)
          .first
        
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking
      
      add_assertion "选择高评分跟团游（评分≥4.5）", weight: 20 do
        tour = @tour_booking.tour_group_product
        # 摄影主题游选择高评分产品
        is_high_rating = tour.rating >= 4.5
        expect(is_high_rating).to be(true),
          "未选择高评分跟团游。当前评分: #{tour.rating}"
      end
      
      add_assertion "跟团游天数为5天", weight: 10 do
        tour = @tour_booking.tour_group_product
        expect(tour.duration).to eq(@expected_duration),
          "跟团游天数错误。期望: #{@expected_duration}天, 实际: #{tour.duration}天"
      end
      
      add_assertion "游客信息正确（王芳）", weight: 15 do
        travelers = @tour_booking.booking_travelers
        expect(travelers).not_to be_empty, "未找到游客信息"
        
        wangfang_traveler = travelers.find { |t| t.traveler_name == @expected_contact_name }
        expect(wangfang_traveler).not_to be_nil,
          "游客信息中缺少王芳。实际游客: #{travelers.map(&:traveler_name).join(', ')}"
        
        expect(wangfang_traveler.id_number).to eq(@wangfang.id_number),
          "身份证号码错误。期望: #{@wangfang.id_number}, 实际: #{wangfang_traveler.id_number}"
      end
      
      add_assertion "预订日期正确", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}, 实际: #{@tour_booking.travel_date}"
      end
      
      add_assertion "联系人信息正确（王芳）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}, 实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}, 实际: #{@tour_booking.contact_phone}"
      end
      
      add_assertion "预订人数正确(1人)", weight: 10 do
        total_passengers = @tour_booking.adult_count + @tour_booking.child_count
        expect(total_passengers).to eq(1),
          "预订人数错误。期望: 1人，实际: #{total_passengers}人"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      
      # 选择5天4晚高评分跟团游
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where(duration: @expected_duration)
        .order(rating: :desc)
        .first!
      
      tour_package = tour_product.tour_packages.first!
      
      # 创建跟团游预订
      tour_booking = TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 1,
        child_count: 0,
        contact_name: @wangfang.name,
        contact_phone: @wangfang.phone,
        total_price: tour_package.price,
        status: 'pending',
        insurance_type: 'standard',
        data_version: @data_version
      )
      
      # 添加游客信息
      BookingTraveler.create!(
        tour_group_booking_id: tour_booking.id,
        traveler_name: @wangfang.name,
        id_number: @wangfang.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
    end
    
    private
    
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        visit_date: @visit_date&.to_s,
        expected_duration: @expected_duration,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone,
        wangfang_id_number: @wangfang&.id_number
      }
    end
    
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @visit_date = Date.parse(data['visit_date']) if data['visit_date']
      @expected_duration = data['expected_duration']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      
      # Restore @wangfang as a simple object with id_number
      if data['wangfang_id_number']
        @wangfang = OpenStruct.new(
          name: @expected_contact_name,
          phone: @expected_contact_phone,
          id_number: data['wangfang_id_number']
        )
      end
    end
  end
end
