# frozen_string_literal: true

require_relative '../base_validator'

# 验证用例302: 王芳9天后要去西安游览历史文化，需要预订博物馆和文化遗产主题的跟团游（至少3天）
# 
# 任务描述:
#   王芳对历史文化感兴趣，计划9天后到西安进行文化深度游，参观博物馆、文化遗产和艺术展览。
#   Agent 需要搜索西安的文化艺术主题跟团游，行程至少3天，完成1人的预订。
# 
# 业务流程（7个关键步骤）：
#   1. 搜索西安地区的跟团游产品
#   2. 筛选文化艺术主题的行程（通过评分和时长判断）
#   3. 确保行程时长≥3天（深度游要求）
#   4. 选择符合条件的优质产品（评分最高或时长最合适）
#   5. 设置出行日期（9天后）
#   6. 填写联系人信息（王芳的姓名、电话）
#   7. 创建游客记录（王芳的姓名、身份证号）
# 
# 复杂度分析（7个关键点）：
#   1. 需要理解目的地筛选：西安地区的跟团游
#   2. 需要理解主题匹配：文化艺术主题（通过评分≥4.5或时长≥3天判断）
#   3. 需要理解行程时长要求：duration字段≥3天
#   4. 需要理解出行日期计算：travel_date=9天后
#   5. 需要理解联系人信息：使用乘客信息中的王芳（姓名、电话）
#   6. 需要理解游客信息：创建BookingTraveler记录（姓名、身份证号）
#   7. 需要理解数据关联：TourGroupBooking关联TourGroupProduct、TourPackage、BookingTraveler
#   ❌ 不能随机选择：必须精确选择西安文化主题、行程≥3天、正确计算出行日期
# 
# 评分标准（7项，总计100分）：
#   1. 创建了跟团游预订（20分）
#   2. 目的地为西安（10分）
#   3. 选择文化艺术主题行程（25分）- 评分≥4.5或时长≥3天（核心业务逻辑）
#   4. 出行日期正确（9天后）（10分）
#   5. 联系人信息正确（王芳的姓名、电话）（10分）
#   6. 行程时长≥3天（10分）- 深度游要求
#   7. 游客信息正确（王芳的姓名、身份证号）（15分）
# 
# 使用方法:
#   rake validator:simulate_single[v302_book_cultural_art_tour_validator]
#   或访问 http://localhost:<PORT>/api/tasks 获取任务列表
module V301V350
  class V302BookCulturalArtTourValidator < BaseValidator
    self.validator_id = 'v302_book_cultural_art_tour_validator'
    self.task_id = 'f24660cb-1708-4a34-a89f-6108f9775035'
    self.title = '王芳9天后要去西安游览历史文化，需要预订博物馆和文化遗产主题的跟团游（至少3天）'
    self.description = '王芳要去西安游览历史文化，需要博物馆和文化遗产主题的跟团游'
    self.timeout_seconds = 300
    
    def prepare
      # 数据已通过 load_all_data_packs 自动加载（v1 目录下所有数据包）
      @destination = '西安'
      @travel_date = Date.current + 9.days  # 9天后出发
      @visit_date = @travel_date
      @min_duration = 3  # 至少3天
      
      # 预查询乘客信息（王芳）
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      @expected_contact_name = @wangfang.name
      @expected_contact_phone = @wangfang.phone
      @expected_traveler_name = @wangfang.name
      @expected_id_number = @wangfang.id_number
      
      # 确保用户余额充足
      if user.balance < 4000
        user.update!(balance: 6000)
      end
      
      # 返回给 Agent 的任务信息
      {
        task: "王芳9天后要去#{@destination}游览历史文化，需要预订博物馆和文化遗产主题的跟团游。#{@travel_date.strftime('%Y年%-m月%-d日')}（9天后）出发，需要参观博物馆、文化遗产和艺术展览，行程至少#{@min_duration}天。重要：必须是文化艺术主题的深度游，行程至少3天。",
        requirements: {
          beneficiary: '王芳',
          destination: @destination,
          theme: '文化艺术（博物馆、文化遗产、艺术展览）',
          travel_date: @travel_date.to_s,
          min_duration: "≥#{@min_duration}天",
          purpose: '历史文化深度游'
        },
        hint: "在#{@destination}筛选文化艺术主题的跟团游产品，行程至少#{@min_duration}天。选择高评分的深度游产品。联系人和游客信息填写王芳的姓名、电话、身份证号。"
      }
    end
    
    def verify
      # 断言1: 创建了跟团游预订（20分）
      # 作用: 查询本次会话的跟团游预订记录，确保预订成功
      # 查询逻辑: 
      #   - 必须包含 data_version: @data_version（会话隔离）
      #   - 通过 joins(:tour_group_product) 关联查询，筛选西安的跟团游
      #   - 按创建时间倒序，获取最新的预订
      add_assertion "创建了跟团游预订", weight: 20 do
        @tour_booking = TourGroupBooking
          .joins(:tour_group_product)
          .where(tour_group_products: { destination: @destination })  # 核心实体过滤
          .where(data_version: @data_version)  # 会话隔离（必须）
          .order(created_at: :desc)
          .first
        expect(@tour_booking).not_to be_nil, "未找到#{@destination}的跟团游预订"
      end
      
      return unless @tour_booking  # 保护后续断言
      
      # 断言2: 目的地为西安（10分）
      # 作用: 验证跟团游的目的地是否正确
      add_assertion "目的地为西安", weight: 10 do
        expect(@tour_booking.tour_group_product.destination).to eq(@destination),
          "目的地错误。期望: #{@destination}（西安），实际: #{@tour_booking.tour_group_product.destination}"
      end
      
      # 断言3: 选择文化艺术主题行程（25分）- 核心业务逻辑
      # 作用: 验证跟团游是否为文化艺术主题
      # 验证逻辑:
      #   - 文化艺术主题通常评分高（≥4.5星）或行程时长适中（≥3天）
      #   - 满足其中一个条件即可视为文化主题
      add_assertion "选择文化艺术主题行程（核心要求）", weight: 25 do
        tour = @tour_booking.tour_group_product
        # 文化主题通常评分高、时长适中
        is_cultural_tour = tour.rating >= 4.5 || tour.duration >= 3
        expect(is_cultural_tour).to be(true),
          "未选择文化艺术主题行程。当前行程: #{tour.title}，评分: #{tour.rating}星，天数: #{tour.duration}天（要求: 评分≥4.5星 或 天数≥3天）"
      end
      
      # 断言4: 出行日期正确（9天后）（10分）
      # 作用: 验证出行日期是否正确
      add_assertion "出行日期正确（#{@travel_date}）", weight: 10 do
        expect(@tour_booking.travel_date).to eq(@travel_date),
          "出行日期错误。期望: #{@travel_date}（9天后），实际: #{@tour_booking.travel_date}"
      end
      
      # 断言5: 联系人信息正确（王芳的姓名、电话）（10分）
      # 作用: 验证联系人姓名和电话是否正确
      add_assertion "联系人信息正确（#{@expected_contact_name}）", weight: 10 do
        expect(@tour_booking.contact_name).to eq(@expected_contact_name),
          "联系人姓名错误。期望: #{@expected_contact_name}（王芳），实际: #{@tour_booking.contact_name}"
        expect(@tour_booking.contact_phone).to eq(@expected_contact_phone),
          "联系电话错误。期望: #{@expected_contact_phone}（王芳手机号），实际: #{@tour_booking.contact_phone}"
      end
      
      # 断言6: 行程时长≥3天（10分）
      # 作用: 验证行程天数是否满足深度游要求（至少3天）
      add_assertion "行程时长≥3天（深度游要求）", weight: 10 do
        tour = @tour_booking.tour_group_product
        expect(tour.duration).to be >= 3,
          "行程天数不足。期望: ≥3天（深度游），实际: #{tour.duration}天"
      end
      
      # 断言7: 游客信息正确（王芳的姓名、身份证号）（15分）
      # 作用: 验证BookingTraveler记录中的游客信息是否正确
      # 验证逻辑:
      #   - 查询本次会话的游客记录（data_version: @data_version）
      #   - 验证游客数量为1人
      #   - 验证游客姓名和身份证号
      add_assertion "游客信息正确（#{@expected_traveler_name}）", weight: 15 do
        travelers = @tour_booking.booking_travelers.where(data_version: @data_version).to_a
        
        expect(travelers.size).to eq(1),
          "游客数量不正确。期望: 1个游客（王芳），实际: #{travelers.size}个游客"
        
        traveler = travelers.first
        expect(traveler.traveler_name).to eq(@expected_traveler_name),
          "游客姓名错误。期望: #{@expected_traveler_name}（王芳），实际: #{traveler.traveler_name}"
        
        expect(traveler.id_number).to eq(@expected_id_number),
          "身份证号错误。期望: #{@expected_id_number}（王芳身份证），实际: #{traveler.id_number}"
      end
    end
    
    def simulate
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
      
      # 1. 查询文化主题跟团游（至少3天）
      # 注意: 筛选条件为 destination=西安 且 duration≥3天
      tour_product = TourGroupProduct
        .where(destination: @destination, data_version: 0)
        .where("duration >= ?", 3)
        .order(rating: :desc)  # 按评分降序，选择高评分的文化主题产品
        .first!
      
      tour_package = tour_product.tour_packages.first!
      
      # 2. 创建跟团游预订
      booking = TourGroupBooking.create!(
        user_id: user.id,
        tour_group_product_id: tour_product.id,
        tour_package_id: tour_package.id,
        travel_date: @travel_date,
        adult_count: 1,
        child_count: 0,
        contact_name: wangfang.name,
        contact_phone: wangfang.phone,
        total_price: tour_package.price,
        status: 'pending',
        insurance_type: 'standard',
        data_version: @data_version
      )
      
      # 3. 创建游客记录（王芳）
      BookingTraveler.create!(
        tour_group_booking_id: booking.id,
        traveler_name: wangfang.name,
        id_number: wangfang.id_number,
        traveler_type: 'adult',
        data_version: @data_version
      )
      
      # 跟团游已包含景区门票，无需单独预订
    end
    
    private
    
    # 保存执行状态数据
    def execution_state_data
      {
        destination: @destination,
        travel_date: @travel_date&.to_s,
        visit_date: @visit_date&.to_s,
        min_duration: @min_duration,
        expected_contact_name: @expected_contact_name,
        expected_contact_phone: @expected_contact_phone,
        expected_traveler_name: @expected_traveler_name,
        expected_id_number: @expected_id_number
      }
    end
    
    # 从状态恢复实例变量
    def restore_from_state(data)
      @destination = data['destination']
      @travel_date = Date.parse(data['travel_date']) if data['travel_date']
      @visit_date = Date.parse(data['visit_date']) if data['visit_date']
      @min_duration = data['min_duration']
      @expected_contact_name = data['expected_contact_name']
      @expected_contact_phone = data['expected_contact_phone']
      @expected_traveler_name = data['expected_traveler_name']
      @expected_id_number = data['expected_id_number']
      
      # 恢复乘客引用
      user = User.find_by!(email: 'demo@travel01.com', data_version: 0)
      @wangfang = user.passengers.find_by!(name: '王芳', data_version: 0)
    end
  end
end
